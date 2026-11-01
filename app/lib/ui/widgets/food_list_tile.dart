import 'package:flutter/material.dart';
import '../../data/food_item.dart';
import 'gl_badge.dart';

class FoodListTile extends StatelessWidget {
  final FoodItem food;
  final bool selected;
  final VoidCallback onTap;
  final int? number;

  const FoodListTile({
    super.key,
    required this.food,
    required this.onTap,
    this.selected = false,
    this.number,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
      leading: number != null
          ? SizedBox(
              width: 32,
              child: Text(
                '$number.',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          : null,
      title: Text(food.name),
      subtitle: Text(
        'GI ${food.gi}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: GlBadge(gl: food.gl, glClass: food.glClass),
      onTap: onTap,
    );
  }
}
