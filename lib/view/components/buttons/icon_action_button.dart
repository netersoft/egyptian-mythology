import 'package:flutter/material.dart';

import '../../themes/app_colors.dart';

// The gold-pill icon button used by GameOverScreen's Replay/Main/Stats row
// and AboutScreen's Contact/Rate/Share row.
class IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const IconActionButton({required this.icon, required this.tooltip, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 75,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.goldenYellow, AppColors.goldenRod],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Semantics(
          label: tooltip,
          child: Icon(icon, color: Colors.black),
        ),
      ),
    ),
  );
}
