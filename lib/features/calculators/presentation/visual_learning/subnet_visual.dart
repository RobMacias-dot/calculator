import 'package:flutter/material.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../../domain/engines/ipv4_address.dart';
import '../calculator_view_model.dart';
import 'visual_models.dart';

class SubnetVisual extends StatelessWidget {
  const SubnetVisual({
    super.key,
    required this.model,
    required this.viewModel,
    this.showInputControls = true,
  });
  final SubnetVisualModel model;
  final CalculatorViewModel viewModel;
  final bool showInputControls;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final subnet = model.inputs.subnet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          image: true,
          label: model.summary,
          child: ExcludeSemantics(
            child: Column(
              children: [
                for (var octet = 0; octet < 4; octet++) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Octet ${octet + 1}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      for (var bit = 0; bit < 8; bit++)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(1),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: octet * 8 + bit < subnet.prefix
                                  ? colors.primaryContainer
                                  : colors.surfaceContainerHighest,
                              border: Border.all(
                                color: octet * 8 + bit < subnet.prefix
                                    ? colors.primary
                                    : colors.outline,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              model.bits[octet * 8 + bit],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: octet * 8 + bit < subnet.prefix
                                    ? colors.onPrimaryContainer
                                    : colors.onSurface,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
        Text(
          '${subnet.prefix} network bits (accent) · ${32 - subnet.prefix} host bits (neutral)',
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${subnet.totalAddresses} addresses',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(value: model.blockScale, minHeight: 8),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Block-size scale: logarithmic, from 1 to 4,294,967,296 addresses. '
          'The bar does not draw individual addresses; one more prefix bit halves the block.',
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Network: ${model.network}\nLast address: ${model.lastAddress}\n'
          'Usable addresses: ${subnet.usableHosts}',
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(model.report.explanation),
        if (showInputControls) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'CIDR prefix: /${subnet.prefix}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Semantics(
            label: 'CIDR prefix',
            child: Slider(
              key: const ValueKey('visual-control-prefix'),
              min: 0,
              max: 32,
              divisions: 32,
              value: subnet.prefix.toDouble(),
              semanticFormatterCallback: (value) => '/${value.round()}',
              onChanged: (value) => viewModel.updateAndCalculate(
                Ipv4Input.prefix.name,
                value.round().toString(),
              ),
            ),
          ),
          const Text(
            'Explore /0 through /32. The IPv4 address stays unchanged.',
          ),
        ],
      ],
    );
  }
}
