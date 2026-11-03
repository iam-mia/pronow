import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class DisciplineState {
  static const String _keyCurrentStreak = 'pronow_current_streak';
  static const String _keyLongestStreak = 'pronow_longest_streak';
  static const String _keyFreezeDays = 'pronow_freeze_days';
  static const String _keyTargetMinutes = 'pronow_target_minutes';
  static const String _keyTargetSentences = 'pronow_target_sentences';
  static const String _legacyHistoryMapKey = 'pronow_history_map';
  static const String _legacyHistoryListKey = 'pronow_practice_history_list';

  static final ValueNotifier<int> currentStreakNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> longestStreakNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> freezeDaysNotifier = ValueNotifier<int>(2);
  static final ValueNotifier<int> targetMinutesNotifier = ValueNotifier<int>(
    15,
  );
  static final ValueNotifier<int> targetSentencesNotifier = ValueNotifier<int>(
    10,
  );
  static final ValueNotifier<double> todayMinutesNotifier =
      ValueNotifier<double>(0);
  static final ValueNotifier<int> todaySentencesNotifier = ValueNotifier<int>(
    0,
  );
  static final ValueNotifier<Map<String, int>> historyMapNotifier =
      ValueNotifier<Map<String, int>>({});
  static final ValueNotifier<List<DailyPracticeSummary>> dailySummaryNotifier =
      ValueNotifier<List<DailyPracticeSummary>>([]);

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      currentStreakNotifier.value = prefs.getInt(_keyCurrentStreak) ?? 0;
      longestStreakNotifier.value = prefs.getInt(_keyLongestStreak) ?? 0;
      freezeDaysNotifier.value = prefs.getInt(_keyFreezeDays) ?? 2;
      targetMinutesNotifier.value = prefs.getInt(_keyTargetMinutes) ?? 15;
      targetSentencesNotifier.value = prefs.getInt(_keyTargetSentences) ?? 10;
      todayMinutesNotifier.value = 0;
      todaySentencesNotifier.value = 0;

      await prefs.remove(_legacyHistoryMapKey);
      await prefs.remove(_legacyHistoryListKey);
      historyMapNotifier.value = {};
      await refreshDailyActivity();
    } catch (e) {
      debugPrint('Discipline state initialize failed: $e');
    }
  }

  static Future<void> refreshDailyActivity() async {
    var activityDates = Map<String, int>.from(historyMapNotifier.value);
    try {
      final summaries = await ApiService.getDailyActivity();
      dailySummaryNotifier.value = summaries;
      activityDates = {
        for (final summary in summaries)
          summary.practiceDate: summary.attemptsCount,
      };
      historyMapNotifier.value = activityDates;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final todayActivity = summaries.where(
        (summary) => summary.practiceDate == today,
      );
      final todaySummary = todayActivity.isEmpty ? null : todayActivity.first;
      todayMinutesNotifier.value = todaySummary?.minutesCompleted ?? 0;
      todaySentencesNotifier.value = todaySummary?.sentencesCompleted ?? 0;
    } catch (e) {
      debugPrint('Daily activity refresh failed: $e');
    }
    try {
      final streak = await ApiService.getStreakStatus();
      final lastActivityDate = streak['last_activity_date']?.toString();
      if (lastActivityDate != null && lastActivityDate.isNotEmpty) {
        activityDates.putIfAbsent(lastActivityDate, () => 1);
      }
      historyMapNotifier.value = activityDates;
      syncFromBackend(
        curStreak: streak['current_streak'] as int? ?? 0,
        longest: streak['longest_streak'] as int? ?? 0,
        freezes: streak['freeze_days_available'] as int? ?? 0,
      );
    } catch (e) {
      debugPrint('Streak refresh failed: $e');
    }
  }

  static Future<void> updateGoals({
    required int minutes,
    required int sentences,
  }) async {
    targetMinutesNotifier.value = minutes;
    targetSentencesNotifier.value = sentences;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTargetMinutes, minutes);
      await prefs.setInt(_keyTargetSentences, sentences);
    } catch (_) {}
  }

  static void syncFromBackend({
    required int curStreak,
    required int longest,
    required int freezes,
  }) {
    currentStreakNotifier.value = curStreak;
    longestStreakNotifier.value = longest;
    freezeDaysNotifier.value = freezes;
  }
}
