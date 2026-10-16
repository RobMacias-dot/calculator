import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/detail_page.dart';
import '../../../core/design_system/glass_card.dart';
import '../../preferences/preferences_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.preferences,
    required this.onBack,
  });
  final PreferencesController preferences;
  final VoidCallback onBack;

  // Flutter embeds the pubspec version (including build flag overrides).
  static String? get _applicationVersion => appBuildName == null
      ? null
      : '$appBuildName${appBuildNumber == null ? '' : ' ($appBuildNumber)'}';

  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://robmacsoftware.github.io/engineering-toolkit/privacy/',
  );

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    try {
      if (await launchUrl(
        _privacyPolicyUrl,
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // A missing handler or platform failure leaves Settings usable.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Could not open the Privacy Policy.'),
          action: SnackBarAction(
            label: 'Copy link',
            onPressed: () => _copyPrivacyPolicyUrl(context),
          ),
        ),
      );
  }

  Future<void> _copyPrivacyPolicyUrl(BuildContext context) async {
    var message = 'Privacy Policy link copied';
    try {
      await Clipboard.setData(
        ClipboardData(text: _privacyPolicyUrl.toString()),
      );
    } catch (_) {
      message = 'Could not copy the Privacy Policy link.';
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => DetailPage(
    title: 'Settings',
    subtitle: 'A workspace that feels like yours.',
    onBack: onBack,
    children: [
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            ValueListenableBuilder(
              valueListenable: preferences.themeMode,
              builder: (context, value, _) => DropdownMenu<ThemeMode>(
                initialSelection: value,
                label: const Text('Theme'),
                expandedInsets: EdgeInsets.zero,
                onSelected: (mode) {
                  if (mode != null) preferences.setThemeMode(mode);
                },
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: ThemeMode.light, label: 'Light'),
                  DropdownMenuEntry(value: ThemeMode.dark, label: 'Dark'),
                  DropdownMenuEntry(value: ThemeMode.system, label: 'System'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListenableBuilder(
              listenable: preferences,
              builder: (context, _) => Text(
                preferences.storageFailed
                    ? 'Changes are available for this session. Saving preferences is temporarily unavailable.'
                    : 'Your appearance choice is saved on this device.',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text('Engineering Toolkit\nCalculate. Understand. Build.'),
            const SizedBox(height: AppSpacing.sm),
            const Text('RobMac Software'),
            Text(
              _applicationVersion == null
                  ? 'Version unavailable'
                  : 'Version $_applicationVersion',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Engineering Toolkit',
                applicationVersion: _applicationVersion,
              ),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Open-source licenses'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => _openPrivacyPolicy(context),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Privacy Policy'),
            ),
          ],
        ),
      ),
    ],
  );
}
