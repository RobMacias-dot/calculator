import 'package:flutter/material.dart';

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
          ],
        ),
      ),
    ],
  );
}
