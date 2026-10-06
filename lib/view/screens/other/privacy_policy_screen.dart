import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_colors.dart';

// The privacy policy, from assets/docs/<locale>/privacy_policy.html: bundled
// with the app so it reads offline. Every app language has its own page.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.black,
    appBar: AppBar(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.goldenYellow,
      title: Text(context.t.privacyPolicy),
    ),
    body: FutureBuilder<String>(
      future: rootBundle.loadString('assets/docs/${LocaleSettings.instance.currentLocale.languageCode}/privacy_policy.html'),
      builder: (context, snapshot) => switch (snapshot.data) {
        final html? => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: HtmlWidget(
            html,
            onTapUrl: (url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            customStylesBuilder: (element) => switch (element.localName) {
              'a' => const {'color': '#DAA520', 'text-decoration': 'underline'},
              'h1' || 'h2' => const {'color': '#DAA520'},
              _ => null,
            },
            textStyle: const TextStyle(color: AppColors.goldenYellow, fontSize: 15),
          ),
        ),
        null => const SizedBox.shrink(),
      },
    ),
  );
}
