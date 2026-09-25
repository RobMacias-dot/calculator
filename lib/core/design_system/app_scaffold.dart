import 'package:flutter/material.dart';

import 'app_tokens.dart';
import 'glass_bottom_navigation.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    required this.selected,
    required this.onSelected,
  });
  final Widget child;
  final AppDestination selected;
  final ValueChanged<AppDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.brightness == Brightness.light
              ? const [
                  Color(0xFFFFF6EF),
                  AppColors.background,
                  Color(0xFFEDF2F9),
                ]
              : const [
                  Color(0xFF26211F),
                  AppColors.darkBackground,
                  Color(0xFF192533),
                ],
          stops: const [0, 0.4, 1],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentWidth,
              ),
              child: child,
            ),
          ),
        ),
        bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
            ? null
            : GlassBottomNavigation(selected: selected, onSelected: onSelected),
      ),
    );
  }
}
