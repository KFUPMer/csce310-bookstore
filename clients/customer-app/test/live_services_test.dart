import 'dart:io';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:customer_app/api/apis.dart';
import 'package:customer_app/models/order_draft.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app's own service clients against the three real running services.
///
/// Skipped in the normal test run, because it places a real order. Run it with
/// the services started and the test data seeded:
///
///     set BOOKSTORE_LIVE=1 && flutter test test/live_services_test.dart
///
/// It prints the order it placed and the book it took a copy of, so they can be
/// removed again afterwards.
void main() {
  final live = Platform.environment['BOOKSTORE_LIVE'] == '1';
  if (!live) {
    test('live check against the running services', () {}, skip: 'Set BOOKSTORE_LIVE=1 and start the three services to run it');
    return;
  }
  final session = Session();
  final users = UserApi(session);
  final books = BookApi(session);
  final orders = OrderApi(session);

  test('a wrong password is refused with user-service\'s message', () async {
    await expectLater(
      users.login('customer1', 'not-the-password'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Wrong username or password')),
    );
    expect(session.isLoggedIn, isFalse);
  });

  test('log in, search, place an order with a rented book, log out', () async {
    final watch = Stopwatch()..start();
    await users.login('customer1', 'customer123');
    stdout.writeln('login: ${watch.elapsedMilliseconds} ms');
    expect(session.role, 'CUSTOMER');

    watch.reset();
    final all = await books.search('');
    stdout.writeln('all books: ${all.length} in ${watch.elapsedMilliseconds} ms');
    expect(all, isNotEmpty);

    watch.reset();
    final java = await books.search('java');
    stdout.writeln('search "java": ${java.map((b) => b.title).join(', ')} in ${watch.elapsedMilliseconds} ms');
    expect(java.every((b) => '${b.title} ${b.author}'.toLowerCase().contains('java')), isTrue);

    final book = all.firstWhere((b) => b.copiesAvailable >= 1);
    final draft = OrderDraft()..add(book, ItemType.rent);
    watch.reset();
    final order = await orders.createOrder(draft);
    stdout.writeln('ORDER ${order.id} BOOK ${book.id} in ${watch.elapsedMilliseconds} ms');
    expect(order.total, book.rentPrice, reason: 'the app shows the same rent price the service charges');
    expect(order.items.single.dueBack, isNotNull);
    expect(order.paymentStatus, 'PENDING');

    final after = await books.search('');
    expect(after.firstWhere((b) => b.id == book.id).copiesAvailable, book.copiesAvailable - 1);

    // The account page: the new order is first, with its rented book. Then the pretend checkout pays it.
    watch.reset();
    final mine = await orders.myOrders();
    stdout.writeln('my orders: ${mine.length} in ${watch.elapsedMilliseconds} ms');
    expect(mine.first.id, order.id);
    expect(mine.first.items.single.dueBack, order.items.single.dueBack);
    expect(mine.every((o) => o.username == 'customer1'), isTrue, reason: 'only this customer\'s orders');

    watch.reset();
    final paid = await orders.pay(order.id);
    stdout.writeln('pay: ${watch.elapsedMilliseconds} ms');
    expect(paid.paymentStatus, 'PAID');
    await expectLater(orders.pay(order.id), throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)));

    await users.logout();
    expect(session.isLoggedIn, isFalse);
  });

  test('a request with an ended session sends the app back to log in', () async {
    session.start(token: 'x' * 64, userId: 1, username: 'customer1', email: 'customer1@example.com', role: 'CUSTOMER');
    await expectLater(books.search(''), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
    expect(session.isLoggedIn, isFalse);
    expect(session.endedMessage, isNotNull);
  });
}
