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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Đặt Mục Tiêu Hàng Ngày',
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 360;
    final horizontalPadding = isNarrow ? 12.0 : 16.0;
    final cardPadding = isNarrow ? 14.0 : 20.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header (Responsive)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
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
                                padding: EdgeInsets.all(cardPadding),
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
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 6,
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
                                        Flexible(
                                          child: Text(
                                            'ngày liên tục',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: NotionColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: NotionColors.tagGreyBg,
                                        borderRadius: BorderRadius.circular(6),
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
                                            '$freezeDays lượt đóng băng',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: NotionColors.textMain,
                                            ),
                                          ),
                                        ],
                                      ),
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
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      color: NotionColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NotionColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
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
                              mainAxisSize: MainAxisSize.min,
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
                    padding: EdgeInsets.all(cardPadding),
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
                            Expanded(
                              child: Text(
                                'MỤC TIÊU HÔM NAY',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: NotionColors.textMuted,
                                  letterSpacing: 0.8,
                                ),
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
                        const SizedBox(height: 10),
                        Text(
                          'Cập nhật sau mỗi lượt có giọng nói: thời gian lấy từ độ dài thu âm; câu chỉ tính khi đạt từ 80 điểm.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: NotionColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Weekly Score Chart
                  ValueListenableBuilder<List<DailyPracticeSummary>>(
                    valueListenable: DisciplineState.dailySummaryNotifier,
                    builder: (context, summaries, _) =>
                        _buildProgressChart(summaries),
                  ),
                  const SizedBox(height: 20),

                  // 6. Notifications
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(cardPadding),
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
                            Expanded(
                              child: Row(
                                children: [
                                  const Text(
                                    '🔔',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Nhắc nhở học hàng ngày',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: NotionColors.textMain,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                  horizontal: 10,
                                  vertical: 6,
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
                                      size: 15,
                                      color: NotionColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Giờ nhắc: ${_reminderTime.format(context)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: NotionColors.textMain,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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

                  // 7. TIẾN ĐỘ BÀI HỌC ĐÃ LUYỆN
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(cardPadding),
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
                            Expanded(
                              child: Row(
                                children: [
                                  const Text(
                                    '📚',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tiến độ bài học đã luyện',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: NotionColors.textMain,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
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
                        const SizedBox(height: 14),
                        if (_lessonProgressList.isEmpty)
                          _buildEmptyStateWidget(
                            icon: Icons.menu_book_outlined,
                            title: 'Chưa có câu nào trong Lộ trình bài học',
                            description:
                                'Vào tab "Bài Học", chọn bất kỳ câu mẫu nào và hoàn thành với điểm số ≥ 80 để ghi nhận tiến độ tại đây.',
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      item.isPassed
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      size: 16,
                                      color: item.isPassed
                                          ? NotionColors.tagGreenText
                                          : NotionColors.tagAmberText,
                                    ),
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
                                        const SizedBox(height: 3),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 2,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              'Bài ${item.lessonId}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: NotionColors.textMuted,
                                              ),
                                            ),
                                            Text(
                                              '•',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: NotionColors.textTertiary,
                                              ),
                                            ),
                                            Text(
                                              'Điểm: ${item.bestScore.toStringAsFixed(0)}/100',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: item.isPassed
                                                    ? NotionColors.tagGreenText
                                                    : NotionColors.tagAmberText,
                                              ),
                                            ),
                                            Text(
                                              '•',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: NotionColors.textTertiary,
                                              ),
                                            ),
                                            Text(
                                              '${item.attemptsCount} lần thử',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: NotionColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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

                  // 8. SỔ TAY CÂU TỰ DO ĐÃ LƯU
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(cardPadding),
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
                            Expanded(
                              child: Row(
                                children: [
                                  const Text(
                                    '⭐',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Sổ tay câu tự do đã lưu',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: NotionColors.textMain,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
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
                        const SizedBox(height: 6),
                        Text(
                          'Những câu tiếng Anh bạn tự nhập và bấm "Lưu câu này" trong màn hình Luyện phát âm.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        if (_savedSentences.isEmpty)
                          _buildEmptyStateWidget(
                            icon: Icons.bookmark_border_rounded,
                            title: 'Sổ tay câu tự do đang trống',
                            description:
                                'Khi luyện bất kỳ câu tự do nào tại tab "Luyện Nói", hãy bấm "⭐ Lưu câu này" để lưu vào sổ tay và luyện lại sau.',
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          saved.sentenceText,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: NotionColors.textMain,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
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
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: NotionColors.textMuted,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Xóa câu',
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

  Widget _buildEmptyStateWidget({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: NotionColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NotionColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: NotionColors.textTertiary),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: NotionColors.textMain,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: NotionColors.textMuted,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

    final isNarrow = MediaQuery.of(context).size.width < 360;
    final cardPadding = isNarrow ? 14.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
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
              if (activeDays > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: NotionColors.tagBlueBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'TB: ${averageScore.toStringAsFixed(0)}/100',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: NotionColors.tagBlueText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            activeDays == 0
                ? 'Theo dõi điểm phát âm trung bình qua từng ngày.'
                : '$activeDays/7 ngày đã luyện tập • $totalAttempts lượt chấm',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: NotionColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          if (activeDays == 0)
            _buildEmptyStateWidget(
              icon: Icons.auto_graph_rounded,
              title: 'Chưa có dữ liệu điểm 7 ngày qua',
              description:
                  'Sau khi hoàn thành lượt chấm phát âm đầu tiên, biểu đồ xu hướng điểm số và mức độ tiến bộ hàng ngày sẽ xuất hiện tại đây.',
            )
          else
            SizedBox(
              height: 180,
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
      ),
    );
  }

  Widget _buildMonthCalendar(Map<String, int> historyMap) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayWeekday = DateTime(now.year, now.month, 1).weekday;
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    final monthPrefix =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-";
    final completedDaysThisMonth = historyMap.entries.where((entry) {
      return entry.key.startsWith(monthPrefix) && entry.value > 0;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
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
            bool isFuture = dayNum > now.day;

            return Container(
              decoration: BoxDecoration(
                color: isPracticed
                    ? NotionColors.textMain
                    : (isFuture
                          ? NotionColors.surfaceSubtle.withAlpha(120)
                          : Colors.white),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isToday
                      ? NotionColors.tagAmberText
                      : (isPracticed
                            ? NotionColors.textMain
                            : NotionColors.border),
                  width: isToday ? 2.0 : 1.0,
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
                              : (isFuture
                                    ? NotionColors.textTertiary
                                    : NotionColors.textMain)),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Đã hoàn thành $completedDaysThisMonth / $daysInMonth ngày trong tháng này.',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: NotionColors.textMuted,
          ),
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
    final isCompleted = target > 0 && current >= target;
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
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: NotionColors.textMain,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCompleted) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: NotionColors.tagGreenBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Đạt ✓',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: NotionColors.tagGreenText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$currentText / $targetText $unit',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCompleted
                    ? NotionColors.tagGreenText
                    : NotionColors.textMuted,
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
            color: isCompleted
                ? NotionColors.tagGreenText
                : NotionColors.textMain,
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

    const left = 32.0;
    const right = 12.0;
    const top = 22.0;
    const bottom = 24.0;
    final plotWidth = size.width - left - right;
    final plotHeight = size.height - top - bottom;

    final gridPaint = Paint()
      ..color = NotionColors.borderSubtle
      ..strokeWidth = 1;

    final guideLinePaint = Paint()
      ..color = NotionColors.borderSubtle
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = NotionColors.tagBlueText
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = NotionColors.tagBlueText
      ..style = PaintingStyle.fill;

    final pointInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw horizontal grid lines at 0, 50, 100
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
        const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: NotionColors.textTertiary,
        ),
        width: left - 6,
      );
    }

    Offset pointAt(int index, double score) {
      final x = left + plotWidth * index / (scores.length - 1);
      final y = top + plotHeight * (1 - score.clamp(0, 100) / 100);
      return Offset(x, y);
    }

    // Connect active days
    int? prevActiveIndex;
    for (var index = 0; index < scores.length; index++) {
      final score = scores[index];
      if (score != null) {
        final currentPoint = pointAt(index, score);
        if (prevActiveIndex != null) {
          final prevPoint = pointAt(prevActiveIndex, scores[prevActiveIndex]!);
          canvas.drawLine(prevPoint, currentPoint, linePaint);
        }
        prevActiveIndex = index;
      }
    }

    // Draw points and values
    for (var index = 0; index < scores.length; index++) {
      final score = scores[index];
      final x = left + plotWidth * index / (scores.length - 1);

      // Draw subtle vertical guide line down to x axis
      canvas.drawLine(
        Offset(x, top),
        Offset(x, size.height - bottom),
        guideLinePaint,
      );

      if (score != null) {
        final point = pointAt(index, score);

        // Draw score text above the dot
        final scoreText = score.toStringAsFixed(0);
        _paintText(
          canvas,
          scoreText,
          Offset(point.dx - 16, point.dy - 17),
          const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: NotionColors.tagBlueText,
          ),
          width: 32,
        );

        // Outer dot & inner white dot
        canvas.drawCircle(point, 5, pointPaint);
        canvas.drawCircle(point, 2.2, pointInnerPaint);
      }

      // Draw bottom label (date)
      _paintText(
        canvas,
        labels[index],
        Offset(x - 20, size.height - bottom + 6),
        TextStyle(
          fontSize: 9,
          fontWeight: score != null ? FontWeight.w600 : FontWeight.w400,
          color: score != null
              ? NotionColors.textMain
              : NotionColors.textTertiary,
        ),
        width: 40,
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
