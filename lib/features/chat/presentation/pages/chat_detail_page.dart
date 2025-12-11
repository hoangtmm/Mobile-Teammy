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
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _sending = false;
  bool _isOnline = false;
  bool _isTyping = false;
  int _currentPage = 1;

  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<bool>? _presenceSub;
  StreamSubscription<bool>? _typingSub;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadHistory();
    _connectHub();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _messageSub?.cancel();
    _presenceSub?.cancel();
    _typingSub?.cancel();
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
          setState(() => _messages = [..._messages, message]);
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

    // Optimistic update - add message immediately to UI
    final optimisticMessage = ChatMessage(
      messageId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: widget.conversation.sessionId,
      senderId: widget.session.userId,
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
      await widget.repository.sendMessage(
        accessToken: widget.session.accessToken,
        sessionId: widget.conversation.sessionId,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        _showError('Failed to send message: $e');
        setState(() {
          _messages = _messages
              .where((m) => m.messageId != optimisticMessage.messageId)
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
              onBack: () => Navigator.of(context).pop(),
              onLanguageChanged: (lang) => setState(() => _language = lang),
            ),
            const SizedBox(height: 8),
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
    required this.onBack,
    required this.onLanguageChanged,
  });

  final String title;
  final AppLanguage language;
  final bool isOnline;
  final bool isTyping;
  final VoidCallback onBack;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final statusText = isTyping
        ? _statusText(language, 'Đang nhập...', 'Typing...')
        : isOnline
        ? _statusText(language, 'Đang hoạt động', 'Active now')
        : _statusText(language, 'Ngoài tuyến', 'Offline');
    final statusColor = isTyping
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
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF1B2B57)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Color(0xFF1B2B57)),
            onPressed: () {},
          ),
          PopupMenuButton<AppLanguage>(
            onSelected: onLanguageChanged,
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => AppLanguage.values
                .map(
                  (lang) => PopupMenuItem(
                    value: lang,
                    child: Text('${lang.displayName} ${lang.flag}'),
                  ),
                )
                .toList(),
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
  });

  final List<ChatMessage> messages;
  final ScrollController controller;
  final String currentUserId;
  final bool loadingMore;

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
              (message) => _Bubble(
                message: message,
                isMine: message.senderId == currentUserId || message.isMine,
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

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

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? const Color(0xFFCFE5FF)
        : const Color(0xFFF2F4F7);
    final textColor = isMine
        ? const Color(0xFF0F172A)
        : const Color(0xFF1F2937);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
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
            Text(
              message.content,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              _formatMessageTime(message.createdAt),
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
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
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF24A148),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.image_outlined, color: Color(0xFF2563EB)),
            onPressed: () {},
          ),
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
