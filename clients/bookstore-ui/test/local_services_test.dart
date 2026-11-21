import 'dart:async';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A stand-in computer: which ports answer, and what running the start script does.
class FakeComputer {
  FakeComputer({required this.up, this.script = r'C:\server\scripts\start-services.ps1', this.scriptStartsThem = true});

  final Set<int> up;
  final String? script;
  final bool scriptStartsThem;
  final List<String> ran = [];
  Completer<void>? hold; // keeps the script "running" until completed

  LocalServices services() => LocalServices(
    isListening: (port) async => up.contains(port),
    findScript: () => script,
    run: (path) async {
      ran.add(path);
      await hold?.future;
      if (scriptStartsThem) up.addAll(LocalServices.servicePorts);
      return scriptStartsThem ? 0 : 1;
    },
  );
}

void main() {
  group('LocalServices', () {
    test('when the three services answer, nothing is started', () async {
      final pc = FakeComputer(up: {8081, 8082, 8083});
      expect(await pc.services().ensureRunning(), isNull);
      expect(pc.ran, isEmpty);
    });

    test('when one is down, the start script runs, and then all answer', () async {
      final pc = FakeComputer(up: {8081});
      expect(await pc.services().ensureRunning(), isNull);
      expect(pc.ran, [r'C:\server\scripts\start-services.ps1']);
    });

    test('without the server folder, it says how to start them by hand', () async {
      final pc = FakeComputer(up: {}, script: null);
      final problem = await pc.services().ensureRunning();
      expect(problem, contains('start-services.cmd'));
      expect(pc.ran, isEmpty);
    });

    test('when the script cannot start them, it says so', () async {
      final pc = FakeComputer(up: {}, scriptStartsThem: false);
      final problem = await pc.services().ensureRunning();
      expect(problem, contains('could not be started'));
      expect(pc.ran, hasLength(1));
    });
  });

  testWidgets('the login form says the services are starting, and lets the user log in once they are up', (tester) async {
    final pc = FakeComputer(up: {})..hold = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBookstoreTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: LoginForm(
                users: UserApi(Session()),
                role: 'CUSTOMER',
                wrongRoleMessage: 'Wrong app',
                onLoggedIn: () {},
                localServices: pc.services(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Starting the bookstore services'), findsOneWidget);
    expect(tester.widget<AppButton>(find.widgetWithText(AppButton, 'Starting the services…')).onPressed, isNull);

    pc.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Starting the bookstore services'), findsNothing);
    expect(tester.widget<AppButton>(find.widgetWithText(AppButton, 'Log in')).onPressed, isNotNull);
  });
}
