import 'dart:io';
import 'dart:ui' as ui;

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:customer_app/main.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

/// Draws each screen with the real typefaces and saves it as a PNG, so the
/// look can be checked and shown in the style guide.
///
/// These are the app's real widgets, drawn by Flutter, on the sample books and
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

  const ui = '../bookstore-ui/fonts';
  await family('packages/bookstore_ui/Inter', ['$ui/Inter-Regular.ttf', '$ui/Inter-Medium.ttf', '$ui/Inter-SemiBold.ttf', '$ui/Inter-Bold.ttf']);
  await family('packages/bookstore_ui/SourceSerif4', ['$ui/SourceSerif4-Regular.ttf', '$ui/SourceSerif4-Semibold.ttf']);
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
    await tester.pump(const Duration(milliseconds: 600)); // let animations finish (toasts stay)
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(frame));
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<AppServices> start(WidgetTester tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final services = fakeServices();
    await tester.pumpWidget(
      RepaintBoundary(
        key: frame,
        child: CustomerApp(services: services),
      ),
    );
    await tester.pumpAndSettle();
    return services;
  }

  Future<void> logIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'alice');
    await tester.enterText(find.byType(TextField).at(1), 'right-password');
    await tester.tap(find.widgetWithText(AppButton, 'Log in'));
    await tester.pumpAndSettle();
  }

  Future<void> toggleDark(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
  }

  testWidgets('log in and create an account', (tester) async {
    await start(tester);
    await shoot(tester, 'customer-login-light');
    await tester.enterText(find.byType(TextField).at(0), 'alice');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.widgetWithText(AppButton, 'Log in'));
    await tester.pumpAndSettle();
    await toggleDark(tester);
    await shoot(tester, 'customer-login-dark-error');

    await tester.tap(find.widgetWithText(AppButton, 'Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'al');
    await tester.enterText(find.byType(TextField).at(1), 'alice@example');
    await tester.enterText(find.byType(TextField).at(2), 'longenough');
    await tester.enterText(find.byType(TextField).at(3), 'longenouhg');
    await tester.tap(find.widgetWithText(AppButton, 'Create account'));
    await tester.pumpAndSettle();
    await shoot(tester, 'customer-register-dark-errors');
    await tester.pumpAndSettle(const Duration(seconds: 7));
  });

  testWidgets('search, order, and bill', (tester) async {
    final services = await start(tester);
    await logIn(tester);
    await shoot(tester, 'customer-search-light');

    await tester.tap(find.bySemanticsLabel(RegExp('^Java Concurrency in Practice by')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Rent for 7 days'));
    await tester.pumpAndSettle();
    await shoot(tester, 'customer-search-light-detail');

    await tester.tap(find.bySemanticsLabel(RegExp('^Clean Code by')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Buy'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Database System Concepts by')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Buy'));
    await tester.pumpAndSettle(const Duration(seconds: 7));

    await tester.tap(find.widgetWithText(AppButton, 'Your order (3)'));
    await tester.pumpAndSettle();
    await shoot(tester, 'customer-order-light');

    await tester.tap(find.widgetWithText(AppButton, 'Place order'));
    await tester.pumpAndSettle();
    await shoot(tester, 'customer-bill-light');
    expect(services.draft.isEmpty, isTrue);

    await tester.tap(find.widgetWithText(AppButton, 'Continue shopping'));
    await tester.pumpAndSettle();
    await toggleDark(tester);
    await tester.enterText(find.byType(TextField).first, 'java');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('Show as a list'));
    await tester.pumpAndSettle();
    await shoot(tester, 'customer-search-dark-list');
    await tester.pumpAndSettle(const Duration(seconds: 7));
  });

  testWidgets('account page and the pretend checkout', (tester) async {
    final services = await start(tester);
    PlacedItem item(String title, String author, ItemType type, double price, {DateTime? due}) =>
        PlacedItem(title: title, author: author, type: type, quantity: 1, unitPrice: price, dueBack: due);
    (services.orders as FakeOrders).placed.addAll([
      Order(
        id: 1031,
        username: 'alice',
        createdAt: DateTime(2026, 11, 8, 16, 20),
        paymentStatus: Order.paid,
        total: 5.5,
        items: [item('Refactoring', 'Martin Fowler', ItemType.rent, 5.5, due: DateTime(2026, 11, 15))],
      ),
      Order(
        id: 1042,
        username: 'alice',
        createdAt: DateTime(2026, 11, 17, 10, 5),
        paymentStatus: Order.pending,
        total: 103,
        items: [
          item('Java Concurrency in Practice', 'Brian Goetz', ItemType.rent, 8, due: DateTime(2026, 11, 24)),
          item('Clean Code', 'Robert C. Martin', ItemType.buy, 40),
          item('Database System Concepts', 'Abraham Silberschatz', ItemType.buy, 55),
        ],
      ),
    ]);
    await logIn(tester);
    await tester.tap(find.byTooltip('Your account'));
    await tester.pumpAndSettle();
    await shoot(tester, 'customer-account-light');

    await tester.tap(find.widgetWithText(AppButton, 'Pay'));
    await tester.pumpAndSettle();
    await shoot(tester, 'customer-pay-light');
    await tester.tap(find.widgetWithText(AppButton, 'Pay \$103.00'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Dark mode'));
    await tester.pumpAndSettle();
    await shoot(tester, 'customer-account-dark-paid');
    await tester.pumpAndSettle(const Duration(seconds: 7));
  });
}
