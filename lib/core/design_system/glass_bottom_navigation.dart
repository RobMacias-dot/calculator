import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_tokens.dart';

enum AppDestination {
  home('Home', Icons.home_outlined, Icons.home_rounded),
  favorites('Favorites', Icons.star_border_rounded, Icons.star_rounded),
  tools('Tools', Icons.grid_view_outlined, Icons.grid_view_rounded),
  settings('Settings', Icons.tune_rounded, Icons.tune_rounded);

  const AppDestination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class GlassBottomNavigation extends StatelessWidget {
  const GlassBottomNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppDestination selected;
  final ValueChanged<AppDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.capsule),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(AppRadius.capsule),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      for (final destination in AppDestination.values)
                        Expanded(
                          child: _DestinationButton(
                            destination: destination,
                            selected: destination == selected,
                            onTap: () => onSelected(destination),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DestinationButton extends StatelessWidget {
  const _DestinationButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });
  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact =
        MediaQuery.sizeOf(context).width < 380 ||
        MediaQuery.textScalerOf(context).scale(12) > 18;
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      onTap: onTap,
      child: Tooltip(
        message: destination.label,
        excludeFromSemantics: true,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppDurations.quick,
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      color: color,
                      size: 22,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        destination.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
