import 'package:flutter/material.dart';

import '../calculator_view_model.dart';
import 'visual_models.dart';
import 'divider_visual.dart';
import 'ideal_gas_visual.dart';
import 'newton_visual.dart';
import 'torque_visual.dart';
import 'bernoulli_visual.dart';
import 'reynolds_visual.dart';
import 'subnet_visual.dart';
import 'vector_visual.dart';

/// Existing renderer selection shared by the sheet and Playground. Capabilities
/// remain on CalculatorDefinition; this widget does not decide availability.
class VisualModelView extends StatelessWidget {
  const VisualModelView({
    super.key,
    required this.model,
    required this.viewModel,
    this.showInputControls = true,
  });
  final VisualModel model;
  final CalculatorViewModel viewModel;
  final bool showInputControls;
  @override
  Widget build(BuildContext context) {
    final model = this.model;
    return switch (model) {
      IdealGasVisualizationModel() => IdealGasVisual(
        showInputControls: showInputControls,
        model: model,
        viewModel: viewModel,
      ),
      NewtonVisualModel() => NewtonVisual(model: model, viewModel: viewModel),
      TorqueVisualModel() => TorqueVisual(model: model, viewModel: viewModel),
      BernoulliVisualModel() => BernoulliVisual(
        model: model,
        viewModel: viewModel,
      ),
      DividerVisualModel() => DividerVisual(
        showInputControls: showInputControls,
        model: model,
        viewModel: viewModel,
      ),
      VectorVisualModel() => VectorVisual(model: model, viewModel: viewModel),
      ReynoldsVisualModel() => ReynoldsVisual(
        model: model,
        viewModel: viewModel,
      ),
      SubnetVisualModel() => SubnetVisual(
        showInputControls: showInputControls,
        model: model,
        viewModel: viewModel,
      ),
    };
  }
}
