import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

/// Seconds (on the server clock) until the earliest thing on the farm becomes ready, or
/// null when nothing is still growing. Already-ripe plots and ready animals are ignored:
/// the player can see them, and a reminder for them would fire immediately.
int? secondsUntilNextReady(Farm farm, int serverNow) {
  int? soonest;
  void consider(int? readyAt) {
    if (readyAt == null || readyAt <= serverNow) return;
    if (soonest == null || readyAt < soonest!) soonest = readyAt;
  }

  for (final p in farm.plots) {
    if (p.cropId != null) consider(p.readyAt);
  }
  for (final a in farm.animals) {
    consider(a.readyAt);
  }
  return soonest == null ? null : soonest! - serverNow;
}

abstract class NotificationScheduler {
  Future<void> cancel();
  Future<void> scheduleIn(Duration delay, {required String title, required String body});
}

/// Keeps exactly one pending "something is ready" reminder, for the earliest ready time.
/// It is re-evaluated whenever the farm changes, so it always matches the server state.
class ReadyReminder {
  final NotificationScheduler scheduler;
  ReadyReminder(this.scheduler);

  Future<void> update(Farm farm, int serverNow) async {
    try {
      await scheduler.cancel();
      final seconds = secondsUntilNextReady(farm, serverNow);
      if (seconds != null) {
        await scheduler.scheduleIn(
          Duration(seconds: seconds),
          title: 'Счастливая ферма',
          body: 'Что-то созрело! Заходи на ферму 🌾',
        );
      }
    } catch (e) {
      // Reminders are best effort; never let them break the game.
      debugPrint('Reminder update failed: $e');
    }
  }
}

/// iOS local notifications. Permission is requested lazily, at the first reminder (that is,
/// after the player planted something), not at app launch.
class LocalNotificationScheduler implements NotificationScheduler {
  static const _id = 1;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true, badge: true);
    _ready = true;
  }

  @override
  Future<void> cancel() async {
    if (!_ready) return; // nothing was ever scheduled in this run
    await _plugin.cancel(id: _id);
  }

  @override
  Future<void> scheduleIn(Duration delay, {required String title, required String body}) async {
    await _init();
    await _plugin.zonedSchedule(
      id: _id,
      // An absolute instant, so the device time zone does not matter.
      scheduledDate: tz.TZDateTime.now(tz.UTC).add(delay),
      notificationDetails: const NotificationDetails(iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
    );
  }
}
