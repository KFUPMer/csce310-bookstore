/// The rules for a new account (FR3), the same ones user-service applies.
///
/// Checked in the app first so each problem appears next to its field before
/// anything is sent. user-service still checks again: the app is not trusted.
Map<String, String> checkRegistration({required String username, required String email, required String password, required String confirm}) {
  final problems = <String, String>{};
  final name = username.trim();
  if (name.isEmpty) {
    problems['username'] = 'Choose a username';
  } else if (name.length < 3) {
    problems['username'] = 'At least 3 characters';
  } else if (name.length > 50) {
    problems['username'] = 'At most 50 characters';
  } else if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name)) {
    problems['username'] = 'Only letters, digits, dots, dashes, and underscores';
  }

  final mail = email.trim();
  if (mail.isEmpty) {
    problems['email'] = 'Enter your email address';
  } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) {
    problems['email'] = 'This does not look like an email address';
  }

  if (password.length < 8) {
    problems['password'] = 'At least 8 characters';
  } else if (password.length > 72) {
    problems['password'] = 'At most 72 characters';
  }
  if (confirm != password) problems['confirm'] = 'The two passwords are not the same';
  return problems;
}
