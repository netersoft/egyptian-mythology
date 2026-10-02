import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/quiz_theme.dart';
import '../../../core/models/score_entry_model.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/services/scores/scores_repository.dart';
import '../../components/backgrounds/pyramid_background.dart';
import '../../components/dialogs/egyptian_alert_dialog.dart';
import '../../components/misc/app_header_card.dart';
import '../../components/misc/floating_modal.dart';
import '../../components/misc/quiz_theme_chips.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_decorations.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _repository = locator<ScoresRepository>();

  // Each theme has its own history and record (see ScoresRepository); null is
  // the "All" view, every game whatever its theme, which has no record.
  QuizTheme? _theme;
  List<ScoreEntryModel> _scores = const [];
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      final theme = _theme;
      _scores = theme == null ? _repository.getAllGames() : _repository.getAll(theme);
      _bestScore = theme == null ? 0 : _repository.getBestScore(theme);
    });
  }

  Future<void> _confirmClear(BuildContext context) async {
    unawaited(locator<AudioService>().playClick());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => EgyptianAlertDialog(
        title: dialogContext.t.confirmTitle,
        content: dialogContext.t.confirmDeleteScores,
        actions: [
          EgyptianDialogAction(label: dialogContext.t.cancel, onPressed: () => Navigator.of(dialogContext).pop(false)),
          EgyptianDialogAction(label: dialogContext.t.yes, onPressed: () => Navigator.of(dialogContext).pop(true)),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _repository.clear();
      _refresh();
    }
  }

  Future<void> _showProgress(BuildContext context) async {
    unawaited(locator<AudioService>().playClick());
    if (_scores.isEmpty) return;

    final t = context.t;

    await showFloatingModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 260,
          child: Column(
            children: [
              Text(t.scoresProgress, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: [for (var i = 0; i < _scores.length; i++) FlSpot(i.toDouble(), _scores[i].score.toDouble())],
                        color: AppColors.goldenYellow,
                        belowBarData: BarAreaData(show: true, color: const Color(0x33FFD700)),
                      ),
                    ],
                    titlesData: const FlTitlesData(show: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots
                            .map((s) => LineTooltipItem(t.score(value: s.y.toInt()), const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Localized date + time in the current app language, e.g. "Sep 23, 2026 14:05"
  // (en) / "23 sept. 2026 14:05" (fr). Falls back to the raw legacy string for
  // an old entry whose timestamp couldn't be parsed.
  String _formatDate(ScoreEntryModel entry) {
    final playedAt = entry.playedAt;
    if (playedAt == null) return entry.date;
    return DateFormat.yMMMd(LocaleSettings.instance.currentLocale.languageCode).add_Hm().format(playedAt);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PyramidBackground(
      child: SafeArea(
        child: Column(
          children: [
            AppHeaderCard(title: _theme == null ? context.t.allGames : context.t.bestScore(value: _bestScore)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: QuizThemeChips(
                keyPrefix: 'stats_theme',
                includeEverything: true,
                selected: _theme,
                onSelected: (theme) {
                  _theme = theme;
                  _refresh();
                },
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: AppDecorations.darkGradientBox,
                child: _scores.isEmpty
                    ? Center(
                        child: Text(context.t.noScore, style: const TextStyle(color: AppColors.yellow, fontSize: 16)),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView.separated(
                          itemCount: _scores.length,
                          separatorBuilder: (context, index) => const Divider(color: AppColors.goldenRod, height: 1),
                          itemBuilder: (context, index) {
                            final entry = _scores[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_formatDate(entry), style: const TextStyle(color: AppColors.goldenYellow)),
                                      // In the "All" view, say which game each score comes from.
                                      if (_theme == null)
                                        Text(
                                          entry.quizTheme.label(context.t),
                                          style: const TextStyle(color: AppColors.goldenRod, fontSize: 12),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    '${entry.score}',
                                    style: const TextStyle(color: AppColors.goldenRod, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatsActionButton(label: context.t.progress, onTap: () => _showProgress(context)),
                  _StatsActionButton(label: context.t.delete, onTap: () => _confirmClear(context), barOnRight: true),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatsActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool barOnRight;

  const _StatsActionButton({required this.label, required this.onTap, this.barOnRight = false});

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      width: 5,
      height: 52,
      decoration: BoxDecoration(color: AppColors.goldenYellow, borderRadius: BorderRadius.circular(42)),
    );
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.goldenYellow, AppColors.goldenRod],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: barOnRight ? [button, bar] : [bar, button],
    );
  }
}
