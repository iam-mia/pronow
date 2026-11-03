import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PhonemeScoreModel {
  final String symbol;
  final String targetPhoneme;
  final double accuracyScore;
  final bool isCorrect;
  final String? feedback;

  PhonemeScoreModel({
    required this.symbol,
    required this.targetPhoneme,
    required this.accuracyScore,
    required this.isCorrect,
    this.feedback,
  });

  factory PhonemeScoreModel.fromJson(Map<String, dynamic> json) {
    return PhonemeScoreModel(
      symbol: json['symbol'] ?? '',
      targetPhoneme: json['target_phoneme'] ?? '',
      accuracyScore: (json['accuracy_score'] as num?)?.toDouble() ?? 0.0,
      isCorrect: json['is_correct'] ?? true,
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'target_phoneme': targetPhoneme,
    'accuracy_score': accuracyScore,
    'is_correct': isCorrect,
    'feedback': feedback,
  };
}

class WordScoreModel {
  final String word;
  final double accuracyScore;
  final String errorType;
  final List<PhonemeScoreModel> phonemes;

  WordScoreModel({
    required this.word,
    required this.accuracyScore,
    required this.errorType,
    required this.phonemes,
  });

  factory WordScoreModel.fromJson(Map<String, dynamic> json) {
    var pList = (json['phonemes'] as List?) ?? [];
    return WordScoreModel(
      word: json['word'] ?? '',
      accuracyScore: (json['accuracy_score'] as num?)?.toDouble() ?? 0.0,
      errorType: json['error_type'] ?? 'None',
      phonemes: pList.map((p) => PhonemeScoreModel.fromJson(p)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'accuracy_score': accuracyScore,
    'error_type': errorType,
    'phonemes': phonemes.map((p) => p.toJson()).toList(),
  };
}

class TargetedDrillModel {
  final String phoneme;
  final String drillTitle;
  final List<String> practiceWords;
  final String mouthGuidance;

  TargetedDrillModel({
    required this.phoneme,
    required this.drillTitle,
    required this.practiceWords,
    required this.mouthGuidance,
  });

  factory TargetedDrillModel.fromJson(Map<String, dynamic> json) {
    var words =
        (json['practice_words'] as List?)?.map((e) => e.toString()).toList() ??
        [];
    return TargetedDrillModel(
      phoneme: json['phoneme'] ?? '',
      drillTitle: json['drill_title'] ?? '',
      practiceWords: words,
      mouthGuidance: json['mouth_guidance'] ?? '',
    );
  }
}

class AssessmentResultModel {
  final double overallScore;
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;
  final List<WordScoreModel> words;
  final List<String> weakPhonemes;
  final List<TargetedDrillModel> recommendations;
  final Map<String, dynamic>? streakInfo;

  AssessmentResultModel({
    required this.overallScore,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.words,
    required this.weakPhonemes,
    required this.recommendations,
    this.streakInfo,
  });

  factory AssessmentResultModel.fromJson(Map<String, dynamic> json) {
    var wList = (json['words'] as List?) ?? [];
    var weakList =
        (json['weak_phonemes'] as List?)?.map((e) => e.toString()).toList() ??
        [];
    var recList = (json['recommendations'] as List?) ?? [];

    return AssessmentResultModel(
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
      accuracyScore: (json['accuracy_score'] as num?)?.toDouble() ?? 0.0,
      fluencyScore: (json['fluency_score'] as num?)?.toDouble() ?? 0.0,
      completenessScore:
          (json['completeness_score'] as num?)?.toDouble() ?? 0.0,
      words: wList.map((w) => WordScoreModel.fromJson(w)).toList(),
      weakPhonemes: weakList,
      recommendations: recList
          .map((r) => TargetedDrillModel.fromJson(r))
          .toList(),
      streakInfo: json['streak_info'],
    );
  }
}

class DailyPracticeSummary {
  final String practiceDate;
  final double averageScore;
  final int attemptsCount;
  final double minutesCompleted;
  final int sentencesCompleted;

  const DailyPracticeSummary({
    required this.practiceDate,
    required this.averageScore,
    required this.attemptsCount,
    required this.minutesCompleted,
    required this.sentencesCompleted,
  });

  factory DailyPracticeSummary.fromJson(Map<String, dynamic> json) {
    return DailyPracticeSummary(
      practiceDate: json['practice_date'] ?? '',
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0,
      attemptsCount: (json['attempts_count'] as num?)?.toInt() ?? 0,
      minutesCompleted: (json['minutes_completed'] as num?)?.toDouble() ?? 0,
      sentencesCompleted: (json['sentences_completed'] as num?)?.toInt() ?? 0,
    );
  }
}

class ApiService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'PRONOW_API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  static String getTtsUrl(String text) {
    return '$baseUrl/tts?text=${Uri.encodeComponent(text)}';
  }

  static Future<String> transcribeSentence(String text) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/transcribe?text=${Uri.encodeComponent(text)}'),
          )
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['ipa'] ?? '/${text.toLowerCase()}/';
      }
    } catch (_) {}
    return '/${text.toLowerCase()}/';
  }

  static Future<List<DailyPracticeSummary>> getDailyActivity({
    String userId = 'default-user',
    int days = 31,
  }) async {
    final res = await http
        .get(Uri.parse('$baseUrl/daily-activity/$userId?days=$days'))
        .timeout(const Duration(seconds: 3));
    if (res.statusCode != 200) {
      throw http.ClientException(
        'Daily activity request failed: ${res.statusCode}',
        res.request?.url,
      );
    }
    final List list = jsonDecode(res.body);
    return list.map((item) => DailyPracticeSummary.fromJson(item)).toList();
  }

  static Future<Map<String, dynamic>> getStreakStatus({
    String userId = 'default-user',
  }) async {
    final res = await http
        .get(Uri.parse('$baseUrl/streaks/$userId'))
        .timeout(const Duration(seconds: 3));
    if (res.statusCode != 200) {
      throw http.ClientException(
        'Streak request failed: ${res.statusCode}',
        res.request?.url,
      );
    }
    return jsonDecode(res.body);
  }

  static Future<AssessmentResultModel> assessPronunciation({
    required String referenceText,
    List<int>? audioBytes,
    String userId = 'default-user',
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/assess-pronunciation'),
      );
      request.fields['reference_text'] = referenceText;
      request.fields['user_id'] = userId;

      if (audioBytes != null && audioBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'audio',
            audioBytes,
            filename: 'recording.wav',
          ),
        );
      }

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 10),
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return AssessmentResultModel.fromJson(data);
      }
    } catch (_) {}

    return AssessmentResultModel(
      overallScore: 0.0,
      accuracyScore: 0.0,
      fluencyScore: 0.0,
      completenessScore: 0.0,
      words: [],
      weakPhonemes: [],
      recommendations: [
        TargetedDrillModel(
          phoneme: "Micro",
          drillTitle: "Không có tín hiệu âm thanh",
          practiceWords: [],
          mouthGuidance: "Không nhận được âm thanh từ micro hoặc backend chưa mở. Vui lòng thử lại.",
        ),
      ],
    );
  }

  // --- Lesson Progress API ---
  static Future<Map<String, dynamic>?> recordLessonProgress({
    required String lessonId,
    required String sentenceId,
    required String sentenceText,
    required double score,
    String userId = 'default-user',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/lesson-progress'),
            body: {
              'user_id': userId,
              'lesson_id': lessonId,
              'sentence_id': sentenceId,
              'sentence_text': sentenceText,
              'score': score.toString(),
            },
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<LessonProgressItem>> getLessonProgress({
    String userId = 'default-user',
  }) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/lesson-progress/$userId'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => LessonProgressItem.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // --- Saved Custom Sentences API ---
  static Future<bool> saveCustomSentence({
    required String sentenceText,
    required String ipa,
    String userId = 'default-user',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/saved-sentences'),
            body: {
              'user_id': userId,
              'sentence_text': sentenceText,
              'ipa': ipa,
            },
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<SavedSentenceItem>> getSavedCustomSentences({
    String userId = 'default-user',
  }) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/saved-sentences/$userId'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => SavedSentenceItem.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> deleteSavedCustomSentence(
    int id, {
    String userId = 'default-user',
  }) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl/saved-sentences/$id?user_id=$userId'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class LessonProgressItem {
  final String userId;
  final String lessonId;
  final String sentenceId;
  final String sentenceText;
  final double bestScore;
  final bool isPassed;
  final int attemptsCount;
  final String lastAttemptAt;

  LessonProgressItem({
    required this.userId,
    required this.lessonId,
    required this.sentenceId,
    required this.sentenceText,
    required this.bestScore,
    required this.isPassed,
    required this.attemptsCount,
    required this.lastAttemptAt,
  });

  factory LessonProgressItem.fromJson(Map<String, dynamic> json) {
    return LessonProgressItem(
      userId: json['user_id'] ?? '',
      lessonId: json['lesson_id'] ?? '',
      sentenceId: json['sentence_id'] ?? '',
      sentenceText: json['sentence_text'] ?? '',
      bestScore: (json['best_score'] as num?)?.toDouble() ?? 0.0,
      isPassed: json['is_passed'] == 1 || json['is_passed'] == true,
      attemptsCount: json['attempts_count'] ?? 1,
      lastAttemptAt: json['last_attempt_at'] ?? '',
    );
  }
}

class SavedSentenceItem {
  final int id;
  final String userId;
  final String sentenceText;
  final String ipa;
  final String createdAt;

  SavedSentenceItem({
    required this.id,
    required this.userId,
    required this.sentenceText,
    required this.ipa,
    required this.createdAt,
  });

  factory SavedSentenceItem.fromJson(Map<String, dynamic> json) {
    return SavedSentenceItem(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      sentenceText: json['sentence_text'] ?? '',
      ipa: json['ipa'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
