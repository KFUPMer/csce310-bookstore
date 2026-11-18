import '../models/book.dart';
import '../models/review.dart';
import 'api_client.dart';
import 'session.dart';

/// Where the services listen. They run on this machine only (P-004).
const userServiceUrl = 'http://127.0.0.1:8081';
const bookServiceUrl = 'http://127.0.0.1:8082';
const orderServiceUrl = 'http://127.0.0.1:8083';

/// user-service: log in, log out, create an account (FR1, FR2, FR3). Used by both apps.
class UserApi extends ApiClient {
  UserApi(Session session, {String baseUrl = userServiceUrl}) : super(baseUrl, session, serviceName: 'The login service');

  /// Logs in and starts [session]. Throws ApiException("Wrong username or password") etc.
  Future<void> login(String username, String password) async {
    final json = await post('/api/auth/login', {'username': username.trim(), 'password': password}) as Map<String, dynamic>;
    session.start(
      token: json['token'] as String,
      userId: json['userId'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }

  /// Ends the session. The app logs out locally even if user-service cannot be reached.
  /// [reason], if given, is shown on the login screen the app returns to.
  Future<void> logout({String? reason}) async {
    try {
      await post('/api/auth/logout');
    } on ApiException {
      // The session is forgotten here anyway; on the server it simply stays unused.
    } finally {
      session.clear(message: reason);
    }
  }

  Future<void> register(String username, String email, String password) =>
      post('/api/users/register', {'username': username.trim(), 'email': email.trim(), 'password': password});
}

/// book-service: search (FR4, FR5), and add and change books (FR14, managers only). Used by both apps.
class BookApi extends ApiClient {
  BookApi(Session session, {String baseUrl = bookServiceUrl}) : super(baseUrl, session, serviceName: 'The book catalog');

  /// Books whose title or author contains [keyword]; every book when it is empty.
  /// A [category] keeps only that shelf (one of [categories]).
  Future<List<Book>> search(String keyword, {String? category}) async {
    final params = [
      if (keyword.trim().isNotEmpty) 'keyword=${Uri.encodeQueryComponent(keyword.trim())}',
      if (category != null && category.isNotEmpty) 'category=${Uri.encodeQueryComponent(category)}',
    ];
    final json = await get('/api/books${params.isEmpty ? '' : '?${params.join('&')}'}') as List;
    return [for (final b in json) Book.fromJson(b as Map<String, dynamic>)];
  }

  /// FR14: adds a book and returns it with its new id.
  Future<Book> add(Book book) async => Book.fromJson(await post('/api/books', book.toJson()) as Map<String, dynamic>);

  /// FR14: changes a book's details, including its number of copies.
  Future<Book> update(Book book) async => Book.fromJson(await put('/api/books/${book.id}', book.toJson()) as Map<String, dynamic>);

  /// A book's reviews, newest first. Extra credit, beyond the PRD.
  Future<List<Review>> reviews(String bookId) async => [
    for (final r in await get('/api/books/$bookId/reviews') as List) Review.fromJson(r as Map<String, dynamic>),
  ];

  /// Writes the customer's review of the book, or replaces the one they wrote before.
  Future<Review> saveMyReview(String bookId, int rating, String text) async =>
      Review.fromJson(await put('/api/books/$bookId/reviews/mine', {'rating': rating, 'text': text.trim()}) as Map<String, dynamic>);

  Future<void> deleteMyReview(String bookId) => delete('/api/books/$bookId/reviews/mine');
}
