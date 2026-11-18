import 'dart:convert';
import 'dart:io';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// ApiClient against a small real web server on this machine, so the address,
/// headers, body, and the reading of each answer are all exercised.
void main() {
  late HttpServer server;
  late Session session;
  late ApiClient api;
  late List<HttpRequest> seen;
  late Future<void> Function(HttpRequest) answer;

  setUp(() async {
    seen = [];
    answer = (r) async => r.response.close();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      seen.add(request);
      await answer(request);
    });
    session = Session();
    api = ApiClient('http://127.0.0.1:${server.port}', session, serviceName: 'The book catalog');
  });

  tearDown(() => server.close(force: true));

  Future<void> reply(HttpRequest r, int status, Object? body) async {
    r.response.statusCode = status;
    r.response.headers.contentType = ContentType.json;
    r.response.write(jsonEncode(body));
    await r.response.close();
  }

  test('sends the session token and reads the JSON answer', () async {
    session.start(token: 'tok', userId: 1, username: 'alice', email: 'a@example.com', role: 'CUSTOMER');
    answer = (r) => reply(r, 200, [
      {'title': 'Clean Code'},
    ]);
    final body = await api.get('/api/books?keyword=clean');
    expect(body, [
      {'title': 'Clean Code'},
    ]);
    expect(seen.single.uri.toString(), '/api/books?keyword=clean');
    expect(seen.single.headers.value('authorization'), 'Bearer tok');
  });

  test('a search asks for the keyword and the shelf, and leaves out what is empty', () async {
    answer = (r) => reply(r, 200, []);
    final books = BookApi(session, baseUrl: 'http://127.0.0.1:${server.port}');
    await books.search('head first', category: 'Kids');
    await books.search('', category: 'Fiction');
    await books.search('java');
    await books.search('');
    expect(
      [for (final r in seen) r.uri.toString()],
      ['/api/books?keyword=head+first&category=Kids', '/api/books?category=Fiction', '/api/books?keyword=java', '/api/books'],
    );
  });

  test('sends a JSON body', () async {
    String? received;
    answer = (r) async {
      received = await utf8.decoder.bind(r).join();
      await reply(r, 201, {'id': 7});
    };
    expect(await api.post('/api/orders', {'items': []}), {'id': 7});
    expect(seen.single.method, 'POST');
    expect(seen.single.headers.contentType?.mimeType, 'application/json');
    expect(jsonDecode(received!), {'items': []});
  });

  test('without a session no token is sent', () async {
    await api.post('/api/auth/login', {'username': 'x'});
    expect(seen.single.headers.value('authorization'), isNull);
  });

  test("an error is raised with the service's own message and status", () async {
    answer = (r) => reply(r, 409, {'error': '"Clean Code" is not available'});
    await expectLater(
      api.post('/api/orders', {}),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', '"Clean Code" is not available').having((e) => e.status, 'status', 409)),
    );
  });

  test('an error without a readable message gets a plain one', () async {
    answer = (r) async {
      r.response.statusCode = 500;
      r.response.write('<html>oops</html>');
      await r.response.close();
    };
    await expectLater(
      api.get('/x'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Something went wrong on the server. Please try again.')),
    );
  });

  test('a 401 for a logged-in user ends the session, so the app goes back to log in', () async {
    session.start(token: 'old', userId: 1, username: 'alice', email: 'a@example.com', role: 'CUSTOMER');
    answer = (r) => reply(r, 401, {'error': 'Your session has ended. Please log in again.'});
    await expectLater(api.get('/api/books'), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
    expect(session.isLoggedIn, isFalse);
    expect(session.endedMessage, 'Your session has ended. Please log in again.');
  });

  test('a 401 at login (wrong password) does not touch the session', () async {
    answer = (r) => reply(r, 401, {'error': 'Wrong username or password'});
    await expectLater(
      api.post('/api/auth/login', {}),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Wrong username or password')),
    );
    expect(session.endedMessage, isNull);
  });

  test('a service that is not running gives a plain message naming it', () async {
    final port = server.port;
    await server.close(force: true);
    final down = ApiClient('http://127.0.0.1:$port', session, serviceName: 'The book catalog');
    await expectLater(
      down.get('/api/books'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'The book catalog is not answering. Please try again in a moment.')
            .having((e) => e.status, 'status', 0),
      ),
    );
  });

  test('a service that is too slow gives the same plain message instead of hanging', () async {
    answer = (r) => Future.delayed(const Duration(seconds: 2), () => reply(r, 200, {}));
    final slow = ApiClient('http://127.0.0.1:${server.port}', session, serviceName: 'The book catalog', timeout: const Duration(milliseconds: 300));
    await expectLater(slow.get('/api/books'), throwsA(isA<ApiException>().having((e) => e.status, 'status', 0)));
  });

  group('reviews', () {
    const bookId = 'aaaaaaaaaaaaaaaaaaaaaaaa';
    Map<String, dynamic> reviewJson({int rating = 4, String text = 'Loved it'}) => {
      'id': 'f' * 24,
      'bookId': bookId,
      'username': 'alice',
      'rating': rating,
      'text': text,
      'createdAt': '2026-11-18T10:05:00',
      'updatedAt': '2026-11-18T10:05:00',
    };

    test("a book's reviews are asked for at its address and read in the order given", () async {
      answer = (r) => reply(r, 200, [reviewJson(rating: 5), reviewJson(rating: 2, text: '')]);
      final books = BookApi(session, baseUrl: 'http://127.0.0.1:${server.port}');
      final reviews = await books.reviews(bookId);
      expect(seen.single.method, 'GET');
      expect(seen.single.uri.toString(), '/api/books/$bookId/reviews');
      expect([for (final r in reviews) r.rating], [5, 2]);
      expect(reviews.last.text, '');
    });

    test("saving the customer's review sends the stars and the trimmed words with PUT", () async {
      String? received;
      answer = (r) async {
        received = await utf8.decoder.bind(r).join();
        await reply(r, 200, reviewJson(rating: 3, text: 'Good'));
      };
      final books = BookApi(session, baseUrl: 'http://127.0.0.1:${server.port}');
      final saved = await books.saveMyReview(bookId, 3, '  Good \n');
      expect(seen.single.method, 'PUT');
      expect(seen.single.uri.toString(), '/api/books/$bookId/reviews/mine');
      expect(jsonDecode(received!), {'rating': 3, 'text': 'Good'});
      expect(saved.rating, 3);
    });

    test('a refused review raises the message book-service gives', () async {
      answer = (r) => reply(r, 400, {'error': 'Choose a rating from 1 to 5 stars'});
      final books = BookApi(session, baseUrl: 'http://127.0.0.1:${server.port}');
      await expectLater(
        books.saveMyReview(bookId, 0, ''),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Choose a rating from 1 to 5 stars')),
      );
    });

    test("deleting the customer's review uses DELETE and accepts the empty 204 answer", () async {
      answer = (r) async {
        r.response.statusCode = 204;
        await r.response.close();
      };
      final books = BookApi(session, baseUrl: 'http://127.0.0.1:${server.port}');
      await books.deleteMyReview(bookId);
      expect(seen.single.method, 'DELETE');
      expect(seen.single.uri.toString(), '/api/books/$bookId/reviews/mine');
    });

    test('a 204 marked as JSON but with no body is also accepted', () async {
      answer = (r) async {
        r.response.statusCode = 204;
        r.response.headers.contentType = ContentType.json;
        await r.response.close();
      };
      expect(await api.delete('/api/books/$bookId/reviews/mine'), isNull);
    });

    test('deleting a review that is not there raises the service message', () async {
      answer = (r) => reply(r, 404, {'error': 'You have not reviewed this book'});
      final books = BookApi(session, baseUrl: 'http://127.0.0.1:${server.port}');
      await expectLater(
        books.deleteMyReview(bookId),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'You have not reviewed this book').having((e) => e.status, 'status', 404)),
      );
    });
  });

  test('an HTML answer is returned as text', () async {
    answer = (r) async {
      r.response.headers.contentType = ContentType.html;
      r.response.write('<!DOCTYPE html><p>bill</p>');
      await r.response.close();
    };
    expect(await api.get('/api/orders/1/bill'), '<!DOCTYPE html><p>bill</p>');
  });
}
