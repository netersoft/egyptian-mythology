import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_colors.dart';
import '../text/typewriter_text.dart';

// The ankh + yellow card header used by MainScreen and InstructionsScreen
// (activity_main.xml / activity_instructions.xml both use the same header).
class AppHeaderCard extends StatelessWidget {
  final String title;

  const AppHeaderCard({required this.title, super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2160),
      curve: Curves.easeIn,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/egyptian/ankh_launcher.png', width: 100, height: 100),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.t.appNameAlt,
                  style: const TextStyle(color: AppColors.dimGray, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                TypewriterText(
                  text: title,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
