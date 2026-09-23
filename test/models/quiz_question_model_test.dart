import 'package:egyptian_mythology/core/models/quiz_question_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuizQuestionModel', () {
    test('fromJson/toJson round-trips all fields', () {
      const json = {
        'id': 1,
        'question': 'Who is the sovereign god and supreme judge of the Kingdom of the Dead',
        'answer': 'Osiris',
        'choices': ['Osiris', 'Anubis', 'Onasis', 'Thot'],
        'explanation': 'Osiris rules the afterlife.',
      };

      final model = QuizQuestionModel.fromJson(json);

      expect(model.id, 1);
      expect(model.question, json['question']);
      expect(model.answer, 'Osiris');
      expect(model.choices, ['Osiris', 'Anubis', 'Onasis', 'Thot']);
      expect(model.explanation, 'Osiris rules the afterlife.');
      expect(model.toJson(), json);
    });
  });
}
