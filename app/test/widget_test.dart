import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengltracker/ui/app.dart';

void main() {
  testWidgets('App shell renders both tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: OpenGlTrackerApp()),
    );
    expect(find.text('Foods'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
  });
}
