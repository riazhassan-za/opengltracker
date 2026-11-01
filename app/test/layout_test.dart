import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengltracker/ui/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tabs = ['Log', 'Foods', 'Dashboard', 'Help', 'About'];

String _todayKey() {
  final d = DateTime.now();
  return 'log_${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

Future<void> _pumpApp(WidgetTester t, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(const ProviderScope(child: OpenGlTrackerApp()));
}

// Real fonts: the default test font draws every glyph as a 14px square, which
// would make text widths (and therefore truncation) meaningless.
Future<void> _loadFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  if (!File('$dir/roboto-regular.ttf').existsSync()) {
    fail('Material fonts not found in $dir. Run `flutter precache --universal`.');
  }
  Future<ByteData> read(String f) async =>
      ByteData.sublistView(File('$dir/$f').readAsBytesSync());
  await (FontLoader('Roboto')
        ..addFont(read('roboto-regular.ttf'))
        ..addFont(read('roboto-medium.ttf'))
        ..addFont(read('roboto-bold.ttf')))
      .load();
}

void main() {
  setUpAll(_loadFonts);

  for (final width in [360.0, 412.0, 1280.0]) {
    testWidgets('tab labels are not truncated at ${width}px', (t) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpApp(t, Size(width, 800));
      for (final label in _tabs) {
        final p = t.renderObject<RenderParagraph>(
            find.descendant(of: find.byType(Tab), matching: find.text(label)));
        expect(p.size.width, greaterThanOrEqualTo(p.getMaxIntrinsicWidth(double.infinity)),
            reason: '"$label" is cut off');
      }
    });
  }

  testWidgets('dashboard y-axis ends on a whole step', (t) async {
    // One day at GL 64: the axis top would be 80 * 1.2 = 96, which used to be
    // drawn as an extra "96" label on top of "95".
    SharedPreferences.setMockInitialValues({
      _todayKey(): jsonEncode([
        {
          'id': 'a',
          'foodName': 'Test',
          'foodGl': 64.0,
          'foodCalories': 500,
          'foodServing': '1',
          'portions': 1.0,
          'category': 'lunch',
        }
      ]),
    });
    await _pumpApp(t, const Size(412, 880));
    await t.tap(find.widgetWithText(Tab, 'Dashboard'));
    await t.pumpAndSettle();

    expect(find.text('96'), findsNothing);
    expect(find.text('95'), findsNothing);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });
}
