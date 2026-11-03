import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pronow_mobile/core/notion_theme.dart';
import 'package:pronow_mobile/features/discipline/discipline_dashboard_screen.dart';

void main() {
  testWidgets('DisciplineDashboardScreen renders all sections and empty states',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NotionTheme.lightTheme,
        home: const DisciplineDashboardScreen(),
      ),
    );
    await tester.pump();

    // Verify main header
    expect(find.text('Kỷ Luật & Thói Quen'), findsOneWidget);

    // Verify streak card
    expect(find.text('CHUỖI NGÀY LIÊN TIẾP'), findsOneWidget);

    // Verify month calendar
    expect(find.textContaining('LỊCH RÈN LUYỆN THÁNG'), findsOneWidget);

    // Verify daily goals
    expect(find.text('MỤC TIÊU HÔM NAY'), findsOneWidget);
    expect(find.text('Thời gian luyện nói'), findsOneWidget);
    expect(find.text('Số câu phát âm chuẩn'), findsOneWidget);

    // Verify weekly progress chart section
    expect(find.text('TIẾN BỘ 7 NGÀY'), findsOneWidget);
    expect(find.text('Chưa có dữ liệu điểm 7 ngày qua'), findsOneWidget);

    // Verify reminders section
    expect(find.text('Nhắc nhở học hàng ngày'), findsOneWidget);

    // Verify lesson progress & empty state
    expect(find.text('Tiến độ bài học đã luyện'), findsOneWidget);
    expect(
      find.text('Chưa có câu nào trong Lộ trình bài học'),
      findsOneWidget,
    );

    // Verify saved sentences notebook & empty state
    expect(find.text('Sổ tay câu tự do đã lưu'), findsOneWidget);
    expect(find.text('Sổ tay câu tự do đang trống'), findsOneWidget);
  });

  testWidgets('DisciplineDashboardScreen renders cleanly on narrow screen (320px)',
      (WidgetTester tester) async {
    // Narrow phone screen (320x640)
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: NotionTheme.lightTheme,
        home: const DisciplineDashboardScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Kỷ Luật & Thói Quen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
