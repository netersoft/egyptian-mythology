import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../../core/enums/app_brightness.dart';
import '../../../core/providers/account/settings_provider.dart';
import '../../../core/services/audio/audio_service.dart';
import '../../../core/services/di/locator.dart';
import '../../../core/services/i18n/config.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../components/backgrounds/pyramid_background.dart';
import '../../components/misc/app_header_card.dart';
import '../../components/misc/centered_scrollable.dart';
import '../../components/misc/floating_modal.dart';
import '../../themes/app_colors.dart';

// Mirrors the legacy activity_settings.xml: pyramid backdrop, Thot portrait,
// gold-on-black rows -- rather than settings_ui's default Material list.
const _egyptianSettingsTheme = SettingsThemeData(
  settingsListBackground: Colors.transparent,
  settingsSectionBackground: Color(0x99000000),
  dividerColor: AppColors.goldenRod,
  titleTextColor: AppColors.yellow,
  settingsTileTextColor: AppColors.yellow,
  trailingTextColor: AppColors.goldenRod,
  leadingIconsColor: AppColors.goldenYellow,
);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PyramidBackground(
      child: SafeArea(
        child: Column(
          children: [
            AppHeaderCard(title: context.t.settings),
            Image.asset('assets/images/egyptian/thot.png', height: 140, fit: BoxFit.contain),
            const SizedBox(height: 16),
            const Expanded(child: CenteredScrollable(child: SettingsListWrapper())),
          ],
        ),
      ),
    ),
  );
}

class SettingsListWrapper extends ConsumerStatefulWidget {
  const SettingsListWrapper({super.key});

  @override
  ConsumerState<SettingsListWrapper> createState() => _SettingsListWrapperState();
}

class _SettingsListWrapperState extends ConsumerState<SettingsListWrapper> {
  final _audioService = locator<AudioService>();

  late bool _musicEnabled = _audioService.isMusicEnabled;
  late bool _soundEnabled = _audioService.isSoundEnabled;

  @override
  Widget build(BuildContext context) {
    final settings = ref.read(settingsProvider.notifier);

    var currentLang = I18nConfig.langItems.firstWhereOrNull(
      (item) => item.code == LocaleSettings.instance.currentLocale.languageCode,
    );

    return SettingsList(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      lightTheme: _egyptianSettingsTheme,
      darkTheme: _egyptianSettingsTheme,
      sections: [
        SettingsSection(
          tiles: <SettingsTile>[
            SettingsTile.navigation(
              leading: const Icon(Icons.language),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currentLang?.label[currentLang.code] ?? ''),
                  const Icon(Icons.chevron_right),
                ],
              ),
              title: Text(context.t.language),
              onPressed: (context) => {
                showFloatingModalBottomSheet(
                  context: context,
                  builder: (context) => Material(
                    child: SafeArea(
                      top: false,
                      child: RadioGroup<String>(
                        groupValue: LocaleSettings.instance.currentLocale.languageCode,
                        onChanged: (value) {
                          if (value != LocaleSettings.instance.currentLocale.languageCode) {
                            settings.changeLanguage(value!);
                            context.pop();
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: I18nConfig.langItems
                              .map<Widget>(
                                (item) => RadioListTile(
                                  title: Text(item.label[currentLang?.code]!),
                                  value: item.code,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              },
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.format_paint),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    settings.getAppBrightness() == AppBrightness.system.name
                        ? context.t.system
                        : settings.getAppBrightness() == AppBrightness.light.name
                        ? context.t.light
                        : context.t.dark,
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              title: Text(context.t.theme),
              onPressed: (context) => {
                showFloatingModalBottomSheet(
                  context: context,
                  builder: (context) => Material(
                    child: SafeArea(
                      top: false,
                      child: RadioGroup<String>(
                        groupValue: settings.getAppBrightness(),
                        onChanged: (value) {
                          if (value != settings.getAppBrightness()) {
                            settings.setAppBrightness(value!);
                            context.pop();
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile(
                              title: Text(context.t.light),
                              value: AppBrightness.light.name,
                            ),
                            RadioListTile(
                              title: Text(context.t.dark),
                              value: AppBrightness.dark.name,
                            ),
                            RadioListTile(
                              title: Text(context.t.system),
                              value: AppBrightness.system.name,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              },
            ),
          ],
        ),
        SettingsSection(
          tiles: <SettingsTile>[
            SettingsTile.switchTile(
              initialValue: _musicEnabled,
              onToggle: (value) {
                setState(() => _musicEnabled = value);
                _audioService.setMusicEnabled(value);
              },
              leading: Icon(_musicEnabled ? Icons.music_note : Icons.music_off),
              title: Text(context.t.music),
            ),
            SettingsTile.switchTile(
              initialValue: _soundEnabled,
              onToggle: (value) {
                setState(() => _soundEnabled = value);
                _audioService.setSoundEnabled(value);
              },
              leading: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off),
              title: Text(context.t.song),
            ),
          ],
        ),
      ],
    );
  }
}
