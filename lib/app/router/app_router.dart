import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/app_scaffold.dart';
import '../../core/design_system/detail_page.dart';
import '../../core/design_system/glass_bottom_navigation.dart';
import '../../features/calculators/domain/calculator_category.dart';
import '../../features/calculators/domain/calculator_registry.dart';
import '../../features/calculators/presentation/calculator_preview_screen.dart';
import '../../features/calculators/presentation/calculator_screen.dart';
import '../../features/calculators/presentation/calculator_view_model.dart';
import '../../features/calculators/presentation/playground_screen.dart';
import '../../features/calculators/presentation/category_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/home_view_model.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/preferences/preferences_controller.dart';

abstract final class AppRoutes {
  static const home = 'home';
  static const category = 'category';
  static const calculator = 'calculator';
  static const settings = 'settings';
  static const playground = 'playground';
}

GoRouter createAppRouter({
  required CalculatorRegistry registry,
  required HomeViewModel home,
  required PreferencesController preferences,
  String? initialLocation,
}) => GoRouter(
  initialLocation: initialLocation,
  errorBuilder: (context, state) => Scaffold(
    body: SafeArea(
      child: _NotFound(onHome: () => context.goNamed(AppRoutes.home)),
    ),
  ),
  routes: [
    // Root route covers shell navigation while borrowing its calculator state.
    GoRoute(
      path: '/playground/:calculatorId',
      name: AppRoutes.playground,
      builder: (context, state) {
        final definition = registry.byId(state.pathParameters['calculatorId']!);
        if (definition == null || !definition.supportsPlayground) {
          return Scaffold(
            body: SafeArea(
              child: _NotFound(onHome: () => context.goNamed(AppRoutes.home)),
            ),
          );
        }
        final supplied = state.extra;
        final borrowed =
            supplied is CalculatorViewModel &&
                identical(supplied.definition, definition)
            ? supplied
            : null;
        return PlaygroundScreen(
          key: ValueKey('playground-${definition.id}'),
          definition: definition,
          viewModel: borrowed,
          preferences: preferences,
          onBack: () => context.canPop()
              ? context.pop()
              : context.goNamed(
                  AppRoutes.calculator,
                  pathParameters: {'calculatorId': definition.id},
                ),
        );
      },
    ),
    ShellRoute(
      builder: (context, state, child) => ListenableBuilder(
        listenable: home,
        builder: (context, _) => AppScaffold(
          selected: state.uri.path == '/settings'
              ? AppDestination.settings
              : switch (home.section) {
                  HomeSection.home => AppDestination.home,
                  HomeSection.favorites => AppDestination.favorites,
                  HomeSection.tools => AppDestination.tools,
                },
          onSelected: (destination) {
            FocusManager.instance.primaryFocus?.unfocus();
            if (destination == AppDestination.settings) {
              context.goNamed(AppRoutes.settings);
            } else {
              home.selectSection(switch (destination) {
                AppDestination.favorites => HomeSection.favorites,
                AppDestination.tools => HomeSection.tools,
                _ => HomeSection.home,
              });
              context.goNamed(AppRoutes.home);
            }
          },
          child: child,
        ),
      ),
      routes: [
        GoRoute(
          path: '/',
          name: AppRoutes.home,
          builder: (context, state) => HomeScreen(
            viewModel: home,
            registry: registry,
            preferences: preferences,
            onCategory: (category) => context.pushNamed<void>(
              AppRoutes.category,
              pathParameters: {'categoryId': category.id},
            ),
            onCalculator: (calculator) => context.pushNamed<void>(
              AppRoutes.calculator,
              pathParameters: {'calculatorId': calculator.id},
            ),
          ),
        ),
        GoRoute(
          path: '/category/:categoryId',
          name: AppRoutes.category,
          builder: (context, state) {
            final category = CalculatorCategory.fromId(
              state.pathParameters['categoryId']!,
            );
            if (category == null) {
              return _NotFound(onHome: () => context.goNamed(AppRoutes.home));
            }
            return CategoryScreen(
              category: category,
              calculators: registry.inCategory(category),
              preferences: preferences,
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.goNamed(AppRoutes.home),
              onCalculator: (calculator) => context.pushNamed<void>(
                AppRoutes.calculator,
                pathParameters: {'calculatorId': calculator.id},
              ),
            );
          },
        ),
        GoRoute(
          path: '/calculator/:calculatorId',
          name: AppRoutes.calculator,
          builder: (context, state) {
            final calculator = registry.byId(
              state.pathParameters['calculatorId']!,
            );
            if (calculator == null) {
              return _NotFound(onHome: () => context.goNamed(AppRoutes.home));
            }
            void onBack() => context.canPop()
                ? context.pop()
                : context.goNamed(
                    AppRoutes.category,
                    pathParameters: {'categoryId': calculator.category.id},
                  );
            if (calculator.isAvailable) {
              return CalculatorScreen(
                key: ValueKey(calculator.id),
                definition: calculator,
                preferences: preferences,
                onBack: onBack,
                onExplore: (viewModel) {
                  if (viewModel.result == null &&
                      viewModel.inputs.any(
                        (input) => viewModel.valueFor(input.id).isNotEmpty,
                      )) {
                    viewModel.calculate();
                  }
                  context.pushNamed<void>(
                    AppRoutes.playground,
                    pathParameters: {'calculatorId': calculator.id},
                    extra: viewModel,
                  );
                },
              );
            }
            return CalculatorPreviewScreen(
              definition: calculator,
              onBack: onBack,
            );
          },
        ),
        GoRoute(
          path: '/settings',
          name: AppRoutes.settings,
          builder: (context, state) => SettingsScreen(
            preferences: preferences,
            onBack: () => context.goNamed(AppRoutes.home),
          ),
        ),
      ],
    ),
  ],
);

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onHome});
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => DetailPage(
    title: 'Page not found',
    subtitle: 'This tool or field is not in the catalog yet.',
    onBack: onHome,
    children: [
      FilledButton(onPressed: onHome, child: const Text('Go to Home')),
    ],
  );
}
