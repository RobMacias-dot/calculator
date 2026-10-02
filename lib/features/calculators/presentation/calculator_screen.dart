import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/glass_card.dart';
import '../domain/calculator_definition.dart';
import 'calculator_mode_selector.dart';
import 'calculator_input_field.dart';
import 'calculator_view_model.dart';
import 'result_card.dart';
import 'engineering_context_card.dart';
import 'favorite_button.dart';
import 'visual_learning/visual_learning_sheet.dart';
import '../../preferences/preferences_controller.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    required this.definition,
    required this.onBack,
    required this.preferences,
    this.onExplore,
  });
  final CalculatorDefinition definition;
  final VoidCallback onBack;
  final PreferencesController preferences;
  final ValueChanged<CalculatorViewModel>? onExplore;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final CalculatorViewModel _viewModel;
  final _scroll = ScrollController();
  final _resultKey = GlobalKey();
  final _issueKey = GlobalKey();
  final _fieldKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _viewModel = CalculatorViewModel(widget.definition);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.preferences.recordOpened(widget.definition.id);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    _viewModel.calculate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final resultContext = _resultKey.currentContext;
      if (resultContext != null && _viewModel.result != null) {
        unawaited(Scrollable.ensureVisible(resultContext));
      } else if (_viewModel.issues.isNotEmpty) {
        final fieldId = _viewModel.issues.first.fieldId;
        final issueContext =
            _fieldKeys[fieldId]?.currentContext ?? _issueKey.currentContext;
        if (issueContext != null) {
          unawaited(Scrollable.ensureVisible(issueContext));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) {
      final theme = Theme.of(context);
      return SingleChildScrollView(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                FavoriteButton(
                  definition: widget.definition,
                  preferences: widget.preferences,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(widget.definition.name, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.definition.description,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.definition.modes.length > 1) ...[
                    CalculatorModeSelector(viewModel: _viewModel),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Text('Inputs', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_viewModel.mode.inputHint),
                  const SizedBox(height: AppSpacing.md),
                  for (final input in _viewModel.inputs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: CalculatorInputField(
                        key: _fieldKeys.putIfAbsent(input.id, GlobalKey.new),
                        input: input,
                        viewModel: _viewModel,
                      ),
                    ),
                  if (_viewModel.status == CalculationStatus.invalid)
                    Padding(
                      key: _issueKey,
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _viewModel.generalIssues.isEmpty
                              ? 'Check the highlighted inputs.'
                              : _viewModel.generalIssues
                                    .map((issue) => issue.message)
                                    .join('\n'),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ),
                  if (_viewModel.hasResistorList) ...[
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _viewModel.addResistor,
                          icon: const Icon(Icons.add),
                          label: const Text('Add resistor'),
                        ),
                        TextButton.icon(
                          onPressed: _viewModel.inputs.length > 2
                              ? _viewModel.removeResistor
                              : null,
                          icon: const Icon(Icons.remove),
                          label: const Text('Remove last resistor'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  FilledButton(
                    onPressed: _calculate,
                    child: const Text('Calculate'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      _viewModel.reset();
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_viewModel.result case final result?)
              ResultCard(
                key: _resultKey,
                result: result,
                calculatorName: widget.definition.name,
              )
            else
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Formula', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    SelectableText(_viewModel.mode.formula),
                    const SizedBox(height: AppSpacing.md),
                    Text(widget.definition.explanation),
                  ],
                ),
              ),
            if (widget.definition.supportsVisualLearning) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _viewModel.result?.context == null
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        unawaited(showVisualLearning(context, _viewModel));
                      },
                icon: const Icon(Icons.insights_rounded),
                label: const Text('Learn visually'),
              ),
              if (_viewModel.result == null)
                const Text('Calculate with valid inputs to explore visually.'),
            ],
            if (widget.definition.supportsPlayground &&
                widget.onExplore != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  widget.onExplore!(_viewModel);
                },
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Explore interactively'),
              ),
            ],
            if (widget.definition.assumptions.isNotEmpty ||
                _viewModel.mode.assumptions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              EngineeringContextCard(
                definition: widget.definition,
                mode: _viewModel.mode,
              ),
            ],
          ],
        ),
      );
    },
  );
}
