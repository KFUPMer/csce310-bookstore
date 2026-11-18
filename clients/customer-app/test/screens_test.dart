import 'dart:async';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:customer_app/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

/// The screens, driven the way a customer uses them, with stand-ins for the
/// three services (no server needed).

const books = [
  Book(id: 'aaaaaaaaaaaaaaaaaaaaaaaa', title: 'Clean Code', author: 'Robert C. Martin', price: 40, copiesAvailable: 4, category: 'Technology'),
  Book(id: 'bbbbbbbbbbbbbbbbbbbbbbbb', title: 'Effective Java', author: 'Joshua Bloch', price: 50, copiesAvailable: 2, category: 'Technology'),
  Book(id: 'cccccccccccccccccccccccc', title: 'The Great Gatsby', author: 'F. Scott Fitzgerald', price: 14, copiesAvailable: 4, category: 'Fiction'),
];

void main() {
  late AppServices services;

  FakeOrders orders() => services.orders as FakeOrders;
  FakeBooks fakeBooks() => services.books as FakeBooks;

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
    fakeBooks().addReview(books[0].id, 'bob', 3, 'Solid advice');
    tester.view.physicalSize = const Size(1024, 700);
    await tester.pumpAndSettle();
    await logIn(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Clean Code by')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(AppButton, 'Rent for 7 days'));
    await tester.tap(find.widgetWithText(AppButton, 'Rent for 7 days'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(AppButton, 'Write a review'));
    await tester.pumpAndSettle();
    expect(find.text('Solid advice'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Write a review'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('5 stars'));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
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
    expect(find.text('3 books. Search by title or author, or pick a cover.'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a shelf shows only its books, a search stays on it, and All shows every book again', (tester) async {
    await start(tester);
    await logIn(tester);
    await tester.tap(find.bySemanticsLabel('Fiction shelf'));
    await tester.pumpAndSettle();
    expect(find.text('1 book on this shelf. Search by title or author, or pick a cover.'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^The Great Gatsby by')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Clean Code by')), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'java');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('No books match "java" in Fiction'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Search every shelf'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('^Effective Java by')), findsOneWidget, reason: 'the same search, on every shelf');

    await tester.tap(find.bySemanticsLabel('All books'));
    await tester.pumpAndSettle();
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

  group('reviews', () {
    /// Scrolls the detail panel to [label]'s button and clicks it.
    Future<void> press(WidgetTester tester, String label) async {
      final button = find.widgetWithText(AppButton, label);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    Future<void> openCleanCode(WidgetTester tester) async {
      await start(tester);
      fakeBooks().addReview(books[0].id, 'bob', 3, 'Solid advice');
      await logIn(tester);
      await tester.tap(find.bySemanticsLabel(RegExp('^Clean Code by')));
      await tester.pumpAndSettle();
    }

    Finder reviewText() => find.descendant(of: find.byType(Dialog), matching: find.byType(TextField));

    Future<void> writeReview(WidgetTester tester, {int stars = 5, String text = 'Loved it'}) async {
      await press(tester, 'Write a review');
      await tester.tap(find.byTooltip(stars == 1 ? '1 star' : '$stars stars'));
      await tester.enterText(reviewText(), text);
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();
    }

    testWidgets("cards show a book's rating, and nothing for a book without reviews", (tester) async {
      await openCleanCode(tester);
      expect(find.text('3.0 (1)'), findsOneWidget, reason: 'the Clean Code card');
      expect(find.bySemanticsLabel(RegExp(r'^Clean Code by .*rated 3\.0 out of 5')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Effective Java by .*rated')), findsNothing);
      await tester.tap(find.byTooltip('Show as a list'));
      await tester.pumpAndSettle();
      expect(find.text('3.0 (1)'), findsOneWidget, reason: 'the Clean Code row');
      await finish(tester);
    });

    testWidgets('a book with no reviews invites the first one', (tester) async {
      await start(tester);
      await logIn(tester);
      await tester.tap(find.bySemanticsLabel(RegExp('^Effective Java by')));
      await tester.pumpAndSettle();
      expect(find.text('No reviews yet. Be the first.'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Write a review'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('the customer writes a review with stars and words and sees it listed first, with the new average', (tester) async {
      await openCleanCode(tester);
      expect(find.text('3.0 · 1 review'), findsOneWidget, reason: 'the rating under the author');
      expect(find.text('Solid advice'), findsOneWidget);
      expect(find.text('bob'), findsOneWidget);

      await writeReview(tester);
      expect(fakeBooks().reviewsByBook[books[0].id]!.map((r) => (r.username, r.rating, r.text)), contains(('alice', 5, 'Loved it')));
      expect(find.text('Your review'), findsOneWidget);
      expect(find.text('Loved it'), findsOneWidget);
      expect(find.text('4.0 · 2 reviews'), findsOneWidget, reason: 'the book is searched again for its new rating');
      expect(find.text('4.0 (2)'), findsOneWidget, reason: 'and the card shows it too');
      expect(find.widgetWithText(AppButton, 'Write a review'), findsNothing, reason: 'one review per customer: it is edited instead');
      expect(tester.getTopLeft(find.text('Your review')).dy, lessThan(tester.getTopLeft(find.text('Solid advice')).dy));
      await finish(tester);
    });

    testWidgets('saving without choosing stars names the problem and saves nothing', (tester) async {
      await openCleanCode(tester);
      await press(tester, 'Write a review');
      await tester.enterText(reviewText(), 'No stars');
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a rating from 1 to 5 stars'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget, reason: 'the dialog stays open with what was written');
      expect(fakeBooks().reviewsByBook[books[0].id], hasLength(1));

      await tester.tap(find.byTooltip('2 stars'));
      await tester.pump();
      expect(find.text('Choose a rating from 1 to 5 stars'), findsNothing, reason: 'the problem goes once fixed');
      await finish(tester);
    });

    testWidgets('the words are limited to 1000 characters and the count is shown', (tester) async {
      await openCleanCode(tester);
      await press(tester, 'Write a review');
      expect(find.text('0 / 1000'), findsOneWidget);
      await tester.enterText(reviewText(), 'x' * 1200);
      await tester.pump();
      expect(find.text('1000 / 1000'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('the limit and the count agree with book-service for emoji too: Unicode characters, not text units', (tester) async {
      await openCleanCode(tester);
      await press(tester, 'Write a review');
      // Each of these is two UTF-16 units but one character to book-service.
      await tester.enterText(reviewText(), '\u{1F600}' * 1200);
      await tester.pump();
      expect(find.text('1000 / 1000'), findsOneWidget);
      expect(tester.widget<TextField>(reviewText()).controller!.text.runes.length, 1000);

      // A family emoji is one picture but five characters to book-service, so 300 of them are over the limit.
      await tester.enterText(reviewText(), '\u{1F468}‍\u{1F469}‍\u{1F467}' * 300);
      await tester.pump();
      expect(find.text('1000 / 1000'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('while a review is being saved, Esc and a click outside do not close the dialog', (tester) async {
      await openCleanCode(tester);
      final gate = fakeBooks().saveGate = Completer<void>();
      await press(tester, 'Write a review');
      await tester.tap(find.byTooltip('4 stars'));
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pump();

      // The spinner never settles, so wait out a closing animation by hand.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Dialog), findsOneWidget, reason: 'Esc waits while the save is on its way');
      await tester.tapAt(const Offset(4, 4));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Dialog), findsOneWidget, reason: 'and so does a click outside');

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Your review'), findsOneWidget, reason: 'the panel knows about the saved review');
      expect(find.text('No reviews yet. Be the first.'), findsNothing);
      await finish(tester);
    });

    testWidgets('when nothing is being saved, Esc still closes the review dialog', (tester) async {
      await openCleanCode(tester);
      await press(tester, 'Write a review');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await finish(tester);
    });

    testWidgets('the customer edits their review: the dialog starts from it', (tester) async {
      await openCleanCode(tester);
      await writeReview(tester);
      await press(tester, 'Edit');
      expect(find.text('5 of 5 stars'), findsOneWidget);
      expect(find.descendant(of: find.byType(Dialog), matching: find.text('Loved it')), findsOneWidget);
      await tester.tap(find.byTooltip('2 stars'));
      await tester.enterText(reviewText(), 'Less good the second time');
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Less good the second time'), findsOneWidget);
      expect(find.text('2.5 · 2 reviews'), findsOneWidget);
      expect(fakeBooks().reviewsByBook[books[0].id], hasLength(2), reason: 'replaced, not added');
      await finish(tester);
    });

    testWidgets('a deleted review can be put back with Undo', (tester) async {
      await openCleanCode(tester);
      await writeReview(tester);
      await press(tester, 'Delete');
      expect(find.text('Your review of Clean Code was deleted'), findsOneWidget);
      expect(find.text('Loved it'), findsNothing);
      expect(find.text('3.0 · 1 review'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Write a review'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Loved it'), findsOneWidget);
      expect(find.text('4.0 · 2 reviews'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('if the reviews cannot be loaded, the message is shown with Try again', (tester) async {
      await start(tester);
      fakeBooks().addReview(books[0].id, 'bob', 3, 'Solid advice');
      fakeBooks().reviewsFailure = const ApiException('The book catalog is not answering. Please try again in a moment.', 0);
      await logIn(tester);
      await tester.tap(find.bySemanticsLabel(RegExp('^Clean Code by')));
      await tester.pumpAndSettle();
      expect(find.text('The book catalog is not answering. Please try again in a moment.'), findsOneWidget);

      fakeBooks().reviewsFailure = null;
      await press(tester, 'Try again');
      expect(find.text('Solid advice'), findsOneWidget);
      await finish(tester);
    });
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
