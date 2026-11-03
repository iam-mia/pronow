import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _prefKeyReminderEnabled = 'pronow_reminder_enabled';
  static const String _prefKeyReminderHour = 'pronow_reminder_hour';
  static const String _prefKeyReminderMinute = 'pronow_reminder_minute';
  static const String _prefKeyLastNotifiedDate = 'pronow_last_notified_date';

  static Timer? _reminderTimer;

  static void initializeTimer() {
    _reminderTimer?.cancel();
    // Check every 30 seconds against device time
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkAndTriggerReminder();
    });
  }

  static Future<void> _checkAndTriggerReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool enabled = prefs.getBool(_prefKeyReminderEnabled) ?? true;
      if (!enabled) return;

      int targetHour = prefs.getInt(_prefKeyReminderHour) ?? 20;
      int targetMinute = prefs.getInt(_prefKeyReminderMinute) ?? 0;

      final now = DateTime.now();
      final todayDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final lastNotifiedDate = prefs.getString(_prefKeyLastNotifiedDate);

      // If current hour and minute match, and we haven't already notified today
      if (now.hour == targetHour && now.minute == targetMinute && lastNotifiedDate != todayDateStr) {
        await prefs.setString(_prefKeyLastNotifiedDate, todayDateStr);
        showInstantNotification(
          title: '🔥 Đến giờ rèn luyện tiếng Anh!',
          body: 'Dành 3-5 phút hoàn thành mục tiêu phát âm hôm nay để giữ vững chuỗi ngày nhé.',
        );
      }
    } catch (_) {}
  }

  static Future<bool> requestNotificationPermission() async {
    debugPrint('Requesting notification permission from device...');
    return true;
  }

  static void showInstantNotification({
    required String title,
    required String body,
  }) {
    debugPrint('[PRO-NOW REMINDER] $title - $body');
  }

  static Future<void> saveReminderSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyReminderEnabled, enabled);
      await prefs.setInt(_prefKeyReminderHour, hour);
      await prefs.setInt(_prefKeyReminderMinute, minute);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> loadReminderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'enabled': prefs.getBool(_prefKeyReminderEnabled) ?? true,
        'hour': prefs.getInt(_prefKeyReminderHour) ?? 20,
        'minute': prefs.getInt(_prefKeyReminderMinute) ?? 0,
      };
    } catch (_) {
      return {
        'enabled': true,
        'hour': 20,
        'minute': 0,
      };
    }
  }
}
