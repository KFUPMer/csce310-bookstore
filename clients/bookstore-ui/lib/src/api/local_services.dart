import 'dart:io';

/// Starts the three bookstore services on this computer when an app opens and they are not running,
/// so a user never has to start them by hand.
///
/// It runs the same script as `start-services.cmd` (`scripts/start-services.ps1`), with its windows
/// hidden. The services keep running after the app closes: the other app, and the next start, find
/// them ready. `stop-services.cmd` stops them.
///
/// The server folder is the one `setup.cmd` recorded in `%APPDATA%\CSCE310 Bookstore\server-folder.txt`;
/// failing that, a folder above the app's own program (an app built inside the repository).
class LocalServices {
  LocalServices({Future<bool> Function(int port)? isListening, String? Function()? findScript, Future<int> Function(String script)? run})
    : _isListening = isListening ?? _portAnswers,
      _findScript = findScript ?? _scriptOnThisComputer,
      _run = run ?? _runHidden;

  /// user-service, book-service, order-service.
  static const servicePorts = [8081, 8082, 8083];

  final Future<bool> Function(int port) _isListening;
  final String? Function() _findScript;
  final Future<int> Function(String script) _run;

  /// Null when the services are running (already, or once started); otherwise what to tell the user.
  Future<String?> ensureRunning() async {
    if (await _allUp()) return null;
    final script = _findScript();
    if (script == null) {
      return 'The bookstore services are not running, and their folder was not found. Run start-services.cmd in the server folder.';
    }
    final exitCode = await _run(script);
    if (exitCode == 0 && await _allUp()) return null;
    return 'The bookstore services could not be started. Run start-services.cmd in the server folder to see why.';
  }

  Future<bool> _allUp() async => (await Future.wait(servicePorts.map(_isListening))).every((up) => up);

  static Future<bool> _portAnswers(int port) async {
    try {
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, port, timeout: const Duration(milliseconds: 500));
      socket.destroy();
      return true;
    } on SocketException {
      return false;
    }
  }

  static String? _scriptOnThisComputer() {
    const script = r'scripts\start-services.ps1';
    final appData = Platform.environment['APPDATA'];
    if (appData != null) {
      final note = File('$appData\\CSCE310 Bookstore\\server-folder.txt');
      if (note.existsSync()) {
        final folder = note.readAsStringSync().replaceAll('﻿', '').trim();
        if (File('$folder\\$script').existsSync()) return '$folder\\$script';
      }
    }
    // An app built inside the repository: its program is under clients\<app>\build\...
    var dir = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 10; i++) {
      if (File('${dir.path}\\$script').existsSync()) return '${dir.path}\\$script';
      dir = dir.parent;
    }
    return null;
  }

  static Future<int> _runHidden(String script) async {
    if (!Platform.isWindows) return 1;
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-WindowStyle',
      'Hidden',
      '-File',
      script,
      '-Hidden',
    ]);
    return result.exitCode;
  }
}
