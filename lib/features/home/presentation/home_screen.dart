import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/glass_card.dart';
import '../../calculators/domain/calculator_category.dart';
import '../../calculators/domain/calculator_definition.dart';
import '../../calculators/domain/calculator_registry.dart';
import '../../calculators/presentation/calculator_tile.dart';
import 'engineering_category_card.dart';
import 'home_view_model.dart';
import '../../preferences/preferences_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.viewModel,
    required this.registry,
    required this.preferences,
    required this.onCategory,
    required this.onCalculator,
  });
  final HomeViewModel viewModel;
  final CalculatorRegistry registry;
  final PreferencesController preferences;
  final ValueChanged<CalculatorCategory> onCategory;
  final ValueChanged<CalculatorDefinition> onCalculator;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.viewModel.query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.viewModel, widget.preferences]),
    builder: (context, _) {
      final vm = widget.viewModel;
      final theme = Theme.of(context);
      final favorites = vm.section == HomeSection.favorites;
      final showCatalog =
          vm.section == HomeSection.tools || vm.query.trim().isNotEmpty;
      final results = favorites ? widget.preferences.favorites : vm.results;
      return CustomScrollView(
        key: PageStorageKey(vm.section),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                        ),
                        child: Icon(
                          Icons.architecture_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'THE ENGINEER’S COMPANION',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.6,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(switch (vm.section) {
                    HomeSection.home => 'Engineering Toolkit',
                    HomeSection.favorites => 'Your favorites',
                    HomeSection.tools => 'Explore tools',
                  }, style: theme.textTheme.headlineLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    switch (vm.section) {
                      HomeSection.home => 'Calculate. Understand. Build.',
                      HomeSection.favorites =>
                        'A little space for your everyday essentials.',
                      HomeSection.tools => 'Small tools. Fundamental ideas.',
                    },
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!favorites)
                    TextField(
                      controller: _search,
                      onChanged: vm.setQuery,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: 'Search tools or fields',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: vm.query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _search.clear();
                                  vm.resetSearch();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  if (vm.section == HomeSection.tools) ...[
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<CalculatorCategory?>(
                      key: ValueKey(vm.category),
                      initialValue: vm.category,
                      isExpanded: true,
                      itemHeight: null,
                      decoration: const InputDecoration(
                        labelText: 'Engineering field',
                      ),
                      items: [
                        const DropdownMenuItem(child: Text('All fields')),
                        for (final category in CalculatorCategory.values)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category.label),
                          ),
                      ],
                      onChanged: vm.setCategory,
                    ),
                  ],
                  if (!favorites && !showCatalog) ...[
                    const SizedBox(height: AppSpacing.lg),
                    if (widget.preferences.recents.isNotEmpty) ...[
                      Text('Recent tools', style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.md),
                      for (final calculator in widget.preferences.recents)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: CalculatorTile(
                            definition: calculator,
                            preferences: widget.preferences,
                            onTap: () => _openCalculator(calculator),
                          ),
                        ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Engineering fields',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'A world of engineering, in your pocket.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (!favorites && showCatalog) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        '${results.length} ${results.length == 1 ? 'tool' : 'tools'} · Offline catalog',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (favorites && results.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: _EmptyState(
                  icon: Icons.star_border_rounded,
                  title: 'Make room for your go-to tools',
                  message: 'Your favorite tools will appear here. Tap a star to keep an everyday essential close.',
                  action: FilledButton(
                    onPressed: () {
                      _search.clear();
                      vm.resetSearch();
                      vm.setCategory(null);
                      vm.selectSection(HomeSection.tools);
                    },
                    child: const Text('Explore tools'),
                  ),
                ),
              ),
            )
          else if (favorites || showCatalog) ...[
            if (results.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: _EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No tools found',
                    message:
                        vm.category != null && vm.section == HomeSection.tools
                        ? 'Try another field or clear your search to explore more tools.'
                        : 'Try a concept such as current or subnet, a tool name, or an engineering field.',
                    action: TextButton(
                      onPressed: () {
                        _search.clear();
                        vm.resetSearch();
                        vm.setCategory(null);
                      },
                      child: const Text('Clear filters'),
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList.builder(
                itemCount: results.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: CalculatorTile(
                    definition: results[index],
                    preferences: widget.preferences,
                    onTap: () => _openCalculator(results[index]),
                  ),
                ),
              ),
            ),
          ] else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final largeText =
                        MediaQuery.textScalerOf(context).scale(16) > 22;
                    final columns = constraints.maxWidth > 840
                        ? 3
                        : constraints.maxWidth >= 320 && !largeText
                        ? 2
                        : 1;
                    final width =
                        (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                        columns;
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final category in CalculatorCategory.values)
                          SizedBox(
                            width: width,
                            child: EngineeringCategoryCard(
                              category: category,
                              toolCount: widget.registry
                                  .inCategory(category)
                                  .length,
                              onTap: () => widget.onCategory(category),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Built for curious minds. Designed to work offline.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  void _openCalculator(CalculatorDefinition calculator) {
    FocusScope.of(context).unfocus();
    widget.onCalculator(calculator);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      children: [
        Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(message, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
      ],
    ),
  );
}
