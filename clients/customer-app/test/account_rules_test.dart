import 'package:customer_app/models/account_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// The same rules user-service applies (api-design.md), checked in the app first so the
/// customer sees the problem next to the field before anything is sent.
void main() {
  Map<String, String> check({String username = 'alice', String email = 'alice@example.com', String password = 'secret123', String? confirm}) =>
      checkRegistration(username: username, email: email, password: password, confirm: confirm ?? password);

  test('a correct form has no problems', () {
    expect(check(), isEmpty);
    expect(check(username: 'a.b_c-9'), isEmpty);
  });

  test('the username is 3 to 50 letters, digits, dots, dashes, or underscores', () {
    expect(check(username: '')['username'], 'Choose a username');
    expect(check(username: 'al')['username'], 'At least 3 characters');
    expect(check(username: 'a' * 51)['username'], 'At most 50 characters');
    expect(check(username: 'al ice')['username'], 'Only letters, digits, dots, dashes, and underscores');
  });

  test('the email must look like an email', () {
    expect(check(email: '')['email'], 'Enter your email address');
    expect(check(email: 'alice')['email'], 'This does not look like an email address');
    expect(check(email: 'alice@example')['email'], 'This does not look like an email address');
  });

  test('the password is 8 to 72 characters and typed the same twice', () {
    expect(check(password: 'short')['password'], 'At least 8 characters');
    expect(check(password: 'x' * 73)['password'], 'At most 72 characters');
    expect(check(confirm: 'secret124')['confirm'], 'The two passwords are not the same');
  });

  test('every problem is reported at once, one per field', () {
    expect(check(username: '', email: '', password: '', confirm: 'x').keys, ['username', 'email', 'password', 'confirm']);
  });
}
