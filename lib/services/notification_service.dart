import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        print('Notification tapped: ${r.payload}');
      },
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
    print('✅ Notification service initialized');
  }

  NotificationDetails _details({
    Importance importance = Importance.high,
    Priority priority = Priority.high,
    bool ongoing = false,
    bool autoCancel = true,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'fire_risk_channel',
        'Fire Risk Alerts',
        channelDescription: 'Forest fire risk status notifications',
        importance: importance,
        priority: priority,
        playSound: true,
        enableVibration: true,
        ongoing: ongoing,
        autoCancel: autoCancel,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> showSafeNotification() async {
    await _notifications.show(
      id: 0,
      title: '🟢 Forest Fire Monitor - Safe',
      body: 'All conditions are normal. No fire risk detected.',
      notificationDetails: _details(),
    );
  }

  Future<void> showRiskNotification(double riskScore) async {
    if (riskScore < 20) {
      await _notifications.show(
        id: 1,
        title: '🟢 Low Risk - Safe',
        body:
            'Fire risk: ${riskScore.toStringAsFixed(1)}%. Conditions are safe.',
        notificationDetails: _details(),
      );
    } else if (riskScore < 40) {
      await _notifications.show(
        id: 2,
        title: '🟡 Moderate Risk',
        body: 'Fire risk: ${riskScore.toStringAsFixed(1)}%. Stay alert.',
        notificationDetails: _details(),
      );
    } else if (riskScore < 60) {
      await _notifications.show(
        id: 3,
        title: '🟠 High Risk Alert!',
        body:
            'Fire risk: ${riskScore.toStringAsFixed(1)}%. Prepare equipment now!',
        notificationDetails: _details(
          importance: Importance.max,
          priority: Priority.max,
        ),
      );
    } else if (riskScore < 80) {
      await _notifications.show(
        id: 4,
        title: '🔴 Very High Risk - Danger!',
        body:
            'Fire risk: ${riskScore.toStringAsFixed(1)}%. Activate emergency protocols!',
        notificationDetails: _details(
          importance: Importance.max,
          priority: Priority.max,
          ongoing: true,
        ),
      );
    } else {
      await _notifications.show(
        id: 5,
        title: '🚨 CRITICAL - EXTREME DANGER!',
        body:
            'Fire risk: ${riskScore.toStringAsFixed(1)}%. Call fire department NOW!',
        notificationDetails: _details(
          importance: Importance.max,
          priority: Priority.max,
          ongoing: true,
          autoCancel: false,
        ),
      );
    }
  }

  Future<void> cancelAll() async => _notifications.cancelAll();
  Future<void> cancel(int notifId) async => _notifications.cancel(id: notifId);
}
