import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/notion_theme.dart';
import '../../core/discipline_state.dart';
import '../../core/notification_service.dart';
import '../../core/api_service.dart';

class DisciplineDashboardScreen extends StatefulWidget {
  final Function(String sentence, String ipa)? onRePracticeSentence;

  const DisciplineDashboardScreen({super.key, this.onRePracticeSentence});

  @override
  State<DisciplineDashboardScreen> createState() =>
      _DisciplineDashboardScreenState();
}

class _DisciplineDashboardScreenState extends State<DisciplineDashboardScreen> {
  bool _isReminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  List<LessonProgressItem> _lessonProgressList = [];
  List<SavedSentenceItem> _savedSentences = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadHistoryData();
    DisciplineState.refreshDailyActivity();
  }

  Future<void> _loadHistoryData() async {
    try {
      final lessons = await ApiService.getLessonProgress();
      final saved = await ApiService.getSavedCustomSentences();
      if (mounted) {
        setState(() {
          _lessonProgressList = lessons;
          _savedSentences = saved;
        });
      }
    } catch (e) {
      debugPrint('Dashboard history load failed: $e');
    }
  }

  Future<void> _deleteSavedSentence(int id) async {
    final ok = await ApiService.deleteSavedCustomSentence(id);
    if (ok) {
      _loadHistoryData();
    }
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationService.loadReminderSettings();
    setState(() {
      _isReminderEnabled = settings['enabled'];
      _reminderTime = TimeOfDay(
        hour: settings['hour'],
        minute: settings['minute'],
      );
    });
  }

  Future<void> _onToggleReminder(bool val) async {
    if (val) {
      await NotificationService.requestNotificationPermission();
    }
    setState(() => _isReminderEnabled = val);
    await NotificationService.saveReminderSettings(
      enabled: val,
      hour: _reminderTime.hour,
      minute: _reminderTime.minute,
    );
  }

  void _showEditGoalsDialog() {
    int tempMinutes = DisciplineState.targetMinutesNotifier.value;
    int tempSentences = DisciplineState.targetSentencesNotifier.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NotionColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đặt Mục Tiêu Hàng Ngày',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: NotionColors.textMuted,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Duy trì thời gian và số câu luyện tập mỗi ngày để hình thành phản xạ phát âm.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thời gian học mỗi ngày:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: NotionColors.textMain,
                        ),
                      ),
                      Text(
                        '$tempMinutes phút',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: NotionColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: tempMinutes.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    activeColor: NotionColors.textMain,
                    inactiveColor: NotionColors.border,
                    onChanged: (v) {
                      setModalState(() => tempMinutes = v.toInt());
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Số câu phát âm mỗi ngày:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: NotionColors.textMain,
                        ),
                      ),
                      Text(
                        '$tempSentences câu',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: NotionColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: tempSentences.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    activeColor: NotionColors.textMain,
                    inactiveColor: NotionColors.border,
                    onChanged: (v) {
                      setModalState(() => tempSentences = v.toInt());
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NotionColors.textMain,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        await DisciplineState.updateGoals(
                          minutes: tempMinutes,
                          sentences: tempSentences,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã cập nhật mục tiêu hàng ngày.'),
                          ),
                        );
                      },
                      child: Text(
                        'Lưu Mục Tiêu',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NotionColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: NotionColors.border),
                        ),
                        child: const Text('🔥', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kỷ Luật & Thói Quen',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Theo dõi chuỗi ngày, mục tiêu và lịch sử luyện tập',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Streak Card
                  ValueListenableBuilder<int>(
                    valueListenable: DisciplineState.currentStreakNotifier,
                    builder: (context, currentStreak, _) {
                      return ValueListenableBuilder<int>(
                        valueListenable: DisciplineState.longestStreakNotifier,
                        builder: (context, longestStreak, _) {
                          return ValueListenableBuilder<int>(
                            valueListenable: DisciplineState.freezeDaysNotifier,
                            builder: (context, freezeDays, _) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: NotionColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: NotionColors.border,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'CHUỖI NGÀY LIÊN TIẾP',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: NotionColors.textMuted,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: NotionColors.tagAmberBg,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Kỷ lục: $longestStreak ngày',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: NotionColors.tagAmberText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          '$currentStreak',
                                          style: GoogleFonts.inter(
                                            fontSize: 44,
                                            fontWeight: FontWeight.w800,
                                            color: NotionColors.textMain,
                                            letterSpacing: -1.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ngày liên tục',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: NotionColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: NotionColors.tagGreyBg,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                '🛡️',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '$freezeDays Lượt đóng băng (Streak Freeze)',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: NotionColors.textMain,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Mỗi 7 ngày liên tiếp bạn được tặng +1 lượt đóng băng (tối đa 2). Tự động bảo vệ chuỗi nếu quên học 1 ngày.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: NotionColors.textMuted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3. One-Month Calendar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: NotionColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NotionColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LỊCH RÈN LUYỆN THÁNG ${DateTime.now().month}/${DateTime.now().year}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: NotionColors.textMuted,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: NotionColors.textMain,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Đã học',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: NotionColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(
                                      color: NotionColors.border,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Chưa học',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: NotionColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<Map<String, int>>(
                          valueListenable: DisciplineState.historyMapNotifier,
                          builder: (context, historyMap, _) {
                            return _buildMonthCalendar(historyMap);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Daily Goals
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: NotionColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NotionColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'MỤC TIÊU HÔM NAY',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: NotionColors.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _showEditGoalsDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: NotionColors.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: NotionColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.edit_outlined,
                                        size: 13,
                                        color: NotionColors.textMain,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Chỉnh sửa',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: NotionColors.textMain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<double>(
                          valueListenable: DisciplineState.todayMinutesNotifier,
                          builder: (context, todayMin, _) {
                            return ValueListenableBuilder<int>(
                              valueListenable:
                                  DisciplineState.targetMinutesNotifier,
                              builder: (context, targetMin, _) {
                                return _buildProgressRow(
                                  title: 'Thời gian luyện nói',
                                  current: todayMin,
                                  target: targetMin,
                                  unit: 'phút',
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        ValueListenableBuilder<int>(
                          valueListenable:
                              DisciplineState.todaySentencesNotifier,
                          builder: (context, todaySent, _) {
                            return ValueListenableBuilder<int>(
                              valueListenable:
                                  DisciplineState.targetSentencesNotifier,
                              builder: (context, targetSent, _) {
                                return _buildProgressRow(
                                  title: 'Số câu phát âm chuẩn',
                                  current: todaySent,
                                  target: targetSent,
                                  unit: 'câu',
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cập nhật sau mỗi lượt có giọng nói: thời gian lấy từ độ dài thu âm; câu chỉ tính khi đạt từ 80 điểm.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: NotionColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ValueListenableBuilder<List<DailyPracticeSummary>>(
                    valueListenable: DisciplineState.dailySummaryNotifier,
                    builder: (context, summaries, _) =>
                        _buildProgressChart(summaries),
                  ),
                  const SizedBox(height: 20),

                  // 5. Notifications
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: NotionColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NotionColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '🔔',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Nhắc nhở học hàng ngày',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: NotionColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isReminderEnabled,
                              activeThumbColor: NotionColors.textMain,
                              onChanged: _onToggleReminder,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hệ thống tự động so khớp đồng hồ thiết bị để gửi thông báo khi đến giờ.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_isReminderEnabled) ...[
                          const SizedBox(height: 12),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: _reminderTime,
                                );
                                if (picked != null) {
                                  setState(() => _reminderTime = picked);
                                  await NotificationService.saveReminderSettings(
                                    enabled: true,
                                    hour: picked.hour,
                                    minute: picked.minute,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: NotionColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: NotionColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                      color: NotionColors.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Giờ nhắc: ${_reminderTime.format(context)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: NotionColors.textMain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. TIẾN ĐỘ BÀI HỌC ĐÃ LUYỆN
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: NotionColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NotionColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '📚',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tiến độ bài học đã luyện',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: NotionColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_lessonProgressList.where((p) => p.isPassed).length} câu đạt',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: NotionColors.tagGreenText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_lessonProgressList.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Bạn chưa luyện câu nào trong Lộ trình bài học.\nHãy vào tab "Bài Học" và hoàn thành các câu đạt ≥ 80 điểm!',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: NotionColors.textMuted,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          ..._lessonProgressList.map((item) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: NotionColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: item.isPassed
                                      ? NotionColors.tagGreenText.withAlpha(80)
                                      : NotionColors.borderSubtle,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.isPassed
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 16,
                                    color: item.isPassed
                                        ? NotionColors.tagGreenText
                                        : NotionColors.tagAmberText,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.sentenceText,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: NotionColors.textMain,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Bài ${item.lessonId} • Điểm cao nhất: ${item.bestScore.toStringAsFixed(0)}/100 (${item.attemptsCount} lần thử)',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: NotionColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.isPassed
                                          ? NotionColors.tagGreenBg
                                          : NotionColors.tagAmberBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.isPassed ? 'Đạt' : 'Chưa đạt',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: item.isPassed
                                            ? NotionColors.tagGreenText
                                            : NotionColors.tagAmberText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. SỔ TAY CÂU TỰ DO ĐÃ LƯU
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: NotionColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NotionColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('⭐', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(
                                  'Sổ tay câu tự do đã lưu',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: NotionColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_savedSentences.length} câu',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: NotionColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Những câu tiếng Anh bạn tự nhập và bấm "Lưu câu này" trong màn hình Luyện phát âm.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        if (_savedSentences.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Chưa có câu nào trong sổ tay.\nKhi luyện câu tự do, hãy bấm "⭐ Lưu câu này" để lưu vào đây và luyện lại sau!',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: NotionColors.textMuted,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          ..._savedSentences.map((saved) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: NotionColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: NotionColors.borderSubtle,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          saved.sentenceText,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: NotionColors.textMain,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          saved.ipa,
                                          style: GoogleFonts.robotoMono(
                                            fontSize: 11,
                                            color: NotionColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Re-practice button
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (widget.onRePracticeSentence !=
                                            null) {
                                          widget.onRePracticeSentence!(
                                            saved.sentenceText,
                                            saved.ipa,
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: NotionColors.textMain,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Luyện lại',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: NotionColors.textMuted,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        _deleteSavedSentence(saved.id),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressChart(List<DailyPracticeSummary> summaries) {
    final today = DateTime.now();
    final dates = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day - 6 + index),
    );
    final summariesByDate = {
      for (final summary in summaries) summary.practiceDate: summary,
    };
    final scores = dates.map((date) {
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      return summariesByDate[key]?.averageScore;
    }).toList();
    final activeDays = scores.whereType<double>().length;
    final sevenDaySummaries = dates
        .map((date) {
          final key =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          return summariesByDate[key];
        })
        .whereType<DailyPracticeSummary>()
        .toList();
    final totalAttempts = sevenDaySummaries.fold<int>(
      0,
      (total, summary) => total + summary.attemptsCount,
    );
    final averageScore = totalAttempts == 0
        ? 0.0
        : sevenDaySummaries.fold<double>(
                0,
                (total, summary) =>
                    total + summary.averageScore * summary.attemptsCount,
              ) /
              totalAttempts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NotionColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NotionColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                size: 18,
                color: NotionColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'TIẾN BỘ 7 NGÀY',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: NotionColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            activeDays == 0
                ? 'Chưa có lượt chấm nào trong 7 ngày gần đây.'
                : '$activeDays ngày luyện · điểm trung bình ${averageScore.toStringAsFixed(0)}/100',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: NotionColors.textMain,
            ),
          ),
          if (activeDays > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 170,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeeklyScorePainter(
                  scores: scores,
                  labels: dates
                      .map((date) => '${date.day}/${date.month}')
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(Map<String, int> historyMap) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayWeekday = DateTime(now.year, now.month, 1).weekday;
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekdays.map((w) {
            return Expanded(
              child: Center(
                child: Text(
                  w,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: NotionColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
          ),
          itemCount: (firstDayWeekday - 1) + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstDayWeekday - 1) {
              return const SizedBox.shrink();
            }

            int dayNum = index - (firstDayWeekday - 1) + 1;
            String dayKey =
                "${now.year}-${now.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}";
            bool isPracticed = (historyMap[dayKey] ?? 0) > 0;
            bool isToday = dayNum == now.day;

            return Container(
              decoration: BoxDecoration(
                color: isPracticed ? NotionColors.textMain : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isToday
                      ? NotionColors.tagAmberText
                      : (isPracticed
                            ? NotionColors.textMain
                            : NotionColors.border),
                  width: isToday ? 1.8 : 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  '$dayNum',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isToday || isPracticed
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isPracticed
                        ? Colors.white
                        : (isToday
                              ? NotionColors.tagAmberText
                              : NotionColors.textMain),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressRow({
    required String title,
    required num current,
    required num target,
    required String unit,
  }) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final currentText = unit == 'phút'
        ? current.toStringAsFixed(1)
        : current.toInt().toString();
    final targetText = unit == 'phút'
        ? target.toStringAsFixed(0)
        : target.toInt().toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: NotionColors.textMain,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$currentText / $targetText $unit',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NotionColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: NotionColors.surfaceSubtle,
            color: NotionColors.textMain,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _WeeklyScorePainter extends CustomPainter {
  final List<double?> scores;
  final List<String> labels;

  _WeeklyScorePainter({required this.scores, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 40 || size.height <= 40 || scores.isEmpty) return;

    const left = 30.0;
    const right = 8.0;
    const top = 10.0;
    const bottom = 25.0;
    final plotWidth = size.width - left - right;
    final plotHeight = size.height - top - bottom;
    final gridPaint = Paint()
      ..color = NotionColors.borderSubtle
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = NotionColors.tagBlueText
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final pointPaint = Paint()..color = NotionColors.tagBlueText;

    for (final level in [0, 50, 100]) {
      final y = top + plotHeight * (1 - level / 100);
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      _paintText(
        canvas,
        '$level',
        Offset(0, y - 6),
        const TextStyle(fontSize: 9, color: NotionColors.textMuted),
        width: left - 5,
      );
    }

    Offset pointAt(int index, double score) {
      final x = left + plotWidth * index / (scores.length - 1);
      final y = top + plotHeight * (1 - score.clamp(0, 100) / 100);
      return Offset(x, y);
    }

    for (var index = 0; index < scores.length; index++) {
      final score = scores[index];
      if (score == null) continue;
      final point = pointAt(index, score);
      if (index > 0 && scores[index - 1] != null) {
        canvas.drawLine(
          pointAt(index - 1, scores[index - 1]!),
          point,
          linePaint,
        );
      }
      canvas.drawCircle(point, 4, pointPaint);
      _paintText(
        canvas,
        labels[index],
        Offset(point.dx - 18, size.height - bottom + 7),
        const TextStyle(fontSize: 8, color: NotionColors.textMuted),
        width: 36,
      );
    }

    for (var index = 0; index < scores.length; index++) {
      if (scores[index] != null) continue;
      final x = left + plotWidth * index / (scores.length - 1);
      _paintText(
        canvas,
        labels[index],
        Offset(x - 18, size.height - bottom + 7),
        const TextStyle(fontSize: 8, color: NotionColors.textMuted),
        width: 36,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double width,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeeklyScorePainter oldDelegate) => true;
}
