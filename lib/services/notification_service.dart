import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/card_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'card_tracker_channel';
  static const _channelName = '카드 실적 알림';
  static const _channelDesc = '카드 실적 달성 및 월말 알림';

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// 실적 임계값 달성 즉시 알림
  Future<void> showAchievementNotification({
    required CardModel card,
    required double achievementRate,
  }) async {
    final id = card.id.hashCode;
    await _plugin.show(
      id,
      '${card.name} 실적 달성!',
      '이번 달 실적이 ${achievementRate.toStringAsFixed(0)}% 달성되었습니다.',
      _notificationDetails,
    );
  }

  /// 월말 D-N 정기 알림 예약
  Future<void> scheduleMonthEndReminders(CardModel card) async {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);

    for (final daysLeft in [7, 3, 1]) {
      final scheduleDate = lastDay.subtract(Duration(days: daysLeft - 1));
      if (scheduleDate.isAfter(now)) {
        await _scheduleNotification(
          id: _monthEndNotificationId(card.id, daysLeft),
          title: '${card.name} 월말 실적 알림',
          body: '이번 달 마감까지 D-$daysLeft입니다. 실적을 확인하세요!',
          scheduledDate: tz.TZDateTime.from(
            DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day, 9),
            tz.local,
          ),
        );
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelCardNotifications(String cardId) async {
    for (final daysLeft in [7, 3, 1]) {
      await _plugin.cancel(_monthEndNotificationId(cardId, daysLeft));
    }
    await _plugin.cancel(cardId.hashCode);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  int _monthEndNotificationId(String cardId, int daysLeft) {
    return '${cardId}_end_$daysLeft'.hashCode;
  }
}
