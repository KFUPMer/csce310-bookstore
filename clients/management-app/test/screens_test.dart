import 'dart:io';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_app/main.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

/// The screens, driven the way a manager uses them, with stand-ins for the
/// three services (no server needed).
void main() {
  late ManagerServices services;
  late List<String> opened;

  Future<void> start(WidgetTester tester, {String role = 'MANAGER', Size size = const Size(1440, 960)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    opened = [];
    services = fakeServices(role: role, opened: opened);
    await tester.pumpWidget(ManagerApp(services: services));
    await tester.pumpAndSettle();
  }

  Future<void> logIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'manager1');
    await tester.enterText(find.byType(TextField).at(1), 'right-password');
    await tester.tap(find.widgetWithText(AppButton, 'Log in'));
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) => tester.pumpAndSettle(const Duration(seconds: 7));

  Finder chipOf(int orderId) => find.descendant(of: find.bySemanticsLabel(RegExp('^Order $orderId by')), matching: find.byType(StatusChip));

  String chipLabel(WidgetTester tester, int orderId) => tester.widget<StatusChip>(chipOf(orderId)).label;

  testWidgets('a customer account is refused: this app is for managers', (tester) async {
    await start(tester, role: 'CUSTOMER');
    await logIn(tester);
    expect(find.text('This app is for managers. Customers log in to the customer app.'), findsOneWidget);
    expect(services.session.isLoggedIn, isFalse);
  });

  testWidgets('a manager sees every order, newest first, and how many wait for payment', (tester) async {
    await start(tester);
    await logIn(tester);
    expect(find.text('Orders'), findsWidgets);
    expect(find.text('3 orders, 2 waiting for payment. Newest first.'), findsOneWidget);
    final rows = tester.widgetList<Semantics>(find.bySemanticsLabel(RegExp(r'^Order \d+ by'))).map((s) => s.properties.label).toList();
    expect(rows.map((l) => l!.split(' ')[1]), ['1044', '1043', '1042']);
    await finish(tester);
  });

  testWidgets('marking an order as paid changes it at once, and Undo puts it back', (tester) async {
    await start(tester);
    await logIn(tester);
    await tester.tap(find.descendant(of: find.bySemanticsLabel(RegExp('^Order 1044 by')), matching: find.widgetWithText(AppButton, 'Mark as paid')));
    await tester.pumpAndSettle();
    expect(chipLabel(tester, 1044), 'Paid');
    expect(find.text('Order 1044 marked as paid'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Undo'));
    await tester.pumpAndSettle();
    expect(chipLabel(tester, 1044), 'Pending');
    await finish(tester);
  });

  testWidgets('the Pending filter shows only the orders waiting for payment', (tester) async {
    await start(tester);
    await logIn(tester);
    await tester.tap(find.bySemanticsLabel('Pending, 2'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('^Order 1043 by')), findsNothing);
    expect(find.bySemanticsLabel(RegExp('^Order 1044 by')), findsOneWidget);
    await finish(tester);
  });

  testWidgets('opening an order shows its bill; it can be marked as paid and printed there', (tester) async {
    await start(tester);
    await logIn(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Order 1044 by')));
    await tester.pumpAndSettle();
    Finder inDialog(Finder f) => find.descendant(of: find.byType(Dialog), matching: f);
    expect(inDialog(find.text('Order 1044')), findsOneWidget);
    expect(inDialog(find.text('Java Concurrency in Practice')), findsOneWidget);
    expect(inDialog(find.text('alice@example.com')), findsOneWidget);
    expect(inDialog(find.text('\$103.00')), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.widgetWithText(AppButton, 'Mark as paid')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(Dialog), matching: find.widgetWithText(AppButton, 'Mark as pending')), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(AppButton, 'Print bill'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(opened.single, endsWith('bookstore-bill-1044.html'));
    expect(File(opened.single).readAsStringSync(), contains('Bill 1044'));

    await tester.tap(find.byTooltip('Close (Esc)'));
    await tester.pumpAndSettle();
    expect(chipLabel(tester, 1044), 'Paid', reason: 'the list follows what was done in the order');
    await finish(tester);
  });

  Future<void> openBooks(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Books'));
    await tester.pumpAndSettle();
  }

  testWidgets('adding a book checks every field, then saves it into the list', (tester) async {
    await start(tester);
    await logIn(tester);
    await openBooks(tester);
    expect(find.text('15 books. Click a book to change it, including its copies.'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Add book'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Add book').last);
    await tester.pumpAndSettle();
    expect(find.text('Enter the title'), findsOneWidget);
    expect(find.text('Enter the price'), findsOneWidget);

    final fields = find.descendant(of: find.byType(Dialog), matching: find.byType(TextField));
    await tester.enterText(fields.at(0), 'Clean Architecture');
    await tester.enterText(fields.at(1), 'Robert C. Martin');
    await tester.enterText(fields.at(2), '42');
    await tester.enterText(fields.at(3), '3');
    await tester.pump();
    expect(find.text('Enter the title'), findsNothing, reason: 'a fixed problem disappears as the manager types');
    await tester.tap(find.widgetWithText(AppButton, 'Add book').last);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Added: Clean Architecture'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Clean Architecture by Robert C\. Martin, \$42\.00, 3 copies')), findsOneWidget);
    await finish(tester);
  });

  testWidgets('editing a book changes its number of copies', (tester) async {
    await start(tester);
    await logIn(tester);
    await openBooks(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Clean Code by')));
    await tester.pumpAndSettle();
    expect(find.text('Edit book'), findsOneWidget);
    final copies = find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)).at(3);
    await tester.enterText(copies, '0');
    await tester.tap(find.widgetWithText(AppButton, 'Save changes'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^Clean Code by Robert C\. Martin, \$40\.00, None left')), findsOneWidget);
    await finish(tester);
  });

  testWidgets('both tabs and both dialogs fit a small 1024 x 700 window without anything overflowing', (tester) async {
    await start(tester, size: const Size(1024, 700));
    await logIn(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Order 1044 by')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close (Esc)'));
    await tester.pumpAndSettle();
    await openBooks(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Add book'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Add book').last);
    await tester.pumpAndSettle();
    expect(find.text('Enter the title'), findsOneWidget); // an overflow anywhere on the way fails the test
    await finish(tester);
  });

  testWidgets('when the session ends, the app goes back to log in and says why', (tester) async {
    await start(tester);
    await logIn(tester);
    services.session.clear(message: 'Your session has ended. Please log in again.');
    await tester.pumpAndSettle();
    expect(find.text('Your session has ended. Please log in again.'), findsOneWidget);
    await finish(tester);
  });
}
