import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:customer_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

/// The screens, driven the way a customer uses them, with stand-ins for the
/// three services (no server needed).

const books = [
  Book(id: 'aaaaaaaaaaaaaaaaaaaaaaaa', title: 'Clean Code', author: 'Robert C. Martin', price: 40, copiesAvailable: 4),
  Book(id: 'bbbbbbbbbbbbbbbbbbbbbbbb', title: 'Effective Java', author: 'Joshua Bloch', price: 50, copiesAvailable: 2),
];

void main() {
  late AppServices services;

  FakeOrders orders() => services.orders as FakeOrders;

  Future<void> start(WidgetTester tester, {String role = 'CUSTOMER'}) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    services = fakeServices(role: role, books: books);
    await tester.pumpWidget(CustomerApp(services: services));
    await tester.pumpAndSettle();
  }

  Future<void> logIn(WidgetTester tester, {String password = 'right-password'}) async {
    await tester.enterText(find.byType(TextField).at(0), 'alice');
    await tester.enterText(find.byType(TextField).at(1), password);
    await tester.tap(find.widgetWithText(AppButton, 'Log in'));
    await tester.pumpAndSettle();
  }

  /// Lets every toast and typing timer run out, so none is left when the test ends.
  Future<void> finish(WidgetTester tester) => tester.pumpAndSettle(const Duration(seconds: 7));

  Future<void> addCleanCode(WidgetTester tester, {String button = 'Buy'}) async {
    await tester.tap(find.bySemanticsLabel(RegExp('^Clean Code by')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, button));
    await tester.pumpAndSettle();
  }

  testWidgets('every screen fits a small 1024 x 700 window without anything overflowing', (tester) async {
    await start(tester);
    tester.view.physicalSize = const Size(1024, 700);
    await tester.pumpAndSettle();
    await logIn(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Clean Code by')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Rent for 7 days'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show as a list'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Your order (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Place order'));
    await tester.pumpAndSettle();
    expect(find.text('Order 1042 placed'), findsOneWidget); // an overflow anywhere on the way fails the test
    await tester.tap(find.widgetWithText(AppButton, 'Pay now'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close (Esc)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to search (Esc)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Your account'));
    await tester.pumpAndSettle();
    expect(find.text('Your account'), findsWidgets);
    await finish(tester);
  });

  Future<void> placeRental(WidgetTester tester) async {
    await addCleanCode(tester, button: 'Rent for 7 days');
    await tester.tap(find.widgetWithText(AppButton, 'Your order (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Place order'));
    await tester.pumpAndSettle();
  }

  testWidgets('the customer pays for the order just placed with the pretend checkout', (tester) async {
    await start(tester);
    await logIn(tester);
    await placeRental(tester);
    expect(find.text('Payment pending'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Pay now'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No card is needed'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Pay \$4.00'));
    await tester.pumpAndSettle();
    expect(find.text('Order 1042 is paid. Thank you!'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Pay now'), findsNothing, reason: 'an order is paid once');
    expect(orders().paid, [1042]);
    await finish(tester);
  });

  testWidgets('the account page shows the profile, the rentals due back, and the orders, and pays one', (tester) async {
    await start(tester);
    await logIn(tester);
    await placeRental(tester);
    await tester.tap(find.byTooltip('Back to search (Esc)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Your account'));
    await tester.pumpAndSettle();
    expect(find.text('alice@example.com'), findsOneWidget);
    expect(find.text('Due back in 7 days'), findsOneWidget);
    expect(find.text('Order 1042'), findsOneWidget);
    expect(find.text('Payment pending'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Pay'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Pay \$4.00'));
    await tester.pumpAndSettle();
    expect(find.text('Paid'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('preferences are remembered for the customer\'s next log in', (tester) async {
    await start(tester);
    await logIn(tester);
    await tester.tap(find.byTooltip('Your account'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Dark mode'));
    await tester.tap(find.bySemanticsLabel('Open search as a list'));
    await tester.pumpAndSettle();
    expect(AppScope.of(tester.element(find.byType(Scaffold).last)).isDark, isTrue);

    await tester.tap(find.widgetWithText(AppButton, 'Log out'));
    await tester.pumpAndSettle();
    services.preferences.update(darkMode: false); // as if another customer had switched it back
    await logIn(tester);
    expect(services.preferences.darkMode, isTrue);
    expect(find.byWidgetPredicate((w) => w is AppIconButton && w.tooltip == 'Show as a list' && w.selected), findsOneWidget);
    await finish(tester);
  });

  testWidgets('empty fields are named before anything is sent', (tester) async {
    await start(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(services.session.isLoggedIn, isFalse);
  });

  testWidgets('a wrong password is said plainly and the customer stays on the login screen', (tester) async {
    await start(tester);
    await logIn(tester, password: 'wrong');
    expect(find.text('Wrong username or password'), findsOneWidget);
    expect(find.text('All books'), findsNothing);
  });

  testWidgets('logging in opens the search screen with the catalog', (tester) async {
    await start(tester);
    await logIn(tester);
    expect(find.text('All books'), findsOneWidget);
    expect(find.text('Clean Code'), findsWidgets); // the card, and the title printed on its cover
    expect(find.text('2 books. Search by title or author, or pick a cover.'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a manager is refused: placing orders is for customers', (tester) async {
    await start(tester, role: 'MANAGER');
    await logIn(tester);
    expect(find.text('This app is for customers. Managers log in to the management app.'), findsOneWidget);
    expect(services.session.isLoggedIn, isFalse);
  });

  testWidgets('registering checks every field, then returns to log in with the username filled in', (tester) async {
    await start(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a username'), findsOneWidget);
    expect(find.text('Enter your email address'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'newreader');
    await tester.enterText(fields.at(1), 'new@example.com');
    await tester.enterText(fields.at(2), 'long-enough');
    await tester.enterText(fields.at(3), 'long-enough');
    await tester.pump();
    expect(find.text('Choose a username'), findsNothing, reason: 'a fixed problem disappears as the customer types');
    await tester.tap(find.widgetWithText(AppButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Account created. Log in with your new password.'), findsOneWidget);
    expect(find.text('newreader'), findsOneWidget);
  });

  testWidgets('the open book closes when a new search no longer finds it', (tester) async {
    await start(tester);
    await logIn(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Clean Code by')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close (Esc)'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'bloch');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byTooltip('Close (Esc)'), findsNothing);
    await finish(tester);
  });

  testWidgets('a book is added, the order is placed, and the bill is shown', (tester) async {
    await start(tester);
    await logIn(tester);
    await addCleanCode(tester, button: 'Rent for 7 days');
    expect(find.textContaining('Added as a 7-day rental: Clean Code'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Your order (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Your order'), findsOneWidget);
    expect(find.text('\$4.00'), findsWidgets);

    await tester.tap(find.widgetWithText(AppButton, 'Place order'));
    await tester.pumpAndSettle();
    expect(find.text('Order 1042 placed'), findsOneWidget);
    expect(find.text('A copy of this bill is on its way to alice@example.com.'), findsOneWidget);
    expect(find.text('Rent (7 days)'), findsOneWidget);
    expect(services.draft.isEmpty, isTrue);
    await finish(tester);
  });

  testWidgets('if the order fails, the message is shown and the books stay in the order', (tester) async {
    await start(tester);
    await logIn(tester);
    await addCleanCode(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Your order (1)'));
    await tester.pumpAndSettle();

    orders().failure = const ApiException('"Clean Code" is not available', 409);
    await tester.tap(find.widgetWithText(AppButton, 'Place order'));
    await tester.pumpAndSettle();
    expect(find.text('"Clean Code" is not available. Remove it from the order and try again. Nothing was charged.'), findsOneWidget);
    expect(services.draft.length, 1);
    expect(find.text('Your order'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a removed book can be put back with Undo', (tester) async {
    await start(tester);
    await logIn(tester);
    await addCleanCode(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Your order (1)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove from order'));
    await tester.pumpAndSettle();
    expect(services.draft.isEmpty, isTrue);
    expect(find.text('Your order is empty'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Undo'));
    await tester.pumpAndSettle();
    expect(services.draft.length, 1);
    await finish(tester);
  });

  testWidgets('when a service says the session has ended, the app goes back to log in and says why', (tester) async {
    await start(tester);
    await logIn(tester);
    await addCleanCode(tester);
    services.session.clear(message: 'Your session has ended. Please log in again.');
    await tester.pumpAndSettle();
    expect(find.text('Log in'), findsWidgets);
    expect(find.text('Your session has ended. Please log in again.'), findsOneWidget);
    expect(services.draft.isEmpty, isTrue, reason: 'the next customer must not see this order');
    await finish(tester);
  });
}
