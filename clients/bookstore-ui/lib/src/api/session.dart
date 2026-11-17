import 'package:flutter/foundation.dart';

/// Who is logged in (FR1, FR2). The token is sent with every request (N4).
///
/// Kept only in memory: closing the app logs the customer out. The app listens
/// to it, so when the session ends (logout, or a 401 from a service) it goes
/// back to the login screen by itself.
class Session extends ChangeNotifier {
  String? _token;
  int? userId;
  String? username;
  String? email;
  String? role;

  /// Why the last session ended, when it was not by logging out. Shown on the login screen.
  String? endedMessage;

  String? get token => _token;
  bool get isLoggedIn => _token != null;

  void start({required String token, required int userId, required String username, required String email, required String role}) {
    _token = token;
    this.userId = userId;
    this.username = username;
    this.email = email;
    this.role = role;
    endedMessage = null;
    notifyListeners();
  }

  /// Forget the session. [message] says why, when it was not the customer's choice.
  void clear({String? message}) {
    _token = userId = username = email = role = null;
    endedMessage = message;
    notifyListeners();
  }
}
