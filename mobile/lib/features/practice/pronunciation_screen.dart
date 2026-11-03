import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../core/notion_theme.dart';
import '../../core/api_service.dart';
import '../../core/discipline_state.dart';

class PronunciationPracticeScreen extends StatefulWidget {
  final String initialSentence;
  final String initialIpa;
  final ValueChanged<String>? onOpenLessonForPhoneme;

  const PronunciationPracticeScreen({
    super.key,
    this.initialSentence = "I think that this is the best path.",
    this.initialIpa = "/aɪ θɪŋk ðæt ðɪs ɪz ðə bɛst pæθ/",
    this.onOpenLessonForPhoneme,
  });

  @override
  State<PronunciationPracticeScreen> createState() =>
      _PronunciationPracticeScreenState();
}

class _PronunciationPracticeScreenState
    extends State<PronunciationPracticeScreen> {
  late final TextEditingController _inputController;
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;

  late String _referenceText;
  late String _ipaTranscription;

  bool _isGeneratingIpa = false;
  bool _isPlayingTts = false;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _isSavedToNotebook = false;
  bool _isSavingSentence = false;

  String? _statusMessage;
  AssessmentResultModel? _result;
  PhonemeScoreModel? _selectedPhoneme;

  final List<String> _suggestedSentences = [
    "I think that this is the best path.",
    "She works hard and loves cold drinks.",
    "Thank you for thirty thoughtful gifts.",
    "Do not slip while the sheep sleep on the ship.",
    "They love their father and mother.",
  ];

  @override
  void initState() {
    super.initState();
    _referenceText = widget.initialSentence;
    _ipaTranscription = widget.initialIpa;
    _inputController = TextEditingController(text: _referenceText);
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingTts = false);
    });
  }

  @override
  void didUpdateWidget(covariant PronunciationPracticeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSentence != oldWidget.initialSentence) {
      setState(() {
        _referenceText = widget.initialSentence;
        _ipaTranscription = widget.initialIpa;
        _inputController.text = widget.initialSentence;
        _result = null;
        _selectedPhoneme = null;
        _isSavedToNotebook = false;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _generateIpaAndStartPractice() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isGeneratingIpa = true);
    final ipa = await ApiService.transcribeSentence(text);

    if (mounted) {
      setState(() {
        _referenceText = text;
        _ipaTranscription = ipa;
        _isGeneratingIpa = false;
        _result = null;
        _selectedPhoneme = null;
        _statusMessage = null;
        _isSavedToNotebook = false;
      });
    }
  }

  Future<void> _playTts() async {
    if (_referenceText.trim().isEmpty) return;
    try {
      setState(() => _isPlayingTts = true);
      final ttsUrl = ApiService.getTtsUrl(_referenceText);
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(ttsUrl));
    } catch (e) {
      debugPrint('TTS Error: $e');
      if (mounted) setState(() => _isPlayingTts = false);
    }
  }

  Future<void> _saveToNotebook() async {
    if (_isSavedToNotebook || _isSavingSentence) return;
    setState(() => _isSavingSentence = true);
    final ok = await ApiService.saveCustomSentence(
      sentenceText: _referenceText,
      ipa: _ipaTranscription,
    );
    if (mounted) {
      setState(() {
        _isSavingSentence = false;
        if (ok) _isSavedToNotebook = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Đã lưu câu vào sổ tay luyện tập!'
                : 'Không thể lưu câu, vui lòng thử lại.',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isAnalyzing = true;
        _statusMessage = "Đang phân tích âm học và so khớp âm vị...";
      });

      Uint8List? audioBytes;
      try {
        final path = await _audioRecorder.stop();
        if (path != null && path.isNotEmpty) {
          if (kIsWeb || path.startsWith('blob:') || path.startsWith('http')) {
            final res = await http.get(Uri.parse(path));
            audioBytes = res.bodyBytes;
          } else {
            final file = await http
                .get(Uri.parse(path))
                .timeout(const Duration(seconds: 2))
                .catchError((_) => http.Response('', 404));
            if (file.statusCode == 200) {
              audioBytes = file.bodyBytes;
            }
          }
        }
      } catch (e) {
        debugPrint('Error retrieving audio bytes: $e');
      }

      if (audioBytes == null || audioBytes.length < 400) {
        setState(() {
          _isAnalyzing = false;
          _statusMessage = "Không nhận được tín hiệu âm thanh từ micro. Vui lòng nói to hơn.";
        });
        return;
      }

      try {
        final assessment = await ApiService.assessPronunciation(
          referenceText: _referenceText,
          audioBytes: audioBytes,
        );

        if (mounted) {
          setState(() {
            _result = assessment;
            _isAnalyzing = false;
            _statusMessage = null;
          });

          // Sync streak status if returned
          if (assessment.streakInfo != null) {
            final curStreak = assessment.streakInfo!['current_streak'] ?? 0;
            final longest = assessment.streakInfo!['longest_streak'] ?? 0;
            final freezes =
                assessment.streakInfo!['freeze_days_available'] ?? 0;
            DisciplineState.syncFromBackend(
              curStreak: curStreak,
              longest: longest,
              freezes: freezes,
            );
          }
          await DisciplineState.refreshDailyActivity();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _statusMessage = "Lỗi khi chấm điểm phát âm: $e";
          });
        }
      }
    } else {
      // Start Recording
      try {
        final hasPermission = await _audioRecorder.hasPermission();
        if (!hasPermission) {
          setState(() {
            _statusMessage = "Vui lòng cấp quyền micro trong trình duyệt/thiết bị để luyện nói.";
          });
          return;
        }

        const config = RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        );

        await _audioRecorder.start(config, path: '');
        setState(() {
          _isRecording = true;
          _statusMessage = "Đang thu âm... Hãy đọc to và rõ câu mẫu.";
          _result = null;
          _selectedPhoneme = null;
        });
      } catch (e) {
        setState(() {
          _statusMessage = "Không thể bật micro: $e";
        });
      }
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80.0) return NotionColors.tagGreenText;
    if (score >= 50.0) return NotionColors.tagAmberText;
    return NotionColors.tagRedText;
  }

  Color _getScoreBgColor(double score) {
    if (score >= 80.0) return NotionColors.tagGreenBg;
    if (score >= 50.0) return NotionColors.tagAmberBg;
    return NotionColors.tagRedBg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NotionColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Compact Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🎙️', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            'Luyện Phát Âm Tự Do',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: NotionColors.textMain,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: NotionColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: NotionColors.border),
                        ),
                        child: Text(
                          'Acoustic Wave AI',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: NotionColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Compact Input Bar & Chips
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NotionColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NotionColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _inputController,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: NotionColors.textMain,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Nhập câu tiếng Anh bất kỳ để luyện...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: NotionColors.textMuted,
                                  ),
                                  isDense: true,
                                  filled: true,
                                  fillColor: NotionColors.surfaceSubtle,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: NotionColors.borderSubtle,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: NotionColors.textMain,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) =>
                                    _generateIpaAndStartPractice(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: NotionColors.textMain,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: _isGeneratingIpa
                                    ? null
                                    : _generateIpaAndStartPractice,
                                child: _isGeneratingIpa
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Đổi câu',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _suggestedSentences.map((sample) {
                              final isSelected = (_referenceText == sample);
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      _inputController.text = sample;
                                      _generateIpaAndStartPractice();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? NotionColors.tagBlueBg
                                            : NotionColors.surfaceSubtle,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isSelected
                                              ? NotionColors.tagBlueText
                                                    .withAlpha(150)
                                              : NotionColors.borderSubtle,
                                        ),
                                      ),
                                      child: Text(
                                        sample,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: isSelected
                                              ? NotionColors.tagBlueText
                                              : NotionColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Central Target Sentence Card with TTS & Bookmark
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NotionColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NotionColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CÂU MỤC TIÊU',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: NotionColors.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Row(
                              children: [
                                // Bookmark Button
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _saveToNotebook,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isSavedToNotebook
                                            ? NotionColors.tagAmberBg
                                            : NotionColors.surfaceSubtle,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: NotionColors.borderSubtle,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isSavedToNotebook
                                                ? Icons.star_rounded
                                                : Icons.star_border_rounded,
                                            size: 13,
                                            color: _isSavedToNotebook
                                                ? NotionColors.tagAmberText
                                                : NotionColors.textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isSavedToNotebook
                                                ? 'Đã lưu'
                                                : 'Lưu câu này',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: _isSavedToNotebook
                                                  ? NotionColors.tagAmberText
                                                  : NotionColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Listen TTS Button
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _isPlayingTts ? null : _playTts,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: NotionColors.surfaceSubtle,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: NotionColors.borderSubtle,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _isPlayingTts
                                              ? const SizedBox(
                                                  width: 10,
                                                  height: 10,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                        color: NotionColors
                                                            .textMain,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.volume_up_rounded,
                                                  size: 13,
                                                  color: NotionColors.textMain,
                                                ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isPlayingTts
                                                ? 'Đang đọc...'
                                                : 'Nghe mẫu',
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _referenceText,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: NotionColors.textMain,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _ipaTranscription,
                          style: GoogleFonts.robotoMono(
                            fontSize: 12,
                            color: NotionColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Central Microphone Control (Compact & In-View)
                  Center(
                    child: Column(
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _isAnalyzing ? null : _toggleRecording,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRecording
                                    ? NotionColors.tagRedBg
                                    : (_isAnalyzing
                                          ? NotionColors.tagAmberBg
                                          : NotionColors.textMain),
                                border: Border.all(
                                  color: _isRecording
                                      ? NotionColors.tagRedText
                                      : NotionColors.border,
                                  width: _isRecording ? 3 : 1,
                                ),
                                boxShadow: _isRecording
                                    ? [
                                        BoxShadow(
                                          color: NotionColors.tagRedText
                                              .withAlpha(80),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: _isAnalyzing
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: NotionColors.tagAmberText,
                                        ),
                                      )
                                    : Icon(
                                        _isRecording
                                            ? Icons.stop_rounded
                                            : Icons.mic_rounded,
                                        size: 28,
                                        color: _isRecording
                                            ? NotionColors.tagRedText
                                            : Colors.white,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isRecording
                              ? 'Đang thu âm... Bấm để dừng & chấm'
                              : (_isAnalyzing
                                    ? 'Đang phân tích phát âm...'
                                    : 'Chạm micro để luyện nói'),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: _isRecording
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _isRecording
                                ? NotionColors.tagRedText
                                : NotionColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_statusMessage != null && !_isAnalyzing) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: NotionColors.tagAmberBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: NotionColors.tagAmberText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  // 5. In-View Assessment Results (Zero-Scroll Display)
                  if (_result != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NotionColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: NotionColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Score Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getScoreBgColor(
                                        _result!.overallScore,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${_result!.overallScore.toStringAsFixed(0)} / 100',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _getScoreColor(
                                          _result!.overallScore,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _result!.overallScore >= 80
                                        ? '🎉 Phát âm rất chuẩn!'
                                        : 'Cần chú ý âm cuối/âm vị tô đỏ',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getScoreColor(
                                        _result!.overallScore,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Độ chính xác: ${_result!.accuracyScore.toStringAsFixed(0)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: NotionColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Words & Phonemes Visualizer
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _result!.words.map((w) {
                              final wColor = _getScoreColor(w.accuracyScore);
                              final wBg = _getScoreBgColor(w.accuracyScore);

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: wBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: wColor.withAlpha(80),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      w.word,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: wColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: w.phonemes.map((p) {
                                        final isWeak =
                                            !p.isCorrect ||
                                            p.accuracyScore < 70;
                                        return MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                              () => _selectedPhoneme = p,
                                            ),
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 1,
                                                  ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 3,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isWeak
                                                    ? NotionColors.tagRedText
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                              child: Text(
                                                p.symbol,
                                                style: GoogleFonts.robotoMono(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isWeak
                                                      ? Colors.white
                                                      : wColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                          // Selected Phoneme Guidance
                          if (_selectedPhoneme != null &&
                              _selectedPhoneme!.feedback != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: NotionColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: NotionColors.borderSubtle,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🔍',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Âm /${_selectedPhoneme!.symbol}/: ${_selectedPhoneme!.feedback!}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: NotionColors.textMain,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildRecommendations(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _result!.recommendations;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: NotionColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: NotionColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BÀI TẬP NÊN LUYỆN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: NotionColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (recommendations.isEmpty)
            Text(
              'Chưa phát hiện âm yếu cần luyện thêm. Hãy tiếp tục duy trì!',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: NotionColors.textMain,
              ),
            )
          else
            ...recommendations.map(
              (drill) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drill.drillTitle,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: NotionColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${drill.practiceWords.join(' · ')}\n${drill.mouthGuidance}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: NotionColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onOpenLessonForPhoneme == null
                          ? null
                          : () => widget.onOpenLessonForPhoneme!(drill.phoneme),
                      child: const Text('Mở bài học'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
