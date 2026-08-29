import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/models/score_entry_model.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/services/scores/scores_repository.dart';
import '../../components/backgrounds/pyramid_background.dart';
import '../../components/dialogs/egyptian_alert_dialog.dart';
import '../../components/misc/app_header_card.dart';
import '../../components/misc/floating_modal.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_decorations.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _repository = locator<ScoresRepository>();

  List<ScoreEntryModel> _scores = const [];
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _scores = _repository.getAll();
      _bestScore = _repository.getBestScore();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PyramidBackground(
      child: SafeArea(
        child: Column(
          children: [
            AppHeaderCard(title: context.t.bestScore(value: _bestScore)),
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
                                  Text(entry.date, style: const TextStyle(color: AppColors.goldenYellow)),
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
