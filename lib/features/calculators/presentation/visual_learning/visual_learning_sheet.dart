import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../calculator_view_model.dart';
import 'divider_visual.dart';
import 'reynolds_visual.dart';
import 'subnet_visual.dart';
import 'vector_visual.dart';
import 'visual_models.dart';
import 'visual_motion.dart';

Future<void> showVisualLearning(
  BuildContext context,
  CalculatorViewModel viewModel,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 760),
  sheetAnimationStyle: reduceVisualMotion(context)
      ? AnimationStyle.noAnimation
      : null,
  builder: (_) => VisualLearningSheet(viewModel: viewModel),
);

/// Lazy, dedicated surface borrowing the calculator's state. The owning screen
/// remains mounted beneath the modal and owns/disposes the ViewModel.
class VisualLearningSheet extends StatelessWidget {
  const VisualLearningSheet({super.key, required this.viewModel});
  final CalculatorViewModel viewModel;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .92,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.sm,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Learn visually',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close visualization',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) {
                final result = viewModel.result;
                final model = result == null ? null : mapVisualModel(result);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      viewModel.definition.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Explore using the same calculation. Changes also update the main form.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (model == null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          viewModel.issues.isEmpty
                              ? 'Calculate with valid inputs in the main form to continue.'
                              : viewModel.issues
                                    .map((issue) => issue.message)
                                    .join('\n'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Return to inputs'),
                      ),
                    ] else
                      switch (model) {
                        DividerVisualModel() => DividerVisual(
                          model: model,
                          viewModel: viewModel,
                        ),
                        VectorVisualModel() => VectorVisual(
                          model: model,
                          viewModel: viewModel,
                        ),
                        ReynoldsVisualModel() => ReynoldsVisual(
                          model: model,
                          viewModel: viewModel,
                        ),
                        SubnetVisualModel() => SubnetVisual(
                          model: model,
                          viewModel: viewModel,
                        ),
                      },
                    const SizedBox(height: AppSpacing.lg),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
