import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:customer_app/api/apis.dart';
import 'package:customer_app/main.dart';
import 'package:customer_app/models/order_draft.dart';
import 'package:customer_app/models/preferences.dart';

/// Stand-ins for the three services, used by the screen tests and the screenshots.

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
  final file = File('../../database/mongodb/books.json');
  final json = jsonDecode(file.readAsStringSync()) as List;
  return [
    for (final (i, b) in json.indexed) Book.fromJson({...b as Map<String, dynamic>, 'id': (i + 1).toRadixString(16).padLeft(24, '0')}),
  ];
}

class FakeUsers extends UserApi {
  FakeUsers(super.session, {this.role = 'CUSTOMER'}) : super(baseUrl: 'http://unused');
  final String role;

  @override
  Future<void> login(String username, String password) async {
    if (password != 'right-password') throw const ApiException('Wrong username or password', 401);
    session.start(token: 't', userId: 1, username: username, email: '$username@example.com', role: role);
  }

  @override
  Future<void> logout({String? reason}) async => session.clear(message: reason);

  @override
  Future<void> register(String username, String email, String password) async {
    if (username == 'taken') throw const ApiException('This username is already taken', 409);
  }
}

class FakeBooks extends BookApi {
  FakeBooks(super.session, this.books) : super(baseUrl: 'http://unused');
  final List<Book> books;

  /// Each book's reviews, by book id. The rating a search returns is worked out from them, as book-service does.
  final Map<String, List<Review>> reviewsByBook = {};

  /// When set, asking for reviews fails with it.
  ApiException? reviewsFailure;

  /// When set, saving a review waits until it completes, so a test can act while the save is on its way.
  Completer<void>? saveGate;

  /// The time stamped on the next review; moves on a minute each time, so "newest first" is clear.
  DateTime clock = DateTime(2026, 11, 17, 9);

  @override
  Future<List<Book>> search(String keyword, {String? category}) async {
    final k = keyword.trim().toLowerCase();
    final found = [
      for (final b in books)
        if ((b.title.toLowerCase().contains(k) || b.author.toLowerCase().contains(k)) && (category == null || b.category == category)) _rated(b),
    ];
    return found..sort((a, b) => a.title.compareTo(b.title));
  }

  Book _rated(Book b) {
    final reviews = reviewsByBook[b.id] ?? const [];
    if (reviews.isEmpty) return b;
    final average = reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length;
    return Book(
      id: b.id,
      title: b.title,
      author: b.author,
      price: b.price,
      copiesAvailable: b.copiesAvailable,
      coverUrl: b.coverUrl,
      category: b.category,
      ratingAverage: (average * 10).round() / 10,
      ratingCount: reviews.length,
    );
  }

  /// Saves [username]'s review of the book: what another customer wrote, for a test to start from.
  Review addReview(String bookId, String username, int rating, String text) {
    final list = reviewsByBook.putIfAbsent(bookId, () => []);
    final old = list.where((r) => r.username == username).firstOrNull;
    clock = clock.add(const Duration(minutes: 1));
    final review = Review(
      id: (list.length + 1).toRadixString(16).padLeft(24, 'e'),
      bookId: bookId,
      username: username,
      rating: rating,
      text: text.trim(),
      createdAt: old?.createdAt ?? clock,
      updatedAt: clock,
    );
    list
      ..removeWhere((r) => r.username == username)
      ..add(review);
    return review;
  }

  @override
  Future<List<Review>> reviews(String bookId) async {
    if (reviewsFailure != null) throw reviewsFailure!;
    return [...?reviewsByBook[bookId]]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<Review> saveMyReview(String bookId, int rating, String text) async {
    if (rating < 1 || rating > 5) throw const ApiException('Choose a rating from 1 to 5 stars', 400);
    await saveGate?.future;
    return addReview(bookId, session.username!, rating, text);
  }

  @override
  Future<void> deleteMyReview(String bookId) async {
    final list = reviewsByBook[bookId] ?? [];
    if (!list.any((r) => r.username == session.username)) throw const ApiException('You have not reviewed this book', 404);
    list.removeWhere((r) => r.username == session.username);
  }
}

class FakeOrders extends OrderApi {
  FakeOrders(super.session) : super(baseUrl: 'http://unused');
  ApiException? failure;
  DateTime now = DateTime(2026, 11, 17, 10, 5);

  /// The number the next placed order gets. The screenshots set it so their orders match the manager app's.
  int nextId = 1042;
  final List<Order> placed = [];
  final List<int> paid = [];

  @override
  Future<List<Order>> myOrders() async => placed.reversed.toList();

  @override
  Future<Order> pay(int orderId) async {
    final i = placed.indexWhere((o) => o.id == orderId);
    if (placed[i].isPaid) throw const ApiException('This order is already paid', 409);
    paid.add(orderId);
    return placed[i] = placed[i].copyWith(paymentStatus: Order.paid);
  }

  @override
  Future<Order> createOrder(OrderDraft draft) async {
    if (failure != null) throw failure!;
    final order = _order(draft);
    placed.add(order);
    return order;
  }

  Order _order(OrderDraft draft) {
    return Order(
      id: nextId,
      username: session.username!,
      createdAt: now,
      paymentStatus: 'PENDING',
      items: [
        for (final i in draft.items)
          PlacedItem(title: i.book.title, author: i.book.author, type: i.type, quantity: 1, unitPrice: i.charge, dueBack: i.dueBack(now)),
      ],
      total: draft.total,
      emailQueued: true,
    );
  }
}

/// The app's services, all stand-ins.
AppServices fakeServices({String role = 'CUSTOMER', List<Book>? books}) {
  final session = Session();
  return AppServices(
    session: session,
    draft: OrderDraft(),
    users: FakeUsers(session, role: role),
    books: FakeBooks(session, books ?? sampleBooks()),
    orders: FakeOrders(session),
    preferences: Preferences(), // in memory only: tests never write to the real preferences file
    now: () => DateTime(2026, 11, 17, 12),
  );
}
