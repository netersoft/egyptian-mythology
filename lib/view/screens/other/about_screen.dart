import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../components/backgrounds/pyramid_background.dart';
import '../../components/buttons/icon_action_button.dart';
import '../../components/misc/centered_scrollable.dart';
import '../../components/text/typewriter_text.dart';
import '../../themes/app_colors.dart';

// Mirrors the legacy app's Play Store share link; there's no publish target
// yet, but the package id (com.neteru.ankh) is kept for continuity.
const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.neteru.ankh';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _share(BuildContext context) async {
    unawaited(locator<AudioService>().playClick());
    final t = context.t;
    await SharePlus.instance.share(
      ShareParams(
        text: t.shareAppMsg(value: _playStoreUrl),
        subject: t.shareAppTitle,
      ),
    );
  }

  Future<void> _contact(BuildContext context) async {
    unawaited(locator<AudioService>().playClick());
    final uri = Uri(
      scheme: 'mailto',
      path: 'support.netersoft@gmail.com',
      queryParameters: {'subject': '${context.t.appNameAlt} - Feedback'},
    );
    await launchUrl(uri);
  }

  // requestReview() also silently no-ops once Google's per-app review quota
  // is hit -- there's no callback to detect that, so the only thing app code
  // can do is make sure isAvailable() == false (e.g. a sideloaded, non-Play
  // Store install) doesn't leave the button doing nothing: fall back to the
  // Play Store listing itself, where the user can leave a review directly.
  Future<void> _rate() async {
    unawaited(locator<AudioService>().playClick());
    if (await InAppReview.instance.isAvailable()) {
      await InAppReview.instance.requestReview();
    } else {
      await InAppReview.instance.openStoreListing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      body: PyramidBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CenteredScrollable(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset('assets/images/egyptian/khepri.png', width: 75, height: 75, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.appNameAlt,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.goldenYellow, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) => Text(
                          snapshot.hasData ? 'v${snapshot.data!.version}' : '',
                          style: const TextStyle(color: AppColors.goldenYellow),
                        ),
                      ),
                      Text(t.credits, style: const TextStyle(color: AppColors.goldenYellow)),
                      const SizedBox(height: 12),
                      TypewriterText(
                        text: '${t.about1}\n\n${t.about2}\n\n${t.about3}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.yellow, fontSize: 13),
                      ),
                      const Divider(color: AppColors.yellow, height: 32),
                      HtmlWidget(
                        t.copyright,
                        textStyle: const TextStyle(color: AppColors.goldenYellow, fontSize: 12),
                        onTapUrl: (url) async {
                          await launchUrl(Uri.parse(url));
                          return true;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconActionButton(icon: Icons.email, tooltip: t.toContact, onTap: () => _contact(context)),
                    IconActionButton(icon: Icons.favorite, tooltip: t.rate, onTap: _rate),
                    IconActionButton(icon: Icons.share, tooltip: t.share, onTap: () => _share(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
