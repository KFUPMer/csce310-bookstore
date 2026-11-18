import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:management_app/api/order_api.dart';
import 'package:management_app/main.dart';

/// Stand-ins for the three services, used by the screen tests and the screenshots.

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

/// The app's services, all stand-ins. [opened] records the files "opened with Windows".
ManagerServices fakeServices({String role = 'MANAGER', List<Order>? orders, List<Book>? books, List<String>? opened}) {
  final session = Session();
  return ManagerServices(
    session: session,
    users: FakeUsers(session, role: role),
    books: FakeBooks(session, books ?? sampleBooks()),
    orders: FakeOrders(session, orders ?? sampleOrders()),
    openFile: (path) async => opened?.add(path),
  );
}
