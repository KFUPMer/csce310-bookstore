import 'dart:convert';
import 'dart:io';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_app/api/report_api.dart';
import 'package:management_app/models/sales_report.dart';

/// The sales report: reading its JSON, asking for it, and the periods a manager can choose.
void main() {
  final json = <String, dynamic>{
    'from': '2026-11-01',
    'to': '2026-11-18',
    'orderCount': 7,
    'paidCount': 4,
    'pendingCount': 3,
    'revenue': 412.5,
    'paidRevenue': 300,
    'booksSold': 9,
    'booksRented': 5,
    'byDay': [
      {'date': '2026-11-16', 'orders': 4, 'revenue': 309.5},
      {'date': '2026-11-17', 'orders': 3, 'revenue': 103},
    ],
    'bestSellers': [
      {'bookId': 'b1', 'title': 'Clean Code', 'author': 'Robert C. Martin', 'bought': 3, 'rented': 1, 'copies': 4, 'revenue': 128},
    ],
    'orders': [
      {'id': 1044, 'username': 'alice', 'createdAt': '2026-11-17T14:20:00', 'total': 103, 'paymentStatus': 'PENDING'},
    ],
  };

  test('a report is read from its JSON, money as numbers with or without decimals', () {
    final r = SalesReport.fromJson(json);
    expect((r.from, r.to), (DateTime(2026, 11, 1), DateTime(2026, 11, 18)));
    expect((r.orderCount, r.paidCount, r.pendingCount, r.booksSold, r.booksRented), (7, 4, 3, 9, 5));
    expect((r.revenue, r.paidRevenue), (412.5, 300.0));
    expect(r.byDay.map((d) => (d.date, d.orders, d.revenue)), [(DateTime(2026, 11, 16), 4, 309.5), (DateTime(2026, 11, 17), 3, 103.0)]);
    final b = r.bestSellers.single;
    expect((b.bookId, b.title, b.author, b.bought, b.rented, b.copies, b.revenue), ('b1', 'Clean Code', 'Robert C. Martin', 3, 1, 4, 128.0));
    expect((r.orders.single.id, r.orders.single.isPaid, r.orders.single.total), (1044, false, 103.0));
    expect(r.isEmpty, isFalse);
  });

  test('an all-time report has no dates, and an empty period is empty', () {
    final r = SalesReport.fromJson({
      ...json,
      'from': null,
      'to': null,
      'orderCount': 0,
      'byDay': <Object>[],
      'bestSellers': <Object>[],
      'orders': <Object>[],
    });
    expect((r.from, r.to), (null, null));
    expect(r.isEmpty, isTrue);
  });

  group('the periods, on 18 November 2026 at 10:00', () {
    final now = DateTime(2026, 11, 18, 10);
    test('each is a range of whole days that ends today', () {
      expect(ReportPeriod.today.range(now), (DateTime(2026, 11, 18), DateTime(2026, 11, 18)));
      expect(ReportPeriod.last7Days.range(now), (DateTime(2026, 11, 12), DateTime(2026, 11, 18)));
      expect(ReportPeriod.last30Days.range(now), (DateTime(2026, 10, 20), DateTime(2026, 11, 18)));
      expect(ReportPeriod.thisMonth.range(now), (DateTime(2026, 11, 1), DateTime(2026, 11, 18)));
      expect(ReportPeriod.allTime.range(now), (null, null));
    });
    test('a range that crosses the start of a year', () {
      expect(ReportPeriod.last7Days.range(DateTime(2027, 1, 3)), (DateTime(2026, 12, 28), DateTime(2027, 1, 3)));
    });
    test('the labels', () {
      expect(ReportPeriod.values.map((p) => p.label), ['Today', 'Last 7 days', 'Last 30 days', 'This month', 'All time']);
    });
  });

  group('ReportApi against a small real web server', () {
    late HttpServer server;
    late List<HttpRequest> seen;
    late ReportApi api;

    setUp(() async {
      seen = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((r) async {
        seen.add(r);
        r.response.headers.contentType = ContentType.json;
        r.response.write(jsonEncode(json));
        await r.response.close();
      });
      final session = Session()..start(token: 'tok', userId: 2, username: 'manager1', email: 'm@example.com', role: 'MANAGER');
      api = ReportApi(session, baseUrl: 'http://127.0.0.1:${server.port}');
    });

    tearDown(() => server.close(force: true));

    test('sends the dates as YYYY-MM-DD and the number of best sellers', () async {
      final r = await api.salesReport(from: DateTime(2026, 11, 1, 23, 59), to: DateTime(2026, 11, 18), top: 5);
      expect(seen.single.uri.toString(), '/api/reports/sales?from=2026-11-01&to=2026-11-18&top=5');
      expect(seen.single.headers.value('authorization'), 'Bearer tok');
      expect(r.orderCount, 7);
    });

    test('leaves out the dates it was not given', () async {
      await api.salesReport();
      expect(seen.single.uri.toString(), '/api/reports/sales?top=10');
    });
  });
}
