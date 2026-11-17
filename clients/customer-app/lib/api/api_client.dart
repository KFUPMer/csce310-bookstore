import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'session.dart';

/// Every failure of a call to a service, with a message a person can read.
/// Screens show [message] as it is (engineering rules, section 3).
class ApiException implements Exception {
  const ApiException(this.message, this.status);

  final String message;

  /// The HTTP status, or 0 when the service could not be reached.
  final int status;

  @override
  String toString() => message;
}

/// Sends requests to one service and reads the answers. The base of
/// [UserApi], [BookApi], and [OrderApi].
///
/// Every method is async and returns a Future, so the window never waits (N2).
/// Uses dart:io's own HTTP client: no extra package, and no plugin, so Windows
/// Developer Mode is not needed.
class ApiClient {
  ApiClient(this.baseUrl, this.session, {required this.serviceName, this.timeout = const Duration(seconds: 8)});

  final String baseUrl;
  final Session session;

  /// Named in messages, e.g. "The book catalog is not answering".
  final String serviceName;

  /// How long to wait for an answer before saying the service is not answering.
  final Duration timeout;

  // One client per service reuses its connection, which saves time on every call (N1).
  final HttpClient _http = HttpClient();

  Future<dynamic> get(String path) => _send('GET', path, null);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);
  Future<dynamic> put(String path, Object? body) => _send('PUT', path, body);
  Future<dynamic> patch(String path, Object? body) => _send('PATCH', path, body);

  Future<dynamic> _send(String method, String path, Object? body) async {
    final token = session.token;
    final int status;
    final String text;
    final bool isJson;
    try {
      final request = await _http.openUrl(method, Uri.parse('$baseUrl$path')).timeout(timeout);
      if (token != null) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(timeout);
      text = await utf8.decoder.bind(response).join().timeout(timeout);
      status = response.statusCode;
      isJson = response.headers.contentType?.mimeType == 'application/json';
    } on SocketException {
      throw _notAnswering();
    } on HttpException {
      throw _notAnswering();
    } on TimeoutException {
      throw _notAnswering();
    }

    final decoded = isJson && text.isNotEmpty ? _tryJson(text) : null;
    if (status >= 200 && status < 300) return isJson ? decoded : text;

    final message = decoded is Map && decoded['error'] is String ? decoded['error'] as String : _fallback(status);
    // A 401 on a request that carried a token means the session has ended: back to log in.
    // (A 401 without a token is a wrong password at login, and is only a message.)
    if (status == 401 && token != null) session.clear(message: message);
    throw ApiException(message, status);
  }

  ApiException _notAnswering() => ApiException('$serviceName is not answering. Please try again in a moment.', 0);

  static Object? _tryJson(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  static String _fallback(int status) => switch (status) {
    401 => 'Your session has ended. Please log in again.',
    403 => 'You are not allowed to do this.',
    404 => 'This could not be found.',
    _ => 'Something went wrong on the server. Please try again.',
  };
}
