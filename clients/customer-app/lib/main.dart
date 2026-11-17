import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'api/apis.dart';
import 'api/session.dart';
import 'models/order_draft.dart';
import 'screens/login_screen.dart';

void main() => runApp(const CustomerApp());

/// The customer app (FR1-FR8). Starts at the login screen.
///
/// Owns the [Session] and the [OrderDraft], so they outlive any one screen,
/// and goes back to the login screen whenever the session ends: on logout, or
/// when a service answers that the session is no longer valid.
class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key, this.services});

  /// For tests: the services to use instead of the real ones.
  final AppServices? services;

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late final AppServices _services = widget.services ?? AppServices.real();
  ThemeMode _mode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _services.session.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    if (_services.session.isLoggedIn) return;
    // The session ended: forget the order being prepared and go back to log in.
    _services.draft.clear();
    _navigator.currentState?.pushAndRemoveUntil(fadeRoute(const LoginScreen()), (_) => false);
  }

  @override
  void dispose() {
    _services.session.removeListener(_sessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: _services,
      isDark: _mode == ThemeMode.dark,
      toggleTheme: () => setState(() => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
      child: MaterialApp(
        title: 'Bookstore',
        debugShowCheckedModeBanner: false,
        theme: buildBookstoreTheme(Brightness.light),
        darkTheme: buildBookstoreTheme(Brightness.dark),
        themeMode: _mode,
        themeAnimationDuration: Motion.slow,
        themeAnimationCurve: Motion.curve,
        navigatorKey: _navigator,
        builder: (context, child) => ToastHost(child: child!),
        home: const LoginScreen(),
      ),
    );
  }
}

/// Everything the screens share: who is logged in, the order being prepared,
/// and the three services.
class AppServices {
  AppServices({required this.session, required this.draft, required this.users, required this.books, required this.orders});

  factory AppServices.real() {
    final session = Session();
    return AppServices(session: session, draft: OrderDraft(), users: UserApi(session), books: BookApi(session), orders: OrderApi(session));
  }

  final Session session;
  final OrderDraft draft;
  final UserApi users;
  final BookApi books;
  final OrderApi orders;
}

/// Gives every screen the [AppServices] and the light/dark switch.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required this.isDark, required this.toggleTheme, required super.child});

  final AppServices services;
  final bool isDark;
  final VoidCallback toggleTheme;

  static AppScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) => isDark != old.isDark || services != old.services;
}
