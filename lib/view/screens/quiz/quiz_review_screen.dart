import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../../core/models/quiz_mistake.dart';
import '../../../core/providers/quiz/quiz_review_provider.dart';
import '../../../core/routes/app_route.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_colors.dart';

// The questions missed in the last game, each with its right answer, why it
// is right, and a link to the documentation page that covers it.
class QuizReviewScreen extends ConsumerWidget {
  const QuizReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakes = ref.watch(quizReviewProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.goldenYellow,
        title: Text(context.t.mistakesTitle),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mistakes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _MistakeCard(mistake: mistakes[index]),
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  final QuizMistake mistake;

  const _MistakeCard({required this.mistake});

  // question_refs.json points at "<category folder>/<item id>".
  void _openDoc(BuildContext context, String ref) {
    final [category, item] = ref.split('/');
    unawaited(locator<AudioService>().playClick());
    unawaited(switch (category) {
      'gods' => GodsDocRoute(item: item).push<void>(context),
      'cosmogonies' => CosmogoniesDocRoute(item: item).push<void>(context),
      _ => MythsDocRoute(item: item).push<void>(context),
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final question = mistake.question;
    final given = mistake.given;
    final explanation = question.explanation;
    final ref = question.ref;

    return Material(
      color: AppColors.blackRussian,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.goldenRod),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: const TextStyle(color: AppColors.goldenYellow, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              given == null ? t.timeUp : t.yourAnswer(value: given),
              style: const TextStyle(color: AppColors.pink, fontSize: 15),
            ),
            Text(
              t.correctAnswer(value: question.answer),
              style: const TextStyle(color: AppColors.limeGreen, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (explanation != null) ...[
              const SizedBox(height: 8),
              HtmlWidget(explanation, textStyle: const TextStyle(color: AppColors.yellow, fontSize: 15)),
            ],
            if (ref != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openDoc(context, ref),
                  icon: const Icon(Icons.menu_book, color: AppColors.goldenRod, size: 18),
                  label: Text(t.learnMore, style: const TextStyle(color: AppColors.goldenRod)),
                ),
              )
            else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
