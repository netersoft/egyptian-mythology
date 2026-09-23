import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_colors.dart';

// Sources of the texts and authors/licences of the pictures and music, from
// assets/docs/<locale>/credits.html. Links open in the browser.
class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  String? _html;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final locale = LocaleSettings.instance.currentLocale.languageCode;
    String raw;
    try {
      raw = await rootBundle.loadString('assets/docs/$locale/credits.html');
    } catch (_) {
      // Not every locale ships its own page yet.
      raw = await rootBundle.loadString('assets/docs/en/credits.html');
    }
    final body = RegExp(r'<body[^>]*>([\s\S]*)</body>').firstMatch(raw)?.group(1) ?? raw;
    if (mounted) setState(() => _html = body);
  }

  Future<bool> _onTapUrl(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.black,
    appBar: AppBar(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.goldenYellow,
      title: Text(context.t.sourcesAndCredits),
    ),
    body: _html == null
        ? const SizedBox.shrink()
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: HtmlWidget(
              _html!,
              onTapUrl: _onTapUrl,
              customStylesBuilder: (element) => switch (element.localName) {
                'a' => const {'color': '#DAA520', 'text-decoration': 'underline'},
                'h2' => const {'color': '#DAA520'},
                _ => null,
              },
              textStyle: const TextStyle(color: AppColors.goldenYellow, fontSize: 15),
            ),
          ),
  );
}
