import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pronow_mobile/core/notion_theme.dart';
import 'package:pronow_mobile/features/curriculum/curriculum_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final screenSize in [const Size(320, 720), const Size(1024, 800)]) {
    testWidgets(
      'curriculum progress and practice controls fit ${screenSize.width}px',
      (WidgetTester tester) async {
        tester.view.physicalSize = screenSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({
          'lesson_progress_cache': jsonEncode({'1_1': 79.0}),
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: NotionTheme.lightTheme,
            home: const CurriculumScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Đang học'), findsOneWidget);
        expect(find.text('Đã hoàn thành'), findsNothing);
        expect(find.text('0/4 câu đạt'), findsWidgets);

        await tester.tap(find.text('Âm Răng Xát Vô Thanh /θ/'));
        await tester.pumpAndSettle();

        expect(find.text('Câu luyện tập'), findsOneWidget);
        expect(
          find.text('Đạt ≥ 80/100 để hoàn thành từng câu.'),
          findsOneWidget,
        );
        expect(
          find.text('Cần luyện · cao nhất 79/100 (cần ≥ 80)'),
          findsOneWidget,
        );
        expect(find.text('Luyện Tiếp'), findsOneWidget);
        expect(find.text('Đã hoàn thành'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
