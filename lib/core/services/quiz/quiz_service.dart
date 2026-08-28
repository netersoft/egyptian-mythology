import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../../models/quiz_question_model.dart';
import '../i18n/translations.g.dart';

class QuizService {
  Future<List<QuizQuestionModel>> loadQuestions({String? localeCode}) async {
    final code = localeCode ?? LocaleSettings.instance.currentLocale.languageCode;
    final raw = await rootBundle.loadString('assets/quiz/questions_$code.json', cache: false);
    final data = jsonDecode(raw) as List<dynamic>;

    final questions = data.map((e) => QuizQuestionModel.fromJson(e as Map<String, dynamic>)).toList()..shuffle(Random());

    return questions;
  }
}
