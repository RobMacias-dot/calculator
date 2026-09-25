import 'package:flutter/material.dart';

import '../../preferences/preferences_controller.dart';
import '../domain/calculator_definition.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.definition,
    required this.preferences,
  });
  final CalculatorDefinition definition;
  final PreferencesController preferences;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) {
      final selected = preferences.isFavorite(definition.id);
      return IconButton(
        isSelected: selected,
        tooltip:
            '${selected ? 'Remove' : 'Add'} ${definition.name} ${selected ? 'from' : 'to'} favorites',
        onPressed: () => preferences.setFavorite(definition.id, !selected),
        icon: const Icon(Icons.star_border_rounded),
        selectedIcon: Icon(
          Icons.star_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    },
  );
}
