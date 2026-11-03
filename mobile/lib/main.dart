import 'package:flutter/material.dart';

import 'core/notion_theme.dart';
import 'core/discipline_state.dart';
import 'core/notification_service.dart';
import 'features/practice/pronunciation_screen.dart';
import 'features/discipline/discipline_dashboard_screen.dart';
import 'features/curriculum/curriculum_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DisciplineState.initialize();
  NotificationService.initializeTimer();
  runApp(const ProNowApp());
}

class ProNowApp extends StatelessWidget {
  const ProNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProNow',
      debugShowCheckedModeBanner: false,
      theme: NotionTheme.lightTheme,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _selectedLessonId;
  String _activeSentence = "I think that this is the best path.";
  String _activeIpa = "/aɪ θɪŋk ðæt ðɪs ɪz ðə bɛst pæθ/";

  void _onSentenceSelected(String sentence, String ipa) {
    setState(() {
      _activeSentence = sentence;
      _activeIpa = ipa;
      _currentIndex = 0; // Switch to Practice tab
    });
  }

  void _openLessonForPhoneme(String phoneme) {
    final lessonId = curriculumLessonIdForPhoneme(phoneme);
    if (lessonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có bài học riêng cho âm này.')),
      );
      return;
    }
    setState(() {
      _selectedLessonId = lessonId;
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      PronunciationPracticeScreen(
        initialSentence: _activeSentence,
        initialIpa: _activeIpa,
        onOpenLessonForPhoneme: _openLessonForPhoneme,
      ),
      DisciplineDashboardScreen(onRePracticeSentence: _onSentenceSelected),
      CurriculumScreen(
        onSelectSentence: _onSentenceSelected,
        initialLessonId: _selectedLessonId,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: NotionColors.background,
          border: Border(
            top: BorderSide(color: NotionColors.border, width: 1.0),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: NotionColors.background,
          indicatorColor: NotionColors.surfaceSubtle,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(
                Icons.mic_none_outlined,
                color: NotionColors.textMuted,
              ),
              selectedIcon: Icon(Icons.mic, color: NotionColors.textMain),
              label: 'Luyện Nói',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.local_fire_department_outlined,
                color: NotionColors.textMuted,
              ),
              selectedIcon: Icon(
                Icons.local_fire_department,
                color: NotionColors.textMain,
              ),
              label: 'Kỷ Luật',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.auto_stories_outlined,
                color: NotionColors.textMuted,
              ),
              selectedIcon: Icon(
                Icons.auto_stories,
                color: NotionColors.textMain,
              ),
              label: 'Bài Học',
            ),
          ],
        ),
      ),
    );
  }
}
