import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Each customer's own settings, remembered on this computer: dark mode, and
/// whether search opens as covers or as a list.
///
/// Kept in a small JSON file in the user's AppData folder, keyed by username.
/// Nothing here is secret, and nothing is sent to a service. If the file
/// cannot be read or written, the settings still work until the app closes.
class Preferences extends ChangeNotifier {
  /// [file] null keeps them in memory only (tests).
  Preferences({this.file});

  factory Preferences.onThisComputer() {
    final folder = Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
    final sep = Platform.pathSeparator;
    return Preferences(file: File('$folder${sep}CSCE310 Bookstore${sep}preferences.json'));
  }

  /// Where they are kept.
  final File? file;
  String? _user;
  bool _darkMode = false;
  bool _listView = false;

  bool get darkMode => _darkMode;
  bool get listView => _listView;

  /// Switch to [username]'s settings, or the defaults if they have none yet.
  void loadFor(String username) {
    _user = username;
    final mine = _readAll()[username];
    _darkMode = mine is Map && mine['darkMode'] == true;
    _listView = mine is Map && mine['listView'] == true;
    notifyListeners();
  }

  /// After logging out: the look stays as it is, but a change is no longer saved for the last customer.
  void forget() => _user = null;

  void update({bool? darkMode, bool? listView}) {
    _darkMode = darkMode ?? _darkMode;
    _listView = listView ?? _listView;
    notifyListeners();
    final user = _user;
    if (user == null) return; // before log in: applies now, remembered for nobody
    final all = _readAll()..[user] = {'darkMode': _darkMode, 'listView': _listView};
    _kept = all;
    try {
      file?.parent.createSync(recursive: true);
      file?.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(all));
    } on FileSystemException {
      // Not remembered for next time; everything else works.
    }
  }

  /// What was last saved, for when there is no file or it cannot be read.
  Map<String, dynamic> _kept = {};

  Map<String, dynamic> _readAll() {
    try {
      final file = this.file;
      if (file == null || !file.existsSync()) return {..._kept};
      final json = jsonDecode(file.readAsStringSync());
      return json is Map<String, dynamic> ? json : {..._kept};
    } on FormatException {
      return {..._kept};
    } on FileSystemException {
      return {..._kept};
    }
  }
}
