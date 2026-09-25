import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';

/// Shared only by the four pilots: one useful semantics node, bounded geometry
/// and repaint isolation. Numerical labels remain normal, scalable widgets.
class VisualScene extends StatelessWidget {
  const VisualScene({super.key, required this.summary, required this.child});
  final String summary;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: summary,
    image: true,
    child: ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AspectRatio(
            aspectRatio: 1.35,
            child: RepaintBoundary(child: child),
          ),
        ),
      ),
    ),
  );
}
