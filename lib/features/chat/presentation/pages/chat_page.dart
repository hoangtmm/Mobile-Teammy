import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_conversation.dart';
import 'chat_detail_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.session, required this.language});

  final AuthSession session;
  final AppLanguage language;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatRepository _repository = ChatRepository(
    remoteDataSource: ChatRemoteDataSource(baseUrl: kApiBaseUrl),
  );

  final TextEditingController _searchController = TextEditingController();

  List<ChatConversation> _conversations = [];
  bool _loading = true;
  String? _errorMessage;
  _ChatFilter _filter = _ChatFilter.recent;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      setState(() {
        _conversations = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _loading = false;
      });
    }
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
      final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: const Color(0xFF4CB065),
              onRefresh: _loadConversations,
              child: _buildConversationList(),
            ),
          ),
        ],
      ),
    );
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
                color: const Color(0xFF24A148),
                letterSpacing: widget.language == AppLanguage.en ? 0.5 : 0,
              ),
            ),
            const Spacer(),
            _buildHeaderIcon(Icons.person_outline),
            _buildHeaderIcon(Icons.help_outline),
            _buildHeaderIcon(Icons.settings_outlined),
            _buildHeaderIcon(Icons.close),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Padding(
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
        child: Icon(icon, size: 18, color: const Color(0xFF1B2B57)),
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
          borderSide: const BorderSide(color: Color(0xFF4CB065)),
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
      _FilterChipData(
        filter: _ChatFilter.channel,
        label: _t('Kênh chat', 'Channels'),
      ),
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
            selectedColor: const Color(0xFF4CB065),
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
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF4CB065),
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
  });

  final ChatConversation conversation;
  final AppLanguage language;
  final String updatedLabel;
  final VoidCallback onTap;

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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
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
                    Text(
                      updatedLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    if (conversation.isGroup)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.push_pin_outlined,
                          size: 16,
                          color: Color(0xFFFF8A3C),
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
