import 'package:json_annotation/json_annotation.dart';

part 'quiz_question_model.g.dart';

@JsonSerializable(includeIfNull: false)
class QuizQuestionModel {
  final int id;
  final String question;
  final String answer;
  final List<String> choices;
  // Why the answer is right, shown when reviewing mistakes (may hold inline
  // HTML). Not every locale has them yet.
  final String? explanation;
  // Documentation page covering the question, as "<category folder>/<item
  // id>" -- locale-independent, so it lives in question_refs.json and is
  // filled in by QuizService.
  final String? ref;

  const QuizQuestionModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.choices,
    this.explanation,
    this.ref,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) => _$QuizQuestionModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuizQuestionModelToJson(this);
}
