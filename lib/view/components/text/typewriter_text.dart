import 'dart:async';

import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration characterDelay;

  const TypewriterText({
    required this.text,
    this.style,
    this.textAlign,
    this.characterDelay = const Duration(milliseconds: 75),
    super.key,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _shown = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    var charCount = 0;
    _timer = Timer.periodic(widget.characterDelay, (timer) {
      if (charCount >= widget.text.length) {
        timer.cancel();
        return;
      }
      charCount++;
      if (mounted) setState(() => _shown = widget.text.substring(0, charCount));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(_shown, style: widget.style, textAlign: widget.textAlign);
}
