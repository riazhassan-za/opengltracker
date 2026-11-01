import 'package:flutter/material.dart';
import '../../data/food_item.dart';

class GlBadge extends StatelessWidget {
  final double gl;
  final GlClass glClass;
  final bool large;

  const GlBadge({
    super.key,
    required this.gl,
    required this.glClass,
    this.large = false,
  });

  Color _color() => switch (glClass) {
        GlClass.low => const Color(0xFF2E7D32),
        GlClass.medium => const Color(0xFFE65100),
        GlClass.high => const Color(0xFFC62828),
      };

  String _label() => switch (glClass) {
        GlClass.low => 'LOW',
        GlClass.medium => 'MED',
        GlClass.high => 'HIGH',
      };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final fontSize = large ? 14.0 : 11.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 7,
        vertical: large ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: large ? 10 : 7, color: color),
          const SizedBox(width: 4),
          Text(
            large ? '${_label()}  GL ${gl.toStringAsFixed(1)}' : 'GL ${gl.toStringAsFixed(1)}',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
