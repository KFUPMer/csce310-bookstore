import 'dart:io';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'api/order_api.dart';
import 'api/report_api.dart';
import 'screens/login_screen.dart';

void main() => runApp(const ManagerApp());

/// The management app (FR11-FR14). Starts at the login screen; only managers get in.
///
/// Owns the [Session] and goes back to the login screen whenever it ends: on
/// logout, or when a service answers that the session is no longer valid.
class ManagerApp extends StatefulWidget {
  const ManagerApp({super.key, this.services});

  /// For tests: the services to use instead of the real ones.
  final ManagerServices? services;

  @override
  State<ManagerApp> createState() => _ManagerAppState();
}

class _ManagerAppState extends State<ManagerApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late final ManagerServices _services = widget.services ?? ManagerServices.real();
  ThemeMode _mode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _services.session.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    if (!_services.session.isLoggedIn) {
      _navigator.currentState?.pushAndRemoveUntil(fadeRoute(const LoginScreen()), (_) => false);
    }
  }

  @override
  void dispose() {
    _services.session.removeListener(_sessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ManagerScope(
      services: _services,
      isDark: _mode == ThemeMode.dark,
      toggleTheme: () => setState(() => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
      child: MaterialApp(
        title: '${MooneysSign.name} Manager',
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

/// Opens a file with the program Windows uses for it, e.g. an HTML bill in the browser.
typedef FileOpener = Future<void> Function(String path);

Future<void> _openWithWindows(String path) async {
  // "start" is part of cmd; the empty title argument stops a quoted path being taken as the title.
  await Process.run('cmd', ['/c', 'start', '', path]);
}

/// Everything the screens share: who is logged in, the three services, and the clock.
class ManagerServices {
  ManagerServices({
    required this.session,
    required this.users,
    required this.books,
    required this.orders,
    required this.reports,
    this.openFile = _openWithWindows,
    this.now = DateTime.now,
    this.localServices,
  });

  factory ManagerServices.real() {
    final session = Session();
    return ManagerServices(
      session: session,
      users: UserApi(session),
      books: BookApi(session),
      orders: OrderApi(session),
      reports: ReportApi(session),
      localServices: LocalServices(),
    );
  }

  final Session session;
  final UserApi users;
  final BookApi books;
  final OrderApi orders;
  final ReportApi reports;
  final FileOpener openFile;

  /// Starts the services on this computer if they are not running; null in tests.
  final LocalServices? localServices;

  /// Today, for the report's periods; tests give a fixed day.
  final DateTime Function() now;
}

/// Gives every screen the [ManagerServices] and the light/dark switch.
class ManagerScope extends InheritedWidget {
  const ManagerScope({super.key, required this.services, required this.isDark, required this.toggleTheme, required super.child});

  final ManagerServices services;
  final bool isDark;
  final VoidCallback toggleTheme;

  static ManagerScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ManagerScope>()!;

  @override
  bool updateShouldNotify(ManagerScope old) => isDark != old.isDark || services != old.services;
}
