import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Definitions', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Glycemic Index (GI)', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Ranks how quickly a carbohydrate-containing food raises blood glucose levels compared to pure glucose (score of 100).',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _ScaleRow(label: 'Low GI', value: '55 or less', color: Colors.green),
                _ScaleRow(label: 'Medium GI', value: '56 to 69', color: Colors.orange),
                _ScaleRow(label: 'High GI', value: '70 or more', color: Colors.red),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Glycemic Load (GL)', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Factors in the portion size of a typical serving alongside its GI, offering a more practical view of a food\'s real-world impact on blood sugar.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _ScaleRow(label: 'Low GL', value: '10 or less', color: Colors.green),
                _ScaleRow(label: 'Medium GL', value: '11 to 19', color: Colors.orange),
                _ScaleRow(label: 'High GL', value: '20 or more', color: Colors.red),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('GL Guidelines', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        _GuidelineCard(
          icon: Icons.cookie_outlined,
          title: 'Per Snack',
          target: 'GL of 10 or less',
          body:
              'For example, 3 cups of plain, air-popped popcorn has a GL of 6, making it an excellent snack.',
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _GuidelineCard(
          icon: Icons.restaurant_outlined,
          title: 'Per Meal',
          target: 'GL of 20 or less',
          body:
              'Ideally closer to 11–15 if you are actively working on insulin sensitivity or weight management. '
              'Try to avoid letting a single meal cross a GL of 25 to 30.',
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _GuidelineCard(
          icon: Icons.today_outlined,
          title: 'Per Day',
          target: 'Total daily GL under 100',
          body:
              'Aim for 60–80 for stricter blood sugar control.',
          color: Colors.red,
        ),
      ],
    );
  }
}

class _ScaleRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScaleRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _GuidelineCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String target;
  final String body;
  final Color color;

  const _GuidelineCard({
    required this.icon,
    required this.title,
    required this.target,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Target: $target',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
