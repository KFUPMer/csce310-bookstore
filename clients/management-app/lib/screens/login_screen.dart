import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';
import 'home_screen.dart';

/// Manager log in (FR1, FR11). A customer account is refused (N5).
/// The form is shared with the customer app (bookstore-ui `LoginForm`).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ManagerScope.of(context);
    return AuthLayout(
      tagline: 'Run Mooney’s.',
      note: 'Orders and payments, and the books on the shelf.',
      coverTitles: const ['Clean Code', 'Atomic Habits', 'The Selfish Gene'],
      coverUrls: const [
        'https://covers.openlibrary.org/b/id/8065615-L.jpg',
        'https://covers.openlibrary.org/b/id/12539702-L.jpg',
        'https://covers.openlibrary.org/b/id/133936-L.jpg',
      ],
      actions: [
        AppIconButton(
          icon: scope.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          tooltip: scope.isDark ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: scope.toggleTheme,
        ),
      ],
      child: LoginForm(
        users: scope.services.users,
        role: 'MANAGER',
        wrongRoleMessage: 'This app is for managers. Customers log in to the customer app.',
        subtitle: 'Management. For store staff only.',
        note: scope.services.session.endedMessage,
        localServices: scope.services.localServices,
        onLoggedIn: () => Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen())),
      ),
    );
  }
}
