import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';
class ChatHubService {
  ChatHubService({
    required this.baseUrl,
    required this.accessToken,
    required this.currentUserId,
    this.hubPath = ApiPath.chatHub,
  });
  final String baseUrl;
  final String accessToken;
  final String currentUserId;
  final String hubPath;
  HubConnection? _connection;
  String? _joinedSessionId;
  String? _joinedGroupId;
  final Set<String> _groupMembersOnline = <String>{};
  List<Map<String, dynamic>> _currentActiveUsers = [];
  final Set<String> _typingUsers = <String>{};
  Timer? _typingTimeoutTimer;
  final StreamController<ChatMessage> _messageController =
      StreamController.broadcast();
  final StreamController<ChatMessage> _messageUpdatedController =
      StreamController.broadcast();
  final StreamController<bool> _presenceController =
      StreamController.broadcast();
  final StreamController<bool> _typingController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _globalPresenceController =
      StreamController.broadcast();
  final StreamController<List<Map<String, dynamic>>> _activeUsersController =
      StreamController.broadcast();
  final StreamController<List<String>> _typingUsersController =
      StreamController.broadcast();
  Stream<ChatMessage> get messages => _messageController.stream;
  Stream<ChatMessage> get messageUpdated => _messageUpdatedController.stream;
  Stream<bool> get presence => _presenceController.stream;
  Stream<bool> get typing => _typingController.stream;
  Stream<List<String>> get typingUsers => _typingUsersController.stream;
  Stream<Map<String, dynamic>> get globalPresence => _globalPresenceController.stream;
  Stream<List<Map<String, dynamic>>> get activeUsers => _activeUsersController.stream;

  Future<void> _ensureConnection() async {
    if (_connection != null && 
        _connection!.state == HubConnectionState.Connected) {
      return;
    }

    if (_connection != null) {
      try {
        await _connection?.stop();
      } catch (e) {
      }
      _connection = null;
    }

    final hubUrl = '$baseUrl$hubPath';
    final builder = HubConnectionBuilder()
      ..withUrl(
        hubUrl,
        options: HttpConnectionOptions(
          accessTokenFactory: () async => accessToken,
          transport: HttpTransportType.LongPolling,
        ),
      )
      ..withAutomaticReconnect();

    final connection = builder.build();
    connection.on('ReceiveMessage', _onReceiveMessage);
    connection.on('MessageUpdated', _onMessageUpdated);
    connection.on('SessionPresenceSnapshot', _onSessionPresenceSnapshot);
    connection.on('SessionPresenceChanged', _onSessionPresenceChanged);
    connection.on('PresenceChanged', _onGroupPresenceChanged);
    connection.on('TypingSession', _onTypingSession);
    connection.on('Typing', _onGroupTyping);
    connection.on('UserOnline', _onUserOnline);
    connection.on('UserOffline', _onUserOffline);

    connection.onreconnected(({connectionId}) {
      final sessionId = _joinedSessionId;
      if (sessionId != null) {
        connection.invoke('JoinSession', args: <Object>[sessionId]).catchError((e) {
          return null;
        });
      }
      final groupId = _joinedGroupId;
      if (groupId != null) {
        connection.invoke('JoinGroup', args: <Object>[groupId]).catchError((e) {
          return null;
        });
      }
    });

    int retries = 0;
    const maxRetries = 3;
    
    while (retries < maxRetries) {
      try {
        await connection.start()?.timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Connection timeout'),
        );
        _connection = connection;
        return;
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * retries));
      }
    }
  }

  Future<void> joinSession(String sessionId) async {
    _joinedSessionId = sessionId;
    _currentActiveUsers = []; 
    await _ensureConnection();
    if (_connection != null) {
      await _connection!.invoke('JoinSession', args: [sessionId]);
    }
  }

  Future<void> leaveSession(String sessionId) async {
    if (_connection == null) return;
    if (_joinedSessionId == sessionId) {
      _joinedSessionId = null;
      _currentActiveUsers = []; 
      _activeUsersController.add([]);
    }
    await _connection?.invoke('LeaveSession', args: [sessionId]);
  }

  Future<void> joinGroup(String groupId) async {
    _joinedGroupId = groupId;
    _currentActiveUsers = []; 
    await _ensureConnection();
    if (_connection != null) {
      await _connection!.invoke('JoinGroup', args: [groupId]);
    }
  }

  Future<void> leaveGroup(String groupId) async {
    if (_connection == null) return;
    if (_joinedGroupId == groupId) {
      _joinedGroupId = null;
      _currentActiveUsers = []; 
      _activeUsersController.add([]);
    }
    await _connection?.invoke('LeaveGroup', args: [groupId]);
  }

  Future<void> sendSessionTyping(String sessionId, bool isTyping) async {
    try {
      await _ensureConnection();
      if (_connection != null) {
        await _connection!.invoke('TypingSession', args: [sessionId, isTyping]);
      }
    } catch (e) {
     
    }
  }

  Future<void> sendGroupTyping(String groupId, bool isTyping) async {
    try {
      await _ensureConnection();
      if (_connection != null) {
        await _connection!.invoke('Typing', args: [groupId, isTyping]);
      }
    } catch (e) {
   
    }
  }

  String? _activeConversationId() => _joinedGroupId ?? _joinedSessionId;

  void _onReceiveMessage(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;
    
    final message = ChatMessageModel.fromJson(
      Map<String, dynamic>.from(data),
      currentUserId: currentUserId,
      fallbackSessionId: _activeConversationId(),
    );
    _messageController.add(message);
  }

  void _onMessageUpdated(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;
    
    final message = ChatMessageModel.fromJson(
      Map<String, dynamic>.from(data),
      currentUserId: currentUserId,
      fallbackSessionId: _activeConversationId(),
    );
    _messageUpdatedController.add(message);
  }

  void _onSessionPresenceSnapshot(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;

    final map = Map<String, dynamic>.from(data);
    final sessionId = map['sessionId']?.toString() ?? _joinedSessionId;
    if (sessionId == null || sessionId != _joinedSessionId) return;

    final users = map['users'] as List?;
    final activeUsers = <Map<String, dynamic>>[];
    
    var hasOtherUserOnline = false;
    if (users != null) {
      for (final user in users) {
        if (user is Map) {
          final userId = user['userId']?.toString();
          final displayName = user['displayName']?.toString();
          if (userId != null && userId != currentUserId) {
            hasOtherUserOnline = true;
            activeUsers.add({
              'userId': userId,
              'displayName': displayName ?? 'Unknown',
            });
          }
        }
      }
    }

    _presenceController.add(hasOtherUserOnline);
    _activeUsersController.add(activeUsers);
  }

  void _onSessionPresenceChanged(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;

    final map = Map<String, dynamic>.from(data);
    final sessionId = map['sessionId']?.toString() ?? _joinedSessionId;
    final userId = map['userId']?.toString();
    final displayName = map['displayName']?.toString();
    final status = map['status']?.toString().toLowerCase();

    if (sessionId == null || sessionId != _joinedSessionId || userId == null) return;
    if (userId == currentUserId) return;
    if (status == 'joined') {
      if (!_currentActiveUsers.any((u) => u['userId'] == userId)) {
        _currentActiveUsers.add({
          'userId': userId,
          'displayName': displayName ?? 'Unknown',
        });
      }
    } else if (status == 'left') {
      _currentActiveUsers.removeWhere((u) => u['userId'] == userId);
    }
    
    _activeUsersController.add(List.from(_currentActiveUsers));
    
    final isOnline = status == 'joined' || status == 'online';
    _presenceController.add(isOnline);
  }

  void _onGroupPresenceChanged(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;

    final map = Map<String, dynamic>.from(data);
    final groupId = map['groupId']?.toString() ?? _joinedGroupId;
    final status = map['status']?.toString().toLowerCase();
    final userId = map['userId']?.toString();
    final displayName = map['displayName']?.toString();

    if (groupId == null || groupId != _joinedGroupId || userId == null) {
      return;
    }

    if (userId == currentUserId) return;

    if (status == 'joined') {
      _groupMembersOnline.add(userId);
      if (!_currentActiveUsers.any((u) => u['userId'] == userId)) {
        _currentActiveUsers.add({
          'userId': userId,
          'displayName': displayName ?? 'Unknown',
        });
      }
    } else if (status == 'left') {
      _groupMembersOnline.remove(userId);
      _currentActiveUsers.removeWhere((u) => u['userId'] == userId);
    }
    _activeUsersController.add(List.from(_currentActiveUsers));
    
    _presenceController.add(_groupMembersOnline.isNotEmpty);
  }

  void _onTypingSession(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;

    final map = Map<String, dynamic>.from(data);
    final sessionId = map['sessionId']?.toString() ?? _joinedSessionId;
    final userId = map['userId']?.toString();
    final isTyping = map['isTyping'] == true;

    if (sessionId == null || sessionId != _joinedSessionId || userId == null || userId == currentUserId) return;
    
    if (isTyping) {
      _typingUsers.add(userId);
    } else {
      _typingUsers.remove(userId);
    }
    
    _typingController.add(_typingUsers.isNotEmpty);
    _typingUsersController.add(List.from(_typingUsers));
    
    _typingTimeoutTimer?.cancel();
    _typingTimeoutTimer = Timer(const Duration(seconds: 5), () {
      _typingUsers.clear();
      _typingController.add(false);
      _typingUsersController.add([]);
    });
  }

  void _onGroupTyping(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;

    final map = Map<String, dynamic>.from(data);
    final groupId = map['groupId']?.toString() ?? _joinedGroupId;
    final userId = map['userId']?.toString();
    final isTyping = map['isTyping'] == true;

    if (groupId == null || groupId != _joinedGroupId || userId == null || userId == currentUserId) return;
    
    if (isTyping) {
      _typingUsers.add(userId);
    } else {
      _typingUsers.remove(userId);
    }
    
    _typingController.add(_typingUsers.isNotEmpty);
    _typingUsersController.add(List.from(_typingUsers));
    
    _typingTimeoutTimer?.cancel();
    _typingTimeoutTimer = Timer(const Duration(seconds: 5), () {
      _typingUsers.clear();
      _typingController.add(false);
      _typingUsersController.add([]);
    });
  }

  void _onUserOnline(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;

    final map = Map<String, dynamic>.from(data);
    final userId = map['userId']?.toString();
    if (userId != null && userId != currentUserId) {
      _globalPresenceController.add({
        'userId': userId,
        'displayName': map['displayName'],
        'status': 'online',
      });
    }
  }

  void _onUserOffline(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;

    final map = Map<String, dynamic>.from(data);
    final userId = map['userId']?.toString();
    if (userId != null && userId != currentUserId) {
      _globalPresenceController.add({
        'userId': userId,
        'displayName': map['displayName'],
        'status': 'offline',
      });
    }
  }

  Future<void> dispose() async {
    _typingTimeoutTimer?.cancel();
    await _connection?.stop();
    _connection = null;
    await _messageController.close();
    await _messageUpdatedController.close();
    await _presenceController.close();
    await _typingController.close();
    await _typingUsersController.close();
    await _globalPresenceController.close();
    await _activeUsersController.close();
  }
}
