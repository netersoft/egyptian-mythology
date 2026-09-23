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
    final refs = jsonDecode(await rootBundle.loadString('assets/quiz/question_refs.json', cache: false)) as Map<String, dynamic>;

    final questions = data.map((e) {
      final q = QuizQuestionModel.fromJson(e as Map<String, dynamic>);
      return QuizQuestionModel(
        id: q.id,
        question: formatQuestion(q.question, code),
        answer: q.answer,
        choices: q.choices,
        explanation: q.explanation,
        ref: refs['${q.id}'] as String?,
      );
    }).toList()..shuffle(Random());

    return questions;
  }

  // The bundled question files are inconsistent: fr never includes the
  // question mark (the legacy app appended " ?" itself), de/es always do,
  // en/pt only sometimes -- so blindly appending one doubled it. Normalize to
  // exactly one, typeset per language: French puts a (non-breaking, so it
  // never wraps alone onto the next line) space before it, the others don't.
  static String formatQuestion(String raw, String localeCode) {
    final text = raw.trim().replaceFirst(RegExp(r'\s*\?$'), '');
    return localeCode == 'fr' ? '$text\u00A0?' : '$text?';
  }
}
