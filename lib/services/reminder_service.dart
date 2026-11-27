import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/attention.dart';
import '../models/doc_item.dart';

/// Local hour (24h) at which reminders are shown.
const reminderHour = 9;

/// Both iOS and Android cap how many local notifications can be pending, so
/// only the soonest ones are scheduled. They are rebuilt on every change.
const maxScheduledReminders = 50;

/// The local moments at which to remind about an event on [day]: 09:00 the
/// day before and 09:00 on the day, keeping only those still after [now].
List<DateTime> reminderMoments(DateTime day, DateTime now) {
  final dayBefore = DateTime(day.year, day.month, day.day - 1, reminderHour);
  final dayOf = DateTime(day.year, day.month, day.day, reminderHour);
  return [dayBefore, dayOf].where((t) => t.isAfter(now)).toList();
}

/// The next Monday at [reminderHour] local time that is after [now].
DateTime nextWeeklyDigest(DateTime now) {
  var day = DateTime(now.year, now.month, now.day, reminderHour);
  while (day.weekday != DateTime.monday || !day.isAfter(now)) {
    day = DateTime(day.year, day.month, day.day + 1, reminderHour);
  }
  return day;
}

class _Planned {
  final DateTime at;
  final String title, body;

  /// Stored path of the document, handed back when the notification is tapped.
  final String? payload;
  const _Planned(this.at, this.title, this.body, this.payload);
}

/// Schedules on-device reminders for dates found in analyzed documents.
///
/// Nothing leaves the device. The scheduled set is always rebuilt from the
/// saved analyses, so it can never drift from what the app shows.
abstract final class ReminderService {
  static const prefsKey = 'reminders_enabled';
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Set to a document's stored path when its reminder is tapped while the
  /// app is running. The listener resets it to null once handled.
  static final ValueNotifier<String?> tapped = ValueNotifier<String?>(null);

  /// The document path of the reminder that launched the app from a closed
  /// state, or null when the app was opened some other way.
  static Future<String?> takeLaunchPayload() async {
    await _init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  static Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) tapped.value = payload;
      },
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested later, when the user turns reminders on.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Asks the OS for permission to show notifications. Returns whether it
  /// was granted.
  static Future<bool> requestPermission() async {
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  static Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }

  /// Replaces every scheduled reminder with the ones the current [docs]
  /// call for. Returns how many were scheduled.
  static Future<int> sync(List<DocItem> docs, {DateTime? now}) async {
    await _init();
    await _plugin.cancelAll();
    final clock = now ?? DateTime.now();
    final planned = <_Planned>[];
    final events = collectAttention(docs, clock, windowDays: 365)
        .where((i) => i.kind == AttentionKind.upcomingDate && i.when != null);
    for (final event in events) {
      for (final at in reminderMoments(event.when!, clock)) {
        final sameDay = at.day == event.when!.day;
        planned.add(_Planned(
            at,
            '${sameDay ? 'Today' : 'Tomorrow'}: ${event.title}',
            event.doc.name,
            event.doc.path));
      }
    }
    planned.sort((a, b) => a.at.compareTo(b.at));
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'deadlines',
        'Document deadlines',
        channelDescription: 'Reminders for dates found in your documents',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final chosen = planned.take(maxScheduledReminders).toList();
    for (var i = 0; i < chosen.length; i++) {
      final item = chosen[i];
      await _plugin.zonedSchedule(
        id: i,
        title: item.title,
        body: item.body,
        // An absolute instant expressed in UTC: correct on any device
        // time zone without needing the local zone's name.
        scheduledDate: tz.TZDateTime.fromMillisecondsSinceEpoch(
            tz.UTC, item.at.millisecondsSinceEpoch),
        notificationDetails: details,
        payload: item.payload,
        // Inexact: no exact-alarm permission, may fire a few minutes late.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    if (docs.isNotEmpty) await _scheduleWeeklyDigest(details, clock);
    return chosen.length;
  }

  static const _digestId = 9000;

  /// A gentle weekly nudge, Mondays at 09:00, to look at what needs
  /// attention. Rebuilt on each sync, so it follows the device time zone
  /// and daylight saving changes whenever the app is opened.
  static Future<void> _scheduleWeeklyDigest(
      NotificationDetails details, DateTime now) async {
    await _plugin.zonedSchedule(
      id: _digestId,
      title: 'Your week in DocuMind',
      body: 'Check upcoming dates and documents that need attention.',
      scheduledDate: tz.TZDateTime.fromMillisecondsSinceEpoch(
          tz.UTC, nextWeeklyDigest(now).millisecondsSinceEpoch),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}
