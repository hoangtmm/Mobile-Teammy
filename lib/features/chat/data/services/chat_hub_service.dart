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

  final StreamController<ChatMessage> _messageController =
      StreamController.broadcast();
  final StreamController<bool> _presenceController =
      StreamController.broadcast();
  final StreamController<bool> _typingController = StreamController.broadcast();

  Stream<ChatMessage> get messages => _messageController.stream;
  Stream<bool> get presence => _presenceController.stream;
  Stream<bool> get typing => _typingController.stream;

  Future<void> _ensureConnection() async {
    if (_connection != null) return;
    final hubUrl = '$baseUrl$hubPath';
    final builder = HubConnectionBuilder()
      ..withUrl(
        hubUrl,
        options: HttpConnectionOptions(
          accessTokenFactory: () async => accessToken,
        ),
      )
      ..withAutomaticReconnect();

    final connection = builder.build();
    connection.on('ReceiveMessage', _onReceiveMessage);
    connection.on('SessionPresenceChanged', _onSessionPresenceChanged);
    connection.on('PresenceChanged', _onGroupPresenceChanged);
    connection.on('TypingSession', _onTypingSession);
    connection.on('Typing', _onTypingSession);
    await connection.start();
    _connection = connection;
  }

  Future<void> joinSession(String sessionId) async {
    _joinedSessionId = sessionId;
    await _ensureConnection();
    await _connection?.invoke('JoinSession', args: [sessionId]);
  }

  Future<void> leaveSession(String sessionId) async {
    if (_connection == null) return;
    if (_joinedSessionId == sessionId) {
      _joinedSessionId = null;
    }
    await _connection?.invoke('LeaveSession', args: [sessionId]);
  }

  Future<void> joinGroup(String groupId) async {
    _joinedGroupId = groupId;
    await _ensureConnection();
    await _connection?.invoke('JoinGroup', args: [groupId]);
    
  }

  Future<void> leaveGroup(String groupId) async {
    if (_connection == null) return;
    if (_joinedGroupId == groupId) {
      _joinedGroupId = null;
    }
    await _connection?.invoke('LeaveGroup', args: [groupId]);
  }

  Future<void> sendSessionTyping(String sessionId, bool isTyping) async {
    await _ensureConnection();
    await _connection?.invoke('TypingSession', args: [sessionId, isTyping]);
  }

  Future<void> sendGroupTyping(String groupId, bool isTyping) async {
    await _ensureConnection();
    await _connection?.invoke('Typing', args: [groupId, isTyping]);
  }

  void _onReceiveMessage(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;

    final message = ChatMessageModel.fromJson(
      Map<String, dynamic>.from(data),
      currentUserId: currentUserId,
      fallbackSessionId: _joinedSessionId ?? _joinedGroupId,
    );
    _messageController.add(message);
  }

  void _onSessionPresenceChanged(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final sessionId = map['sessionId']?.toString();
    final status = map['status']?.toString().toLowerCase();
    final userId = map['userId']?.toString();
    if (sessionId == null ||
        sessionId != _joinedSessionId ||
        userId == currentUserId) {
      return;
    }
    final isOnline = status == 'joined' || status == 'online';
    _presenceController.add(isOnline);
  }

  void _onTypingSession(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final sessionId = map['sessionId']?.toString();
    final isTyping = map['isTyping'] == true;
    final groupId = map['groupId']?.toString();

    if (sessionId != null &&
        sessionId == _joinedSessionId &&
        map['userId']?.toString() != currentUserId) {
      _typingController.add(isTyping);
      return;
    }

    if (groupId != null &&
        groupId == _joinedGroupId &&
        map['userId']?.toString() != currentUserId) {
      _typingController.add(isTyping);
    }
  }

  void _onGroupPresenceChanged(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    final data = arguments.first;
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final groupId = map['groupId']?.toString();
    final status = map['status']?.toString().toLowerCase();
    final userId = map['userId']?.toString();
    if (groupId == null || groupId != _joinedGroupId || userId == null) return;
    if (userId == currentUserId) return;

    if (status == 'joined') {
      _groupMembersOnline.add(userId);
    } else if (status == 'left') {
      _groupMembersOnline.remove(userId);
    }
    _presenceController.add(_groupMembersOnline.isNotEmpty);
  }

  Future<void> dispose() async {
    await _connection?.stop();
    _connection = null;
    await _messageController.close();
    await _presenceController.close();
    await _typingController.close();
  }
}
