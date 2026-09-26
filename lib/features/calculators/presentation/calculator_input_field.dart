import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../domain/calculator_definition.dart';
import 'calculator_view_model.dart';

class CalculatorInputField extends StatefulWidget {
  const CalculatorInputField({
    super.key,
    required this.input,
    required this.viewModel,
    this.live = false,
  });
  final CalculatorInput input;
  final CalculatorViewModel viewModel;
  final bool live;

  @override
  State<CalculatorInputField> createState() => _CalculatorInputFieldState();
}

class _CalculatorInputFieldState extends State<CalculatorInputField> {
  TextEditingController? _editor;
  CalculatorInput get input => widget.input;
  CalculatorViewModel get viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    if (widget.live) {
      _editor = TextEditingController(text: viewModel.valueFor(input.id));
    }
  }

  @override
  void didUpdateWidget(CalculatorInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This is only an editor buffer. The ViewModel is authoritative; retain the
    // caret/composing range when the text already matches during live typing.
    if (widget.live) {
      _editor ??= TextEditingController();
      final text = viewModel.valueFor(input.id);
      if (_editor!.text != text) {
        _editor!.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _editor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        key: ValueKey(
          'input-${input.id}-${widget.live ? 'live' : viewModel.revision}',
        ),
        controller: widget.live ? _editor : null,
        initialValue: widget.live ? null : viewModel.valueFor(input.id),
        onChanged: (value) => widget.live
            ? viewModel.updateAndCalculate(input.id, value)
            : viewModel.setValue(input.id, value),
        keyboardType:
            input.kind == CalculatorInputKind.ipv4 ||
                input.kind == CalculatorInputKind.text
            ? TextInputType.text
            : TextInputType.numberWithOptions(
                decimal: input.kind == CalculatorInputKind.decimal,
                signed: true,
              ),
        textInputAction: TextInputAction.next,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: input.label,
          errorText: viewModel.errorFor(input.id),
          errorMaxLines: 4,
        ),
      ),
      if (input.units.length > 1) ...[
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<EngineeringUnit>(
          key: ValueKey(
            'unit-${input.id}-${widget.live ? 'live' : viewModel.revision}',
          ),
          initialValue: viewModel.unitFor(input.id),
          isExpanded: true,
          itemHeight: null,
          decoration: InputDecoration(labelText: '${input.label} unit'),
          items: [
            for (final unit in input.units)
              DropdownMenuItem(value: unit, child: Text(unit.symbol)),
          ],
          onChanged: (unit) {
            if (unit != null) {
              viewModel.setUnit(input.id, unit, recalculate: widget.live);
            }
          },
        ),
      ] else if (input.units.isNotEmpty && input.units.single.symbol.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            'Unit: ${input.units.single.symbol}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ],
  );
}
