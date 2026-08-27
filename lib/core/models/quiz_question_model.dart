import 'package:json_annotation/json_annotation.dart';

part 'quiz_question_model.g.dart';

@JsonSerializable()
class QuizQuestionModel {
  final int id;
  final String question;
  final String answer;
  final List<String> choices;

  const QuizQuestionModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.choices,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) => _$QuizQuestionModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuizQuestionModelToJson(this);
}
