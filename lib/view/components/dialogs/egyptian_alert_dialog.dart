import 'package:flutter/material.dart';

import '../../themes/app_colors.dart';

// Mirrors the legacy app's CustomDialogTheme / background_dialog.xml: a
// goldenRod card with a goldenYellow border, rounded corners, and an inset
// margin. Text is black (not the legacy's white) to match the rest of the
// app, where content sitting on a gold background is always black.
class EgyptianAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<Widget> actions;

  const EgyptianAlertDialog({
    required this.title,
    required this.content,
    required this.actions,
    super.key,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.goldenRod,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: AppColors.goldenYellow, width: 2),
    ),
    titleTextStyle: const TextStyle(
      fontFamily: 'papyrus',
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
    contentTextStyle: const TextStyle(fontFamily: 'papyrus', color: Colors.black, fontSize: 16),
    title: Text(title),
    content: Text(content),
    actions: actions,
  );
}

// A TextButton pre-styled with black foreground text, for use in an
// [EgyptianAlertDialog]'s actions.
class EgyptianDialogAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const EgyptianDialogAction({required this.label, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(foregroundColor: Colors.black),
    onPressed: onPressed,
    child: Text(label),
  );
}
