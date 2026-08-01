import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/finance_models.dart';
import '../utils/currency_formatters.dart';

/// Schedules local Android reminders for planned payments: one two days before
/// the due date and one on the due date itself.
class PaymentReminderService {
  PaymentReminderService._();

  static final PaymentReminderService instance = PaymentReminderService._();

  static const String _channelId = 'payment_reminders';
  static const String _channelName = 'Payment reminders';
  static const String _channelDescription =
      'Reminders for upcoming planned payments';
  static const int _reminderHour = 9;
  static const int _reminderIdOffset = 100000;
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
      final due = payment.nextDue();
      final dueDate = _atHour(due, _reminderHour);
      if (dueDate.isAfter(now)) {
        await _schedule(
          id: _dueIdOffset + _stableId(payment.id),
          date: dueDate,
          title: 'Due today',
          body:
              '${payment.title} · ${payment.isIncome ? '+' : '-'}'
              '${formatCurrency(payment.amount)}',
        );
      }
      final reminderDate = dueDate.subtract(const Duration(days: 2));
      if (reminderDate.isAfter(now)) {
        await _schedule(
          id: _reminderIdOffset + _stableId(payment.id),
          date: reminderDate,
          title: 'Payment coming up',
          body:
              '${payment.title} is due in 2 days · '
              '${payment.isIncome ? '+' : '-'}'
              '${formatCurrency(payment.amount)}',
        );
      }
    }
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

  tz.TZDateTime _atHour(DateTime date, int hour) {
    final local = tz.local;
    final current = tz.TZDateTime(local, date.year, date.month, date.day, hour);
    return current;
  }

  int _stableId(String id) {
    final parsed = int.tryParse(id);
    if (parsed != null) return parsed & 0x3FFFFFFF;
    return id.hashCode & 0x3FFFFFFF;
  }
}
