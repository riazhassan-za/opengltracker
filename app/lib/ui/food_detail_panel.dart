import 'package:flutter/material.dart';
import '../data/food_item.dart';
import 'widgets/gl_badge.dart';

class FoodDetailPanel extends StatelessWidget {
  final FoodItem food;

  /// Shown only for the user's own foods; the bundled ones are read-only.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FoodDetailPanel(
      {super.key, required this.food, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(food.name, style: textTheme.titleLarge),
            const SizedBox(height: 12),
            GlBadge(gl: food.gl, glClass: food.glClass, large: true),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _Row('Glycemic Index (GI)', '${food.gi}'),
            const SizedBox(height: 8),
            _Row('Glycemic Load (GL)', food.gl.toStringAsFixed(1)),
            const SizedBox(height: 8),
            _Row('Serving Size', food.serving),
            if (food.carbs != null) ...[
              const SizedBox(height: 8),
              _Row('Carbohydrate', '${food.carbs} g'),
            ],
            if (food.custom) ...[
              const SizedBox(height: 20),
              Row(children: [
                Text('My food', style: textTheme.labelMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
