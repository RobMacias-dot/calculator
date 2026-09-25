import 'package:flutter/material.dart';

import 'app_tokens.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.children,
  });
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: onBack,
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: AppSpacing.sm),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: AppSpacing.lg),
      ...children,
    ],
  );
}
