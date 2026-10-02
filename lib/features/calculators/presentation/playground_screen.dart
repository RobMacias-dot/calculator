import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/glass_card.dart';
import '../domain/calculator_definition.dart';
import '../../preferences/preferences_controller.dart';
import 'calculator_input_field.dart';
import 'calculator_mode_selector.dart';
import 'calculator_view_model.dart';
import 'result_card.dart';
import 'engineering_context_card.dart';
import 'visual_learning/visual_model_view.dart';
import 'visual_learning/visual_models.dart';

/// A route borrows the ordinary form's VM when opened there. A direct link owns
/// one local VM instead. No copied inputs/results and no global calculator state.
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({
    super.key,
    required this.definition,
    required this.onBack,
    required this.preferences,
    this.viewModel,
  });
  final CalculatorDefinition definition;
  final CalculatorViewModel? viewModel;
  final VoidCallback onBack;
  final PreferencesController preferences;

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  late final CalculatorViewModel _viewModel;
  late final bool _ownsViewModel;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? CalculatorViewModel(widget.definition);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.preferences.recordOpened(widget.definition.id);
    });
  }

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        tooltip: 'Back to calculator',
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Interactive Playground',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.definition.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Edit inputs to see the result and diagram update together.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PlaygroundContent(viewModel: _viewModel),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Layout composition only. Every output in a build derives from one report.
/// The renderer alone listens to animation ticks, never this calculation UI.
class PlaygroundContent extends StatelessWidget {
  const PlaygroundContent({super.key, required this.viewModel});
  final CalculatorViewModel viewModel;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final theme = Theme.of(context);
      final report = viewModel.result;
      final model = report == null ? null : mapVisualModel(report);
      final inputs = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (viewModel.definition.modes.length > 1) ...[
                  CalculatorModeSelector(viewModel: viewModel),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text('Inputs', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(viewModel.mode.inputHint),
                const SizedBox(height: AppSpacing.md),
                for (final input in viewModel.inputs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: CalculatorInputField(
                      key: ValueKey(
                        'playground-${viewModel.mode.id}-${input.id}',
                      ),
                      input: input,
                      viewModel: viewModel,
                      live: true,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (report != null)
            GlassCard(
              child: CalculationResultSummary(
                result: report,
                calculatorName: viewModel.definition.name,
                label: 'Calculated · ${viewModel.mode.label}',
              ),
            )
          else
            GlassCard(
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Waiting for valid inputs',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Complete the inputs to show the current result and visualization.',
                    ),
                    for (final issue in viewModel.generalIssues)
                      Text(
                        issue.message,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                  ],
                ),
              ),
            ),
        ],
      );
      final outputs = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (model != null) ...[
            Text('Visualization', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            VisualModelView(
              model: model,
              viewModel: viewModel,
              showInputControls: false,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          // One disclosure contains the existing report, including IPv4 details.
          // No decorative panel animation, including when Reduce Motion is active.
          GlassCard(
            child: ExpansionTile(
              key: const ValueKey('playground-reasoning'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: AppSpacing.md),
              expansionAnimationStyle: AnimationStyle.noAnimation,
              title: const Text('How it is calculated'),
              subtitle: const Text('Formula, substitution and explanation'),
              children: [
                if (report != null)
                  CalculationResultDetails(result: report)
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SelectableText(viewModel.mode.formula),
                      const SizedBox(height: AppSpacing.md),
                      Text(viewModel.definition.explanation),
                    ],
                  ),
              ],
            ),
          ),
          if (viewModel.definition.assumptions.isNotEmpty ||
              viewModel.mode.assumptions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            EngineeringContextCard(
              definition: viewModel.definition,
              mode: viewModel.mode,
            ),
          ],
        ],
      );
      return LayoutBuilder(
        builder: (context, constraints) {
          // Large text needs a full-width column even on a small tablet.
          final twoColumns =
              constraints.maxWidth >= 900 &&
              MediaQuery.textScalerOf(context).scale(16) <= 24;
          if (twoColumns) {
            return Row(
              key: const ValueKey('playground-two-columns'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: inputs),
                const SizedBox(width: AppSpacing.lg),
                Expanded(flex: 5, child: outputs),
              ],
            );
          }
          return Column(
            key: const ValueKey('playground-one-column'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              inputs,
              const SizedBox(height: AppSpacing.lg),
              outputs,
            ],
          );
        },
      );
    },
  );
}
