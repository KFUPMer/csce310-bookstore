import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'api/apis.dart';
import 'models/order_draft.dart';
import 'models/preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _services.session.addListener(_sessionChanged);
    _services.preferences.addListener(_preferencesChanged);
  }

  void _sessionChanged() {
    final session = _services.session;
    if (session.isLoggedIn) {
      _services.preferences.loadFor(session.username!); // this customer's dark mode and view
      return;
    }
    // The session ended: forget the order being prepared and go back to log in.
    _services.draft.clear();
    _services.preferences.forget();
    _navigator.currentState?.pushAndRemoveUntil(fadeRoute(const LoginScreen()), (_) => false);
  }

  void _preferencesChanged() => setState(() {});

  @override
  void dispose() {
    _services.session.removeListener(_sessionChanged);
    _services.preferences.removeListener(_preferencesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = _services.preferences.darkMode;
    return AppScope(
      services: _services,
      isDark: dark,
      toggleTheme: () => _services.preferences.update(darkMode: !dark),
      child: MaterialApp(
        title: MooneysSign.name,
        debugShowCheckedModeBanner: false,
        theme: buildBookstoreTheme(Brightness.light),
        darkTheme: buildBookstoreTheme(Brightness.dark),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
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
/// the customer's preferences, and the three services.
class AppServices {
  AppServices({
    required this.session,
    required this.draft,
    required this.users,
    required this.books,
    required this.orders,
    required this.preferences,
    this.now = DateTime.now,
    this.localServices,
  });

  factory AppServices.real() {
    final session = Session();
    return AppServices(
      session: session,
      draft: OrderDraft(),
      users: UserApi(session),
      books: BookApi(session),
      orders: OrderApi(session),
      preferences: Preferences.onThisComputer(),
      localServices: LocalServices(),
    );
  }

  final Session session;
  final OrderDraft draft;
  final UserApi users;
  final BookApi books;
  final OrderApi orders;
  final Preferences preferences;

  /// Today's date and time; tests fix it, so "due back in 7 days" does not depend on the day they run.
  final DateTime Function() now;

  /// Starts the services on this computer if they are not running; null in tests.
  final LocalServices? localServices;
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
