import '../models/book.dart';
import '../models/order.dart';
import '../models/order_draft.dart';
import 'api_client.dart';
import 'session.dart';

/// Where the services listen. They run on this machine only (P-004).
const userServiceUrl = 'http://127.0.0.1:8081';
const bookServiceUrl = 'http://127.0.0.1:8082';
const orderServiceUrl = 'http://127.0.0.1:8083';

/// user-service: log in, log out, create an account (FR1, FR2, FR3).
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

/// book-service: keyword search (FR4, FR5).
class BookApi extends ApiClient {
  BookApi(Session session, {String baseUrl = bookServiceUrl}) : super(baseUrl, session, serviceName: 'The book catalog');

  /// Books whose title or author contains [keyword]; every book when it is empty.
  Future<List<Book>> search(String keyword) async {
    final query = keyword.trim().isEmpty ? '' : '?keyword=${Uri.encodeQueryComponent(keyword.trim())}';
    final json = await get('/api/books$query') as List;
    return [for (final b in json) Book.fromJson(b as Map<String, dynamic>)];
  }
}

/// order-service: place an order and get its bill (FR6-FR10).
class OrderApi extends ApiClient {
  OrderApi(Session session, {String baseUrl = orderServiceUrl}) : super(baseUrl, session, serviceName: 'The order service');

  Future<Order> createOrder(OrderDraft draft) async => Order.fromJson(await post('/api/orders', draft.toJson()) as Map<String, dynamic>);
}
