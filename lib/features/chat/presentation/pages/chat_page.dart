import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../timeline/presentation/widgets/navigation_drawer_widget.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/chat_hub_service.dart';
import '../../domain/entities/chat_conversation.dart';
import 'chat_detail_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.session,
    required this.language,
    this.onClose,
  });

  final AuthSession session;
  final AppLanguage language;
  final VoidCallback? onClose;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatRepository _repository = ChatRepository(
    remoteDataSource: ChatRemoteDataSource(baseUrl: kApiBaseUrl),
  );
  
  late final ChatHubService _hubService = ChatHubService(
    baseUrl: kApiBaseUrl,
    accessToken: widget.session.accessToken,
    currentUserId: widget.session.userId,
  );

  final TextEditingController _searchController = TextEditingController();

  List<ChatConversation> _conversations = [];
  bool _loading = true;
  String? _errorMessage;
  _ChatFilter _filter = _ChatFilter.recent;
  
  Timer? _autoRefreshTimer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedDrawerIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    _hubService.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final items = await _repository.fetchConversations(
        accessToken: widget.session.accessToken,
      );
      if (!mounted) return;
      
      // Remove duplicates by sessionId/groupId
      final seen = <String>{};
      final uniqueItems = <ChatConversation>[];
      for (final item in items) {
        final id = item.isGroup ? (item.groupId ?? '') : item.sessionId;
        if (!seen.contains(id)) {
          seen.add(id);
          uniqueItems.add(item);
        }
      }
      
      setState(() {
        _conversations = uniqueItems;
        _loading = false;
      });
      
      // Join all conversations to receive realtime updates
      print('[ChatPage] Loaded ${uniqueItems.length} conversations');
      _joinAllConversations(uniqueItems);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _joinAllConversations(List<ChatConversation> conversations) async {
    try {
      print('[ChatPage] Joining ${conversations.length} conversations...');
      // Ensure hub connection is established first
      await Future.delayed(const Duration(milliseconds: 1000));
      
      for (final conv in conversations) {
        if (conv.isGroup && conv.groupId?.isNotEmpty == true) {
          print('[ChatPage] Joining group: ${conv.groupId}');
          _hubService.joinGroup(conv.groupId!).catchError((e) {
            print('[ChatPage] Error joining group: $e');
          });
        } else {
          print('[ChatPage] Joining session: ${conv.sessionId}');
          _hubService.joinSession(conv.sessionId).catchError((e) {
            print('[ChatPage] Error joining session: $e');
          });
        }
        // Small delay between joins
        await Future.delayed(const Duration(milliseconds: 100));
      }
      print('[ChatPage] Finished joining all conversations');
    } catch (e) {
      print('[ChatPage] Error in _joinAllConversations: $e');
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      try {
        final items = await _repository.fetchConversations(
          accessToken: widget.session.accessToken,
        );
        if (!mounted) return;
        
        // Remove duplicates by sessionId/groupId
        final seen = <String>{};
        final uniqueItems = <ChatConversation>[];
        for (final item in items) {
          final id = item.isGroup ? (item.groupId ?? '') : item.sessionId;
          if (!seen.contains(id)) {
            seen.add(id);
            uniqueItems.add(item);
          }
        }
        
        // Only update UI if data changed
        if (uniqueItems.length != _conversations.length ||
            uniqueItems.asMap().entries.any((e) => 
              e.value.lastMessage != _conversations[e.key].lastMessage ||
              e.value.unreadCount != _conversations[e.key].unreadCount
            )) {
          if (mounted) {
            setState(() {
              _conversations = uniqueItems;
            });
          }
        }
      } catch (e) {
        // Silent fail
      }
    });
  }

  Future<void> _markAsRead(String sessionId) async {
    try {
      await _repository.markAsRead(
        accessToken: widget.session.accessToken,
        sessionId: sessionId,
      );
      
      // Update unreadCount to 0 in local state
      final index = _conversations.indexWhere((c) => c.sessionId == sessionId);
      if (index >= 0) {
        final conversation = _conversations[index];
        _conversations[index] = ChatConversation(
          sessionId: conversation.sessionId,
          type: conversation.type,
          groupId: conversation.groupId,
          groupName: conversation.groupName,
          otherUserId: conversation.otherUserId,
          otherDisplayName: conversation.otherDisplayName,
          otherAvatarUrl: conversation.otherAvatarUrl,
          lastMessage: conversation.lastMessage,
          updatedAt: conversation.updatedAt,
          unreadCount: 0,
          isPinned: conversation.isPinned,
          pinnedAt: conversation.pinnedAt,
        );
        if (mounted) setState(() {});
      }
    } catch (e) {
    }
  }

  Future<void> _togglePin(ChatConversation conversation) async {
    try {
      await _repository.pinConversation(
        accessToken: widget.session.accessToken,
        sessionId: conversation.sessionId,
        pin: !conversation.isPinned,
      );
      
      // Update pinned state in local state
      final index = _conversations.indexWhere((c) => c.sessionId == conversation.sessionId);
      if (index >= 0) {
        final conv = _conversations[index];
        _conversations[index] = ChatConversation(
          sessionId: conv.sessionId,
          type: conv.type,
          groupId: conv.groupId,
          groupName: conv.groupName,
          otherUserId: conv.otherUserId,
          otherDisplayName: conv.otherDisplayName,
          otherAvatarUrl: conv.otherAvatarUrl,
          lastMessage: conv.lastMessage,
          updatedAt: conv.updatedAt,
          unreadCount: conv.unreadCount,
          isPinned: !conv.isPinned,
          pinnedAt: !conv.isPinned ? DateTime.now() : null,
        );
        if (mounted) setState(() {});
      }
    } catch (e) {
    }
  }

  void _showPinMenu(BuildContext context, ChatConversation conversation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!conversation.isPinned)
              ListTile(
                leading: const Icon(Icons.push_pin, color: Color(0xFF2563EB)),
                title: const Text('Ghim'),
                onTap: () {
                  Navigator.pop(context);
                  _togglePin(conversation);
                },
              ),
            if (conversation.isPinned)
              ListTile(
                leading: const Icon(Icons.push_pin, color: Color(0xFFF59E0B)),
                title: const Text('Bỏ ghim'),
                onTap: () {
                  Navigator.pop(context);
                  _togglePin(conversation);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _t(String vi, String en) =>
      widget.language == AppLanguage.vi ? vi : en;

  List<ChatConversation> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    return _conversations.where((conversation) {
      final matchFilter = switch (_filter) {
        _ChatFilter.recent => true,
        _ChatFilter.group => conversation.isGroup,
        _ChatFilter.channel => conversation.isChannel,
        _ChatFilter.dm => conversation.isDirect,
      };
      if (!matchFilter) return false;
      if (query.isEmpty) return true;
      final name = conversation.displayName.toLowerCase();
      final message = (conversation.lastMessage ?? '').toLowerCase();
      return name.contains(query) || message.contains(query);
    }).toList()..sort((a, b) {
      // Sort by: isPinned desc → pinnedAt desc → updatedAt desc
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      if (a.isPinned && b.isPinned) {
        final aPinned = a.pinnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bPinned = b.pinnedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final pinnedCompare = bPinned.compareTo(aPinned);
        if (pinnedCompare != 0) return pinnedCompare;
      }
      
      final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: NavigationDrawerWidget(
        selectedIndex: _selectedDrawerIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedDrawerIndex = index;
          });
          Navigator.of(context).pop();
          _handleDrawerNavigation(index);
        },
        language: widget.language,
      ),
      body: Container(
        color: const Color(0xFFF7F7F7),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchField(),
            ),
            const SizedBox(height: 12),
            _buildFilterRow(),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF5DADE2),
                onRefresh: _loadConversations,
                child: _buildConversationList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDrawerNavigation(int index) {
    // Navigation handled by MainPage
    // This is just a placeholder to close drawer
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Text(
              'WorkChat',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5DADE2),
                letterSpacing: widget.language == AppLanguage.en ? 0.5 : 0,
              ),
            ),
            const Spacer(),
            if (widget.onClose != null)
              GestureDetector(
                onTap: widget.onClose,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close, size: 18, color: Color(0xFF1B2B57)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: _t('Nhập từ khóa để tìm kiếm', 'Search conversations'),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF66BB6A)),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = [
      _FilterChipData(
        filter: _ChatFilter.recent,
        label: _t('Gần đây', 'Recent'),
      ),
      _FilterChipData(
        filter: _ChatFilter.group,
        label: _t('Nhóm chat', 'Group chats'),
      ),
      _FilterChipData(filter: _ChatFilter.dm, label: _t('Tin nhắn', 'Direct')),
   
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final option = filters[index];
          final isSelected = option.filter == _filter;
          return ChoiceChip(
            label: Text(
              option.label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: isSelected,
            selectedColor: const Color(0xFF5DADE2),
            backgroundColor: const Color(0xFFEFF1F5),
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            onSelected: (_) => setState(() => _filter = option.filter),
          );
        },
        separatorBuilder: (_, index) => const SizedBox(width: 12),
        itemCount: filters.length,
      ),
    );
  }

  Widget _buildConversationList() {
    final items = _visibleItems;

    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 160),
          Center(
            child: SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF4CB065),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 120),
          Column(
            children: [
              Text(
                _t(
                  'Không thể tải danh sách chat',
                  'Unable to load conversations',
                ),
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadConversations,
                child: Text(_t('Thử lại', 'Retry')),
              ),
            ],
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              _t('Không có cuộc trò chuyện nào', 'No conversations yet'),
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemBuilder: (context, index) {
        final conversation = items[index];
        return _ConversationTile(
          conversation: conversation,
          language: widget.language,
          updatedLabel: _formatUpdatedAt(conversation.updatedAt),
          onTap: () {
            _markAsRead(conversation.sessionId);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(
                  session: widget.session,
                  language: widget.language,
                  conversation: conversation,
                  repository: _repository,
                ),
              ),
            );
          },
          onLongPress: () => _showPinMenu(context, conversation),
        );
      },
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }

  String _formatUpdatedAt(DateTime? updatedAt) {
    if (updatedAt == null) return '';
    final now = DateTime.now();
    final date = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(date).inDays;

    if (difference == 0) {
      return _t('Hôm nay', 'Today');
    }
    if (difference == 1) {
      return _t('Hôm qua', 'Yesterday');
    }

    const viDays = {
      DateTime.monday: 'Thứ Hai',
      DateTime.tuesday: 'Thứ Ba',
      DateTime.wednesday: 'Thứ Tư',
      DateTime.thursday: 'Thứ Năm',
      DateTime.friday: 'Thứ Sáu',
      DateTime.saturday: 'Thứ Bảy',
      DateTime.sunday: 'Chủ nhật',
    };
    const enDays = {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };

    final weekday = updatedAt.weekday;
    final label = widget.language == AppLanguage.vi
        ? viDays[weekday]
        : enDays[weekday];
    if (label != null) return label;
    return '${updatedAt.day}/${updatedAt.month}';
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.language,
    required this.updatedLabel,
    required this.onTap,
    this.onLongPress,
  });

  final ChatConversation conversation;
  final AppLanguage language;
  final String updatedLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.displayName.isNotEmpty
                            ? conversation.displayName
                            : (conversation.isGroup
                                  ? (language == AppLanguage.vi
                                        ? 'Nhóm'
                                        : 'Group')
                                  : (language == AppLanguage.vi
                                        ? 'Trò chuyện'
                                        : 'Chat')),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: conversation.unreadCount > 0 
                              ? FontWeight.w700 
                              : FontWeight.w600,
                          color: Color(0xFF1F2A37),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessage?.isNotEmpty == true
                            ? conversation.lastMessage!
                            : (language == AppLanguage.vi
                                  ? 'Chưa có tin nhắn'
                                  : 'No messages yet'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.w800
                              : FontWeight.w400,
                          color: conversation.unreadCount > 0
                              ? const Color(0xFF1F2A37)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (conversation.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        Text(
                          updatedLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    if (conversation.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Bỏ ghim',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    if (conversation.unreadCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            conversation.unreadCount > 99 ? '99+' : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (conversation.isGroup || conversation.isChannel) {
      final text = conversation.displayName.isNotEmpty
          ? conversation.displayName[0].toUpperCase()
          : 'G';
      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFFE0F2F1),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF047857),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (conversation.otherAvatarUrl != null &&
        conversation.otherAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(conversation.otherAvatarUrl!),
      );
    }

    final text = conversation.displayName.isNotEmpty
        ? conversation.displayName[0].toUpperCase()
        : 'D';
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE8EEFF),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FilterChipData {
  const _FilterChipData({required this.filter, required this.label});

  final _ChatFilter filter;
  final String label;
}

enum _ChatFilter { recent, group, dm, channel }
