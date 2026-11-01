import 'package:flutter/material.dart';
import '../data/food_item.dart';
import 'widgets/gl_badge.dart';

class FoodDetailPanel extends StatelessWidget {
  final FoodItem food;

  const FoodDetailPanel({super.key, required this.food});

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
