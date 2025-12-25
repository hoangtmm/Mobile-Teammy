import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/constants/api_constants.dart';

class GroupInvitation {
  final String invitationId;
  final String groupId;
  final String? groupName;
  final String type; // member, mentor, mentor_request
  final String status; // pending, accepted, rejected, revoked, expired, pending_leader
  final DateTime createdAt;
  final String invitedBy; // User ID
  final String? topicId;
  final String? topicTitle;

  GroupInvitation({
    required this.invitationId,
    required this.groupId,
    required this.groupName,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.invitedBy,
    required this.topicId,
    required this.topicTitle,
  });

  bool get isPending => status == 'pending';

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      invitationId: json['invitationId'] as String,
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String?,
      type: json['type'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      invitedBy: json['invitedBy'] as String,
      topicId: json['topicId'] as String?,
      topicTitle: json['topicTitle'] as String?,
    );
  }
}

class GroupInvitationService {
  GroupInvitationService({
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
  
  final StreamController<GroupInvitation> _invitationController =
      StreamController.broadcast();
  
  final StreamController<Map<String, dynamic>> _invitationStatusController =
      StreamController.broadcast();
  
  Stream<GroupInvitation> get invitations => _invitationController.stream;
  Stream<Map<String, dynamic>> get invitationStatus => _invitationStatusController.stream;

  Future<void> _ensureConnection() async {
    if (_connection != null && 
        _connection!.state == HubConnectionState.Connected) {
      return;
    }

    try {
      _connection = HubConnectionBuilder()
          .withUrl(
            '$baseUrl$hubPath',
            options: HttpConnectionOptions(
              accessTokenFactory: () async => accessToken,
              transport: HttpTransportType.LongPolling,
            ),
          )
          .withAutomaticReconnect(retryDelays: [1000, 3000, 5000, 10000])
          .build();

      _setupListeners();

      await _connection!.start();
    } catch (e) {
      debugPrint('[GroupInvitationHub] Connection failed: $e');
      rethrow;
    }
  }

  void _setupListeners() {
    if (_connection == null) return;

    // Event: InvitationCreated - gửi cho user được mời
    _connection!.on('InvitationCreated', (message) {
      try {
        if (message != null && message.isNotEmpty) {
          final data = message[0] as Map<String, dynamic>;
          final invitation = GroupInvitation.fromJson(data);
          _invitationController.add(invitation);
        }
      } catch (e) {
        // Silently handle error
      }
    });

    // Event: InvitationStatusChanged - cập nhật status
    _connection!.on('InvitationStatusChanged', (message) {
      try {
        if (message != null && message.isNotEmpty) {
          final data = message[0] as Map<String, dynamic>;
          _invitationStatusController.add(data);
        }
      } catch (e) {
        // Silently handle error
      }
    });

    // Event: PendingUpdated - refresh pending list (for group leader)
    _connection!.on('PendingUpdated', (message) {
      try {
        if (message != null && message.isNotEmpty) {
          final data = message[0] as Map<String, dynamic>;
          final groupId = data['groupId'] as String;
          _invitationStatusController.add({'event': 'PendingUpdated', 'groupId': groupId});
        }
      } catch (e) {
        // Silently handle error
      }
    });

    _connection!.onclose(({error}) {
      // Connection closed
    });

    _connection!.onreconnected(({connectionId}) {
      // Reconnected
    });
  }

  Future<void> connect() async {
    try {
      await _ensureConnection();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinGroup(String groupId) async {
    try {
      await _ensureConnection();
      await _connection!.invoke('JoinGroup', args: [groupId]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> respondToInvitation({
    required String invitationId,
    required bool isAccepted,
  }) async {
    try {
      await _ensureConnection();
      // Backend implementation required - this is just placeholder
      // Backend should handle Accept/Decline via appropriate hub method
      print('[GroupInvitationHub] Responding to invitation: $invitationId - ${isAccepted ? 'Accept' : 'Decline'}');
    } catch (e) {
      print('[GroupInvitationHub] Error responding to invitation: $e');
      rethrow;
    }
  }

  void dispose() {
    _connection?.stop();
    _invitationController.close();
    _invitationStatusController.close();
  }
}
