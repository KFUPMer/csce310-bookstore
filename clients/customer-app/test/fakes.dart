import 'dart:convert';
import 'dart:io';

import 'package:customer_app/api/api_client.dart';
import 'package:customer_app/api/apis.dart';
import 'package:customer_app/api/session.dart';
import 'package:customer_app/main.dart';
import 'package:customer_app/models/book.dart';
import 'package:customer_app/models/order.dart';
import 'package:customer_app/models/order_draft.dart';

/// Stand-ins for the three services, used by the screen tests and the screenshots.

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

  @override
  Future<List<Book>> search(String keyword) async {
    final k = keyword.trim().toLowerCase();
    final found = [
      for (final b in books)
        if (b.title.toLowerCase().contains(k) || b.author.toLowerCase().contains(k)) b,
    ];
    return found..sort((a, b) => a.title.compareTo(b.title));
  }
}

class FakeOrders extends OrderApi {
  FakeOrders(super.session) : super(baseUrl: 'http://unused');
  ApiException? failure;
  DateTime now = DateTime(2026, 11, 17, 10, 5);

  @override
  Future<Order> createOrder(OrderDraft draft) async {
    if (failure != null) throw failure!;
    return Order(
      id: 1042,
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
  );
}
