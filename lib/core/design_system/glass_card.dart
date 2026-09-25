import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Translucent surface without a per-card backdrop filter.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: theme.brightness == Brightness.light
                ? Colors.white
                : theme.colorScheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
