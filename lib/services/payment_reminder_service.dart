import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/finance_models.dart';
import '../utils/currency_formatters.dart';

class PaymentReminderPlan {
  const PaymentReminderPlan({
    required this.daysBefore,
    required this.date,
    required this.title,
    required this.body,
  });

  final int daysBefore;
  final tz.TZDateTime date;
  final String title;
  final String body;
}

/// Schedules local Android reminders for planned payments two days before, one
/// day before, and on the due date itself.
class PaymentReminderService {
  PaymentReminderService._();

  static final PaymentReminderService instance = PaymentReminderService._();

  static const String _channelId = 'payment_reminders';
  static const String _channelName = 'Payment reminders';
  static const String _channelDescription =
      'Reminders for upcoming planned payments';
  static const int _reminderHour = 9;
  static const int _reminderIdOffset = 100000;
  static const int _tomorrowIdOffset = 300000;
  static const int _dueIdOffset = 200000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Falls back to the default (UTC) location when the timezone cannot be
      // resolved, so scheduling still succeeds.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('notification_icon'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
    _initialized = true;
  }

  Future<bool> _ensurePermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? true;
  }

  /// Replaces all pending reminders with fresh ones for [payments].
  Future<void> scheduleReminders(List<PlannedPayment> payments) async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();
    if (payments.isEmpty) return;
    if (!await _ensurePermission()) return;

    final now = tz.TZDateTime.now(tz.local);
    for (final payment in payments) {
      for (final plan in buildReminderPlan(payment, now: now)) {
        final offset = switch (plan.daysBefore) {
          2 => _reminderIdOffset,
          1 => _tomorrowIdOffset,
          _ => _dueIdOffset,
        };
        await _schedule(
          id: offset + _stableId(payment.id),
          date: plan.date,
          title: plan.title,
          body: plan.body,
        );
      }
    }
  }

  static List<PaymentReminderPlan> buildReminderPlan(
    PlannedPayment payment, {
    tz.TZDateTime? now,
  }) {
    final current = now ?? tz.TZDateTime.now(tz.local);
    final due = payment.nextDue(from: current);
    final dueDate = tz.TZDateTime(
      tz.local,
      due.year,
      due.month,
      due.day,
      _reminderHour,
    );
    final sign = payment.isIncome ? '+' : '-';
    final amount = formatCurrency(payment.amount);
    final plans = <PaymentReminderPlan>[];
    for (final daysBefore in [2, 1, 0]) {
      final date = dueDate.subtract(Duration(days: daysBefore));
      if (!date.isAfter(current)) continue;
      final title = daysBefore == 0
          ? 'Payment due today'
          : 'Payment coming up in $daysBefore ${daysBefore == 1 ? 'day' : 'days'}';
      final body = daysBefore == 0
          ? '${payment.title} · $sign$amount'
          : '${payment.title} is due in $daysBefore '
                '${daysBefore == 1 ? 'day' : 'days'} · $sign$amount';
      plans.add(
        PaymentReminderPlan(
          daysBefore: daysBefore,
          date: date,
          title: title,
          body: body,
        ),
      );
    }
    return plans;
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime date,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: date,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  int _stableId(String id) {
    final parsed = int.tryParse(id);
    if (parsed != null) return parsed & 0x3FFFFFFF;
    return id.hashCode & 0x3FFFFFFF;
  }
}
