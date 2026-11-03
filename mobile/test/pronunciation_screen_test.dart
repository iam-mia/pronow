import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pronow_mobile/core/notion_theme.dart';
import 'package:pronow_mobile/features/practice/pronunciation_screen.dart';

void main() {
  Widget buildTestableWidget({
    String sentence = "I think that this is the best path.",
    String ipa = "/aɪ θɪŋk ðæt ðɪs ɪz ðə bɛst pæθ/",
    ValueChanged<String>? onOpenLesson,
  }) {
    return MaterialApp(
      theme: NotionTheme.lightTheme,
      home: Scaffold(
        body: PronunciationPracticeScreen(
          initialSentence: sentence,
          initialIpa: ipa,
          onOpenLessonForPhoneme: onOpenLesson,
        ),
      ),
    );
  }

  testWidgets('renders pronunciation practice screen elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());

    expect(find.text('Luyện Phát Âm Tự Do'), findsOneWidget);
    expect(find.text('Acoustic Wave AI'), findsOneWidget);
    expect(find.text('CÂU MỤC TIÊU'), findsOneWidget);
    expect(find.text('I think that this is the best path.'), findsWidgets);
    expect(find.text('/aɪ θɪŋk ðæt ðɪs ɪz ðə bɛst pæθ/'), findsOneWidget);
    expect(find.text('Nghe mẫu'), findsOneWidget);
    expect(find.text('Lưu câu này'), findsOneWidget);
    expect(find.text('Chạm micro để luyện nói'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });

  testWidgets('selecting suggested sentence updates input and display',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());

    final suggestedChip = find.text('She works hard and loves cold drinks.');
    expect(suggestedChip, findsOneWidget);

    await tester.tap(suggestedChip);
    await tester.pump();

    final inputField = find.byType(TextField);
    expect(inputField, findsOneWidget);
    expect(find.text('She works hard and loves cold drinks.'), findsWidgets);
  });

  testWidgets('renders cleanly on narrow mobile screen without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Chạm micro để luyện nói'), findsOneWidget);
  });

  testWidgets('renders cleanly on wide desktop screen without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Luyện Phát Âm Tự Do'), findsOneWidget);
  });
}
