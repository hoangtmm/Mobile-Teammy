import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/chat_hub_service.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({
    super.key,
    required this.session,
    required this.language,
    required this.conversation,
    required this.repository,
  });

  final AuthSession session;
  final AppLanguage language;
  final ChatConversation conversation;
  final ChatRepository repository;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  static const int _pageSize = 30;

  late final ChatHubService _hubService = ChatHubService(
    baseUrl: kApiBaseUrl,
    accessToken: widget.session.accessToken,
    currentUserId: widget.session.userId,
  );

  late AppLanguage _language = widget.language;
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _activeUsers = [];
  List<String> _typingUserIds = [];
  List<ChatMessage> _pinnedMessages = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _sending = false;
  bool _isOnline = false;
  bool _isTyping = false;
  int _currentPage = 1;
  String? _selectedMessageId;

  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<bool>? _presenceSub;
  StreamSubscription<bool>? _typingSub;
  StreamSubscription<List<String>>? _typingUsersSub;
  StreamSubscription<ChatMessage>? _messageUpdatedSub;
  StreamSubscription<List<Map<String, dynamic>>>? _activeUsersSub;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadHistory();
    _connectHub();
    _markAsRead();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _messageSub?.cancel();
    _presenceSub?.cancel();
    _typingSub?.cancel();
    _typingUsersSub?.cancel();
    _messageUpdatedSub?.cancel();
    _activeUsersSub?.cancel();
    _typingTimer?.cancel();

    if (widget.conversation.isGroup &&
        widget.conversation.groupId?.isNotEmpty == true) {
      unawaited(_hubService.leaveGroup(widget.conversation.groupId!));
    } else {
      unawaited(_hubService.leaveSession(widget.conversation.sessionId));
    }
    _hubService.dispose();

    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool loadMore = false}) async {
    if (loadMore) {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _currentPage = 1;
        _hasMore = true;
      });
    }

    final targetPage = loadMore ? _currentPage + 1 : 1;
    try {
      final history = await _fetchMessages(targetPage);
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _messages = [...history, ..._messages];
          _currentPage = targetPage;
          _loadingMore = false;
        } else {
          _messages = history;
          _currentPage = 1;
          _loading = false;
          // Extract pinned messages from loaded history
          _pinnedMessages = history.where((m) => m.isPinned ?? false).toList();
        }
        _hasMore = history.length >= _pageSize;
      });
      if (!loadMore) {
        _scrollToBottom();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _loadingMore = false;
        } else {
          _loading = false;
        }
      });
    }
  }

  Future<List<ChatMessage>> _fetchMessages(int page) {
    if (widget.conversation.isGroup &&
        widget.conversation.groupId?.isNotEmpty == true) {
      return widget.repository.fetchGroupMessages(
        accessToken: widget.session.accessToken,
        groupId: widget.conversation.groupId!,
        currentUserId: widget.session.userId,
        page: page,
        pageSize: _pageSize,
      );
    }
    return widget.repository.fetchSessionMessages(
      accessToken: widget.session.accessToken,
      sessionId: widget.conversation.sessionId,
      currentUserId: widget.session.userId,
      page: page,
      pageSize: _pageSize,
    );
  }

  void _handleScroll() {
    if (_scrollController.position.pixels <= 80 &&
        !_loading &&
        !_loadingMore &&
        _hasMore) {
      _loadHistory(loadMore: true);
    }
  }

  Future<void> _connectHub() async {
    try {
      _messageSub = _hubService.messages.listen(
        (message) {
          if (!mounted) return;
          setState(() {
            // Check if this is a real message replacing an optimistic one
            int optimisticIndex = -1;
            for (int i = 0; i < _messages.length; i++) {
              final m = _messages[i];
              if (m.content == message.content && 
                  m.senderId == message.senderId &&
                  m.messageId.startsWith('temp_')) {
                optimisticIndex = i;
                break;
              }
            }
            
            if (optimisticIndex >= 0) {
              _messages[optimisticIndex] = message;
            } else {
              _messages = [..._messages, message];
            }
          });
          _scrollToBottom();
        },
        onError: (error) {
          // Silent fail
        },
      );

      _presenceSub = _hubService.presence.listen(
        (online) {
          if (!mounted) return;
          setState(() => _isOnline = online);
        },
        onError: (error) {
          // Silent fail
        },
      );

      _typingSub = _hubService.typing.listen(
        (typing) {
          if (!mounted) return;
          setState(() => _isTyping = typing);
        },
        onError: (error) {
          // Silent fail
        },
      );

      _activeUsersSub = _hubService.activeUsers.listen(
        (users) {
          if (!mounted) return;
          setState(() => _activeUsers = users);
        },
        onError: (error) {
          // Silent fail
        },
      );

      // Subscribe to typing users list
      _typingUsersSub = _hubService.typingUsers.listen(
        (userIds) {
          if (!mounted) return;
          setState(() => _typingUserIds = userIds);
        },
        onError: (error) {
          // Silent fail
        },
      );

      // Subscribe to message updates (pin/unpin/delete)
      _messageUpdatedSub = _hubService.messageUpdated.listen(
        (updatedMessage) {
          if (!mounted) return;
          setState(() {
            final index = _messages.indexWhere(
              (m) => m.messageId == updatedMessage.messageId,
            );
            if (index >= 0) {
              _messages[index] = updatedMessage;
            }
            
            // Update pinned messages list
            if (updatedMessage.isPinned ?? false) {
              // Add to pinned if not already there
              if (!_pinnedMessages.any((m) => m.messageId == updatedMessage.messageId)) {
                _pinnedMessages.add(updatedMessage);
              } else {
                // Update existing pinned message
                final pinnedIndex = _pinnedMessages.indexWhere(
                  (m) => m.messageId == updatedMessage.messageId,
                );
                if (pinnedIndex >= 0) {
                  _pinnedMessages[pinnedIndex] = updatedMessage;
                }
              }
            } else {
              // Remove from pinned if unpinned
              _pinnedMessages.removeWhere((m) => m.messageId == updatedMessage.messageId);
            }
          });
        },
        onError: (error) {
          // Silent fail
        },
      );

      final bool isGroupConversation =
          widget.conversation.isGroup && widget.conversation.groupId?.isNotEmpty == true;
      if (isGroupConversation) {
        await _hubService.joinGroup(widget.conversation.groupId!);
      } else {
        await _hubService.joinSession(widget.conversation.sessionId);
      }
    } catch (e) {
      // Silent fail - will retry on auto-reconnect
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
    }
  }

  Future<void> _sendMessage() async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _sending) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final userId = widget.session.userId;
    
    // Optimistic update - add message immediately to UI
    final optimisticMessage = ChatMessage(
      messageId: tempId,
      sessionId: widget.conversation.sessionId,
      senderId: userId,
      senderName: widget.session.displayName ?? 'You',
      content: text,
      createdAt: DateTime.now(),
      isMine: true,
    );

    setState(() {
      _messages = [..._messages, optimisticMessage];
      _sending = true;
    });
    _composerController.clear();
    _scrollToBottom();

    try {
      final isGroupConversation =
          widget.conversation.isGroup && widget.conversation.groupId?.isNotEmpty == true;
      if (isGroupConversation) {
        await widget.repository.sendGroupMessage(
          accessToken: widget.session.accessToken,
          groupId: widget.conversation.groupId!,
          content: text,
        );
      } else {
        await widget.repository.sendMessage(
          accessToken: widget.session.accessToken,
          sessionId: widget.conversation.sessionId,
          content: text,
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        _showError('Failed to send: $errorMsg');
        setState(() {
          _messages = _messages
              .where((m) => m.messageId != tempId)
              .toList();
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _handleComposerChanged(String value) {
    if (value.isEmpty) {
      _notifyTyping(false);
      _typingTimer?.cancel();
      return;
    }
    _notifyTyping(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _notifyTyping(false);
    });
  }

  void _notifyTyping(bool isTyping) {
    if (widget.conversation.isGroup &&
        widget.conversation.groupId?.isNotEmpty == true) {
      _hubService.sendGroupTyping(widget.conversation.groupId!, isTyping).catchError((e) {
      });
    } else {
      _hubService.sendSessionTyping(widget.conversation.sessionId, isTyping).catchError((e) {
      });
    }
  }

  Future<void> _markAsRead() async {
    try {
      await widget.repository.markAsRead(
        accessToken: widget.session.accessToken,
        sessionId: widget.conversation.sessionId,
      );
    } catch (e) {
      // Silent fail
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollToMessage(String messageId) {
    // Find the index of the message
    final index = _messages.indexWhere((m) => m.messageId == messageId);
    if (index < 0) return;

    // Calculate scroll position
    final itemHeight = 80.0; // Approximate height of message item
    final offset = index * itemHeight;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _unpinMessage(String messageId) async {
    try {
      await widget.repository.unpinMessage(
        accessToken: widget.session.accessToken,
        sessionId: widget.conversation.sessionId,
        messageId: messageId,
        currentUserId: widget.session.userId,
      );
      
      if (mounted) {
        setState(() {
          _pinnedMessages.removeWhere((m) => m.messageId == messageId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã bỏ ghim tin nhắn')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  String _t(String vi, String en) => _language == AppLanguage.vi ? vi : en;

  @override
  Widget build(BuildContext context) {
    final title = widget.conversation.displayName.isEmpty
        ? _t('Cuộc trò chuyện', 'Conversation')
        : widget.conversation.displayName;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            _DetailHeader(
              title: title,
              language: _language,
              isOnline: _isOnline,
              isTyping: _isTyping,
              typingUserIds: _typingUserIds,
              activeUsers: _activeUsers,
              onBack: () => Navigator.of(context).pop(),
              onLanguageChanged: (lang) => setState(() => _language = lang),
            ),
            // Pinned messages section
            if (_pinnedMessages.isNotEmpty)
              _PinnedMessagesBar(
                messages: _pinnedMessages,
                onTap: _scrollToMessage,
                onUnpin: _unpinMessage,
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadHistory(),
                      child: _MessageList(
                        messages: _messages,
                        controller: _scrollController,
                        currentUserId: widget.session.userId,
                        loadingMore: _loadingMore,
                        repository: widget.repository,
                        accessToken: widget.session.accessToken,
                        sessionId: widget.conversation.sessionId,
                        activeUsers: _activeUsers,
                      ),
                    ),
            ),
            _Composer(
              controller: _composerController,
              onSubmit: _sendMessage,
              language: _language,
              sending: _sending,
              onChanged: _handleComposerChanged,
            ),
          ],
        ),
      ),
    );
  }
}
class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.title,
    required this.language,
    required this.isOnline,
    required this.isTyping,
    required this.typingUserIds,
    required this.activeUsers,
    required this.onBack,
    required this.onLanguageChanged,
  });

  final String title;
  final AppLanguage language;
  final bool isOnline;
  final bool isTyping;
  final List<String> typingUserIds;
  final List<Map<String, dynamic>> activeUsers;
  final VoidCallback onBack;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    // Get typing user names from activeUsers
    final typingNames = typingUserIds
        .map((id) => activeUsers
            .firstWhere(
              (u) => u['userId'] == id,
              orElse: () => {'displayName': 'Someone'},
            )['displayName']
            .toString())
        .toList();

    final statusText = typingUserIds.isNotEmpty
        ? '${typingNames.join(', ')} ${_statusText(language, 'đang nhập...', 'typing...')}'
        : isTyping
        ? _statusText(language, 'Đang nhập...', 'Typing...')
        : isOnline
        ? _statusText(language, 'Đang hoạt động', 'Active now')
        : _statusText(language, 'Ngoài tuyến', 'Offline');
    
    final statusColor = typingUserIds.isNotEmpty || isTyping
        ? const Color(0xFFF97316)
        : isOnline
        ? const Color(0xFF2ECC71)
        : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: onBack,
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE8EEFF),
            child: const Icon(
              Icons.bookmark_border_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF174230),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(AppLanguage lang, String vi, String en) =>
      lang == AppLanguage.vi ? vi : en;
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.controller,
    required this.currentUserId,
    required this.loadingMore,
    required this.repository,
    required this.accessToken,
    required this.sessionId,
    required this.activeUsers,
  });

  final List<ChatMessage> messages;
  final ScrollController controller;
  final String currentUserId;
  final bool loadingMore;
  final ChatRepository repository;
  final String accessToken;
  final String sessionId;
  final List<Map<String, dynamic>> activeUsers;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ChatMessage>>{};
    for (final message in messages) {
      final key =
          '${message.createdAt.year}-${message.createdAt.month}-${message.createdAt.day}';
      grouped.putIfAbsent(key, () => []).add(message);
    }
    final keys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: keys.length + (loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (loadingMore && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final adjustedIndex = loadingMore ? index - 1 : index;
        final key = keys[adjustedIndex];
        final groupMessages = grouped[key]!
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return Column(
          children: [
            _DaySeparator(label: _formatDay(groupMessages.first.createdAt)),
            const SizedBox(height: 12),
            ...groupMessages.map(
              (message) => _BubbleWithActions(
                message: message,
                isMine: message.senderId == currentUserId || message.isMine,
                repository: repository,
                accessToken: accessToken,
                sessionId: sessionId,
                activeUsers: activeUsers,
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  String _formatDay(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}

class _BubbleWithActions extends StatelessWidget {
  const _BubbleWithActions({
    required this.message,
    required this.isMine,
    required this.repository,
    required this.accessToken,
    required this.sessionId,
    required this.activeUsers,
  });

  final ChatMessage message;
  final bool isMine;
  final ChatRepository repository;
  final String accessToken;
  final String sessionId;
  final List<Map<String, dynamic>> activeUsers;

  String _formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = (hour % 12 == 0 ? 12 : hour % 12).toString().padLeft(
      2,
      '0',
    );
    return '$displayHour:$minute $period';
  }

  String _getPinnedByName(ChatMessage message) {
    // First try pinnedByName from model
    if (message.pinnedByName?.isNotEmpty == true) {
      return message.pinnedByName!;
    }
    // Then try to find from activeUsers if pinnedBy is available
    if (message.pinnedBy?.isNotEmpty == true) {
      try {
        final user = activeUsers.firstWhere(
          (u) => (u['userId'] ?? u['id']) == message.pinnedBy,
          orElse: () => {},
        );
        if (user.isNotEmpty) {
          return user['displayName'] ?? user['name'] ?? message.pinnedBy!;
        }
      } catch (_) {}
      return message.pinnedBy!; // Return ID if name not found
    }
    return 'Someone';
  }

  void _showMessageActions(BuildContext context) {
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
            // Pin message
            ListTile(
              leading: const Icon(Icons.push_pin, color: Color(0xFF2563EB)),
              title: const Text('Ghim'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final currentUserId = message.senderId;
                  await repository.pinMessage(
                    accessToken: accessToken,
                    sessionId: sessionId,
                    messageId: message.messageId,
                    currentUserId: currentUserId,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tin nhắn đã được ghim')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
            ),
            // Delete message (only for own messages)
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Xóa'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xóa tin nhắn'),
                      content: const Text('Bạn chắc chắn muốn xóa tin nhắn này?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    try {
                      final currentUserId = message.senderId;
                      await repository.deleteMessage(
                        accessToken: accessToken,
                        sessionId: sessionId,
                        messageId: message.messageId,
                        currentUserId: currentUserId,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tin nhắn đã được xóa')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? const Color(0xFFCFE5FF)
        : const Color(0xFFF2F4F7);
    final textColor = isMine
        ? const Color(0xFF0F172A)
        : const Color(0xFF1F2937);

    // Check if message is deleted
    final isDeleted = message.isDeleted ?? false;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: Radius.circular(isMine ? 0 : 16),
              bottomLeft: Radius.circular(isMine ? 16 : 0),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Text(
                  message.senderName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              if (!isMine) const SizedBox(height: 4),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    isDeleted ? 'Message deleted' : message.content,
                    style: TextStyle(
                      color: isDeleted ? const Color(0xFF94A3B8) : textColor,
                      fontSize: 15,
                      fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  if (message.isPinned ?? false)
                    Positioned(
                      right: -80,
                      top: -35,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.push_pin,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatMessageTime(message.createdAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSubmit,
    required this.language,
    required this.sending,
    this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final AppLanguage language;
  final bool sending;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                onChanged: onChanged,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: language == AppLanguage.vi
                      ? 'Soạn tin...'
                      : 'Type a message...',
                ),
              ),
            ),
          ),
          IconButton(
            icon: sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: Color(0xFF24A148)),
            onPressed: sending ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _PinnedMessagesBar extends StatefulWidget {
  const _PinnedMessagesBar({
    required this.messages,
    required this.onTap,
    required this.onUnpin,
  });

  final List<ChatMessage> messages;
  final Function(String messageId) onTap;
  final Function(String messageId) onUnpin;

  @override
  State<_PinnedMessagesBar> createState() => _PinnedMessagesBarState();
}

class _PinnedMessagesBarState extends State<_PinnedMessagesBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFEF3C7),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          GestureDetector(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Row(
              children: [
                const Icon(Icons.push_pin, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text(
                  '${widget.messages.length} tin được ghim',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
                const Spacer(),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: const Color(0xFF92400E),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _isExpanded = false);
                  },
                  child: const Icon(Icons.close, size: 16, color: Color(0xFF92400E)),
                ),
              ],
            ),
          ),
          // Expanded list
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.messages.length,
                    (index) {
                      final message = widget.messages[index];
                      return GestureDetector(
                        onTap: () => widget.onTap(message.messageId),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.senderName,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F2937),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      message.content,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF374151),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => widget.onUnpin(message.messageId),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}



