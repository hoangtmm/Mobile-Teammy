import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  int _notificationId = 0;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create Android notification channels
    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.max,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel invitationChannel = AndroidNotificationChannel(
      'group_invitations',
      'Group Invitations',
      description: 'Notifications for group invitations',
      importance: Importance.high,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    final androidImpl = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(chatChannel);
      await androidImpl.createNotificationChannel(invitationChannel);
    }

    _isInitialized = true;
  }

  Future<void> showMessageNotification({
    required String title,
    required String body,
    required String sessionId,
    String? senderName,
  }) async {
    if (!_isInitialized) {
      print('[NotificationService] Not initialized, initializing now...');
      await initialize();
    }

    _notificationId++;
    final notificationId = _notificationId;
    
    print('[NotificationService] Showing notification #$notificationId: $title - $body');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFF2563EB),
      autoCancel: false,
      onlyAlertOnce: false,
      groupKey: 'chat_messages',
      setAsGroupSummary: false,
      showWhen: true,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: sessionId,
      );
      print('[NotificationService] Notification #$notificationId showed successfully');
    } catch (e) {
      print('[NotificationService] Error showing notification: $e');
    }
  }

  Future<void> showGroupInvitationNotification({
    required String groupName,
    required String invitationType,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    _notificationId++;
    final notificationId = _notificationId;
    
    final title = _getInvitationTitle(invitationType);
    final body = groupName;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'group_invitations',
      'Group Invitations',
      channelDescription: 'Notifications for group invitations',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFF10B981),
      autoCancel: false,
      onlyAlertOnce: false,
      groupKey: 'group_invitations',
      setAsGroupSummary: false,
      showWhen: true,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      // Error showing group invitation
    }
  }

  String _getInvitationTitle(String type) {
    switch (type) {
      case 'mentor':
        return 'Lời mời làm mentor';
      case 'mentor_request':
        return 'Yêu cầu mentor';
      case 'member':
      default:
        return 'Lời mời vào nhóm';
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    final payload = notificationResponse.payload;
    if (payload != null) {
      // Navigation can be handled by app
    }
  }

  Future<void> requestPermissions() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Request iOS permissions
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request Android 13+ permissions
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}

