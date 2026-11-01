import 'package:flutter/material.dart';
import '../../data/consumption_entry.dart';

class LogEntryTile extends StatelessWidget {
  final ConsumptionEntry entry;
  final VoidCallback onDelete;

  const LogEntryTile({super.key, required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final portionStr = entry.portions == entry.portions.truncateToDouble()
        ? entry.portions.toInt().toString()
        : entry.portions.toStringAsFixed(1);
    final gl = entry.glContribution;
    final glStr = gl == gl.truncateToDouble()
        ? gl.toInt().toString()
        : gl.toStringAsFixed(1);

    return ListTile(
      dense: true,
      title: Text('${portionStr}x ${entry.foodName}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$glStr GL', style: Theme.of(context).textTheme.bodySmall),
              Text('${entry.calorieContribution} kcal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Remove',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
