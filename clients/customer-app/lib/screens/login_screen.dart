import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';
import 'register_screen.dart';
import 'search_screen.dart';

/// Log in (FR1). The first screen, and where the app returns when the session ends.
/// The form itself is shared with the management app (bookstore-ui `LoginForm`).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// After creating an account: the new username, and a note saying so.
  String? _newUsername;
  String? _accountNote;

  Future<void> _openRegister() async {
    final username = await Navigator.of(context).push<String>(fadeRoute(const RegisterScreen()));
    if (username == null || !mounted) return;
    // FR3: the new account is ready; log in with it.
    setState(() {
      _newUsername = username;
      _accountNote = 'Account created. Log in with your new password.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final services = scope.services;
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;

    return AuthLayout(
      tagline: 'Find a book. Buy it, or rent it for a week.',
      note: 'Search the catalog by title or author. Renting costs 10% of the price.',
      coverTitles: const ['Nineteen Eighty-Four', 'Matilda', 'Cosmos'],
      coverUrls: const [
        'https://covers.openlibrary.org/b/isbn/9780451524935-L.jpg',
        'https://covers.openlibrary.org/b/id/12889769-L.jpg',
        'https://covers.openlibrary.org/b/id/8283901-L.jpg',
      ],
      actions: [
        AppIconButton(
          icon: scope.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          tooltip: scope.isDark ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: scope.toggleTheme,
        ),
      ],
      child: LoginForm(
        // A new key after registering, so the form starts again with the new username.
        key: ValueKey(_newUsername),
        users: services.users,
        role: 'CUSTOMER',
        wrongRoleMessage: 'This app is for customers. Managers log in to the management app.',
        note: _accountNote ?? services.session.endedMessage,
        initialUsername: _newUsername,
        localServices: services.localServices,
        onLoggedIn: () => Navigator.of(context).pushReplacement(fadeRoute(const SearchScreen())),
        // Wraps rather than overflows if the text is larger (e.g. Windows text scaling).
        footer: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('New here?', style: t.bodyMedium!.copyWith(color: c.textSecondary)),
            const SizedBox(width: Space.xs),
            AppButton(label: 'Create an account', style: AppButtonStyle.quiet, onPressed: _openRegister),
          ],
        ),
      ),
    );
  }
}
