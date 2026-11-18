import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:management_app/api/order_api.dart';
import 'package:management_app/api/report_api.dart';
import 'package:management_app/main.dart';
import 'package:management_app/models/sales_report.dart';

/// Stand-ins for the three services, used by the screen tests and the screenshots.

/// The app's real typefaces, in place of the square test font, for the screenshots and for
/// checks of how much room real text takes. A font stays loaded for the rest of the test file.
Future<void> loadRealFonts() async {
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

// The same helper as in the customer app's test/fakes.dart: each app is its own project.
/// For the screenshots: the real cover photos of books.json, from the cache that
/// tools/screenshots/fetch_covers.py fills (tests have no internet). Each photo is
/// decoded here, up front, so the covers show it at once; a missing one keeps its drawn cover.
Future<void> useCachedCovers(WidgetTester tester) async {
  final ready = <String, ui.Image>{};
  await tester.runAsync(() async {
    final books = jsonDecode(File('../../database/mongodb/books.json').readAsStringSync()) as List;
    for (final b in books) {
      final url = (b as Map<String, dynamic>)['coverUrl'] as String?;
      final file = File('../build-cover-cache/${url?.replaceAll(RegExp('[^A-Za-z0-9]'), '_')}.jpg');
      if (url == null || !file.existsSync()) continue;
      final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
      ready[url] = (await codec.getNextFrame()).image;
    }
  });
  BookCover.imageFor = (url) => ready.containsKey(url) ? _ReadyImage(url, ready[url]!) : NetworkImage(url);
}

/// An image that is already decoded, so it is shown in the very first frame.
class _ReadyImage extends ImageProvider<_ReadyImage> {
  const _ReadyImage(this.url, this.image);

  final String url;
  final ui.Image image;

  @override
  Future<_ReadyImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_ReadyImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(SynchronousFuture(ImageInfo(image: image.clone())));

  @override
  bool operator ==(Object other) => other is _ReadyImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

/// The sample books of database/mongodb/books.json, with made-up ids.
List<Book> sampleBooks() {
  final json = jsonDecode(File('../../database/mongodb/books.json').readAsStringSync()) as List;
  return [
    for (final (i, b) in json.indexed) Book.fromJson({...b as Map<String, dynamic>, 'id': (i + 1).toRadixString(16).padLeft(24, '0')}),
  ];
}

/// A few orders as customers would have placed them.
List<Order> sampleOrders() => [
  Order(
    id: 1044,
    username: 'alice',
    email: 'alice@example.com',
    createdAt: DateTime(2026, 11, 17, 14, 20),
    paymentStatus: Order.pending,
    total: 103,
    items: [
      PlacedItem(title: 'Clean Code', author: 'Robert C. Martin', type: ItemType.buy, quantity: 1, unitPrice: 40),
      PlacedItem(title: 'Database System Concepts', author: 'Abraham Silberschatz', type: ItemType.buy, quantity: 1, unitPrice: 55),
      PlacedItem(
        title: 'Java Concurrency in Practice',
        author: 'Brian Goetz',
        type: ItemType.rent,
        quantity: 1,
        unitPrice: 8,
        dueBack: DateTime(2026, 11, 24),
      ),
    ],
  ),
  Order(
    id: 1043,
    username: 'omar',
    email: 'omar@example.com',
    createdAt: DateTime(2026, 11, 16, 18, 40),
    paymentStatus: Order.paid,
    total: 55,
    items: [PlacedItem(title: 'Database System Concepts', author: 'Abraham Silberschatz', type: ItemType.buy, quantity: 1, unitPrice: 55)],
  ),
  Order(
    id: 1042,
    username: 'customer1',
    email: 'customer1@example.com',
    createdAt: DateTime(2026, 11, 15, 9, 15),
    paymentStatus: Order.pending,
    total: 4.8,
    items: [
      PlacedItem(title: 'Refactoring', author: 'Martin Fowler', type: ItemType.rent, quantity: 1, unitPrice: 4.8, dueBack: DateTime(2026, 11, 22)),
    ],
  ),
];

class FakeUsers extends UserApi {
  FakeUsers(super.session, {this.role = 'MANAGER'}) : super(baseUrl: 'http://unused');
  final String role;

  @override
  Future<void> login(String username, String password) async {
    if (password != 'right-password') throw const ApiException('Wrong username or password', 401);
    session.start(token: 't', userId: 2, username: username, email: '$username@example.com', role: role);
  }

  @override
  Future<void> logout({String? reason}) async => session.clear(message: reason);
}

class FakeBooks extends BookApi {
  FakeBooks(super.session, this.books) : super(baseUrl: 'http://unused');
  final List<Book> books;
  int _next = 100;

  @override
  Future<List<Book>> search(String keyword, {String? category}) async {
    final k = keyword.trim().toLowerCase();
    return [
      for (final b in books)
        if ((b.title.toLowerCase().contains(k) || b.author.toLowerCase().contains(k)) && (category == null || b.category == category)) b,
    ]..sort((a, b) => a.title.compareTo(b.title));
  }

  @override
  Future<Book> add(Book book) async {
    final saved = Book(
      id: '${_next++}'.padLeft(24, '0'),
      title: book.title,
      author: book.author,
      price: book.price,
      copiesAvailable: book.copiesAvailable,
      coverUrl: book.coverUrl,
    );
    books.add(saved);
    return saved;
  }

  @override
  Future<Book> update(Book book) async {
    books[books.indexWhere((b) => b.id == book.id)] = book;
    return book;
  }
}

class FakeOrders extends OrderApi {
  FakeOrders(super.session, this.orders) : super(baseUrl: 'http://unused');
  final List<Order> orders;

  @override
  Future<List<Order>> listOrders() async => [
    for (final o in orders) Order(id: o.id, username: o.username, createdAt: o.createdAt, paymentStatus: o.paymentStatus, total: o.total),
  ];

  @override
  Future<Order> getOrder(int id) async => orders.firstWhere((o) => o.id == id);

  @override
  Future<Order> setPaymentStatus(int id, String status) async {
    final i = orders.indexWhere((o) => o.id == id);
    orders[i] = orders[i].copyWith(paymentStatus: status);
    return orders[i];
  }

  @override
  Future<String> billHtml(int id) async => '<!DOCTYPE html><title>Bill $id</title>';
}

/// The fixed "now" of the screen tests and screenshots: 18 November 2026, 10:00.
DateTime fixedNow() => DateTime(2026, 11, 18, 10);

/// About two weeks of sales, as the report of the last 30 days would show them on [fixedNow].
/// The totals are added up from the orders, so they agree with each other the way the service's do.
SalesReport sampleReport() {
  // (day of November, orders that day, revenue that day); days without orders are left out, as the service does.
  const days = [
    (5, 2, 95.00),
    (6, 1, 40.00),
    (7, 3, 142.80),
    (9, 1, 4.80),
    (10, 2, 63.50),
    (11, 4, 187.00),
    (12, 2, 80.00),
    (13, 3, 121.40),
    (14, 1, 55.00),
    (15, 2, 59.80),
    (16, 3, 134.00),
    (17, 4, 178.50),
    (18, 2, 62.00),
  ];
  const customers = ['alice', 'omar', 'customer1', 'sara', 'yusuf', 'lina'];
  final orders = <Order>[];
  var id = 1015;
  for (final (day, count, revenue) in days) {
    final each = (revenue / count * 100).floor() / 100;
    for (var i = 0; i < count; i++) {
      final total = i == count - 1 ? ((revenue - each * (count - 1)) * 100).round() / 100 : each;
      orders.add(
        Order(
          id: id,
          username: customers[id % customers.length],
          createdAt: DateTime(2026, 11, day, 9 + i * 3, (id * 7) % 60),
          paymentStatus: day < 15 || id.isEven ? Order.paid : Order.pending,
          total: total,
        ),
      );
      id++;
    }
  }
  double sum(Iterable<Order> os) => os.fold(0.0, (s, o) => s + o.total);
  final paid = orders.where((o) => o.isPaid);
  return SalesReport(
    from: DateTime(2026, 10, 20),
    to: DateTime(2026, 11, 18),
    orderCount: orders.length,
    paidCount: paid.length,
    pendingCount: orders.length - paid.length,
    revenue: sum(orders),
    paidRevenue: sum(paid),
    booksSold: 34,
    booksRented: 12,
    byDay: [for (final (day, count, revenue) in days) DayTotal(date: DateTime(2026, 11, day), orders: count, revenue: revenue)],
    bestSellers: const [
      BestSeller(bookId: 'b1', title: 'Clean Code', author: 'Robert C. Martin', bought: 6, rented: 2, copies: 8, revenue: 248.00),
      BestSeller(bookId: 'b3', title: 'Database System Concepts', author: 'Abraham Silberschatz', bought: 4, rented: 1, copies: 5, revenue: 225.50),
      BestSeller(bookId: 'b9', title: 'Refactoring', author: 'Martin Fowler', bought: 3, rented: 2, copies: 5, revenue: 153.60),
      BestSeller(bookId: 'b5', title: 'Java Concurrency in Practice', author: 'Brian Goetz', bought: 2, rented: 2, copies: 4, revenue: 176.00),
      BestSeller(bookId: 'b8', title: 'Design Patterns', author: 'Erich Gamma', bought: 2, rented: 1, copies: 3, revenue: 136.50),
      BestSeller(
        bookId: 'b2',
        title: 'The Pragmatic Programmer',
        author: 'Andrew Hunt and David Thomas',
        bought: 3,
        rented: 0,
        copies: 3,
        revenue: 135.00,
      ),
      BestSeller(bookId: 'b21', title: 'Atomic Habits', author: 'James Clear', bought: 2, rented: 0, copies: 2, revenue: 54.00),
    ],
    orders: orders.reversed.toList(),
  );
}

/// A report of a period without orders.
SalesReport emptyReport({DateTime? from, DateTime? to}) => SalesReport(
  from: from,
  to: to,
  orderCount: 0,
  paidCount: 0,
  pendingCount: 0,
  revenue: 0,
  paidRevenue: 0,
  booksSold: 0,
  booksRented: 0,
  byDay: const [],
  bestSellers: const [],
  orders: const [],
);

class FakeReports extends ReportApi {
  FakeReports(super.session, this.report) : super(baseUrl: 'http://unused');

  /// What every request answers, whatever the period.
  SalesReport report;

  /// When set, every request fails with it.
  ApiException? failure;

  /// The (from, to) of each request, in order.
  final List<(DateTime?, DateTime?)> asked = [];

  @override
  Future<SalesReport> salesReport({DateTime? from, DateTime? to, int top = 10}) async {
    asked.add((from, to));
    if (failure != null) throw failure!;
    return report;
  }
}

/// The app's services, all stand-ins. [opened] records the files "opened with Windows".
ManagerServices fakeServices({String role = 'MANAGER', List<Order>? orders, List<Book>? books, List<String>? opened, SalesReport? report}) {
  final session = Session();
  return ManagerServices(
    session: session,
    users: FakeUsers(session, role: role),
    books: FakeBooks(session, books ?? sampleBooks()),
    orders: FakeOrders(session, orders ?? sampleOrders()),
    reports: FakeReports(session, report ?? sampleReport()),
    openFile: (path) async => opened?.add(path),
    now: fixedNow,
  );
}
