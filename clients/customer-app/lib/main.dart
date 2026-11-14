import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/search_screen.dart';

/// Start-up options, only used to take screenshots of the style preview:
///   --dark        start in dark mode
///   --list        start in list view
///   --select=N    open the detail panel of the book with id N
///   --query=TEXT  start with TEXT in the search field
void main(List<String> args) {
  String? option(String name) {
    for (final a in args) {
      if (a.startsWith('--$name=')) return a.substring(name.length + 3);
    }
    return null;
  }

  runApp(
    CustomerApp(startDark: args.contains('--dark'), startList: args.contains('--list'), startSelected: option('select'), startQuery: option('query') ?? ''),
  );
}

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key, this.startDark = false, this.startList = false, this.startSelected, this.startQuery = ''});

  final bool startDark;
  final bool startList;
  final String? startSelected;
  final String startQuery;

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  late ThemeMode _mode = widget.startDark ? ThemeMode.dark : ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookstore',
      debugShowCheckedModeBanner: false,
      theme: buildBookstoreTheme(Brightness.light),
      darkTheme: buildBookstoreTheme(Brightness.dark),
      themeMode: _mode,
      themeAnimationDuration: Motion.slow,
      themeAnimationCurve: Motion.curve,
      home: SearchScreen(
        isDark: _mode == ThemeMode.dark,
        onToggleTheme: () => setState(() => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
        startList: widget.startList,
        startSelected: widget.startSelected,
        startQuery: widget.startQuery,
      ),
    );
  }
}
