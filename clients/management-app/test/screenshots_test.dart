import 'dart:io';
import 'dart:ui' as ui;

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_app/main.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

/// Draws each screen with the real typefaces and saves it as a PNG, so the
/// look can be checked and shown in the style guide.
///
/// These are the app's real widgets, drawn by Flutter, on sample data and
/// stand-in services; not a capture of the running window. Skipped in the
/// normal test run:
///
///     set BOOKSTORE_SCREENSHOTS=1 && flutter test test/screenshots_test.dart
const _out = '../../docs/02-design/ui';
const _size = Size(1440, 900);

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  }

  const fonts = '../bookstore-ui/fonts';
  await family('packages/bookstore_ui/Inter', [
    '$fonts/Inter-Regular.ttf',
    '$fonts/Inter-Medium.ttf',
    '$fonts/Inter-SemiBold.ttf',
    '$fonts/Inter-Bold.ttf',
  ]);
  await family('packages/bookstore_ui/SourceSerif4', ['$fonts/SourceSerif4-Regular.ttf', '$fonts/SourceSerif4-Semibold.ttf']);
  final flutterRoot = File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path; // .../flutter
  await family('MaterialIcons', ['$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
}

void main() {
  if (Platform.environment['BOOKSTORE_SCREENSHOTS'] != '1') {
    test('screenshots', () {}, skip: 'Set BOOKSTORE_SCREENSHOTS=1 to draw them');
    return;
  }

  final frame = GlobalKey();

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 600));
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(frame));
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> start(WidgetTester tester) async {
    await useCachedCovers(tester);
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: frame,
        child: ManagerApp(services: fakeServices()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> logIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'manager1');
    await tester.enterText(find.byType(TextField).at(1), 'right-password');
    await tester.tap(find.widgetWithText(AppButton, 'Log in'));
    await tester.pumpAndSettle();
  }

  testWidgets('the management app', (tester) async {
    await start(tester);
    await shoot(tester, 'manager-login-light');
    await logIn(tester);
    await shoot(tester, 'manager-orders-light');

    await tester.tap(find.bySemanticsLabel(RegExp('^Order 1044 by')));
    await tester.pumpAndSettle();
    await shoot(tester, 'manager-order-bill-light');
    await tester.tap(find.byTooltip('Close (Esc)'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Books'));
    await tester.pumpAndSettle();
    await shoot(tester, 'manager-books-light');

    await tester.tap(find.bySemanticsLabel(RegExp('^Clean Code by'))); // near the top of the 27 books
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)).at(2), '');
    await tester.tap(find.widgetWithText(AppButton, 'Save changes'));
    await tester.pumpAndSettle();
    await shoot(tester, 'manager-book-form-light-error');
    await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Orders'));
    await tester.pumpAndSettle();
    await shoot(tester, 'manager-orders-dark');
    await tester.pumpAndSettle(const Duration(seconds: 7));
  });
}
