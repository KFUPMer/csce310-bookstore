import 'dart:io';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_app/api/order_api.dart';
import 'package:management_app/api/report_api.dart';

/// The manager app's service clients against the three real running services.
///
/// It changes nothing: it reads the orders and books, and saves one book with
/// the values it already has. Skipped in the normal test run:
///
///     set BOOKSTORE_LIVE=1 && flutter test test/live_services_test.dart
void main() {
  if (Platform.environment['BOOKSTORE_LIVE'] != '1') {
    test('live check against the running services', () {}, skip: 'Set BOOKSTORE_LIVE=1 and start the three services to run it');
    return;
  }
  final session = Session();
  final users = UserApi(session);
  final books = BookApi(session);
  final orders = OrderApi(session);

  test('a customer account cannot use the manager endpoints', () async {
    await users.login('customer1', 'customer123');
    await expectLater(orders.listOrders(), throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)));
    await users.logout();
  });

  test('a manager lists orders and books, opens an order, and saves a book', () async {
    final watch = Stopwatch()..start();
    await users.login('manager1', 'manager123');
    stdout.writeln('login: ${watch.elapsedMilliseconds} ms, role ${session.role}');
    expect(session.role, 'MANAGER');

    watch.reset();
    final list = await orders.listOrders();
    stdout.writeln('orders: ${list.length} in ${watch.elapsedMilliseconds} ms');
    if (list.isNotEmpty) {
      watch.reset();
      final one = await orders.getOrder(list.first.id);
      stdout.writeln('order ${one.id}: ${one.items.length} items, ${one.email} in ${watch.elapsedMilliseconds} ms');
      expect(one.items, isNotEmpty);
      final html = await orders.billHtml(one.id);
      expect(html, startsWith('<!DOCTYPE html>'));
    }

    watch.reset();
    final all = await books.search('');
    stdout.writeln('books: ${all.length} in ${watch.elapsedMilliseconds} ms');
    final book = all.first;
    watch.reset();
    final saved = await books.update(book);
    stdout.writeln('saved "${saved.title}" unchanged in ${watch.elapsedMilliseconds} ms');
    expect((saved.title, saved.price, saved.copiesAvailable), (book.title, book.price, book.copiesAvailable));

    // The sales report (extra credit): over all time it counts exactly the orders the list shows.
    watch.reset();
    final report = await ReportApi(session).salesReport();
    stdout.writeln('report: ${report.orderCount} orders, ${money(report.revenue)}, ${report.bestSellers.length} best sellers in ${watch.elapsedMilliseconds} ms');
    expect(report.orderCount, list.length);
    expect(report.paidCount + report.pendingCount, report.orderCount);
    await users.logout();
  });
}
