import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_app/main.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

/// How much room the home bar leaves for the logged-in name, measured with the real typeface.
/// In its own file because a loaded font stays for the rest of the file, and the other screen
/// tests keep the wider test font as the worst case.
void main() {
  testWidgets('a usual username is shown in full in the smallest 1024 x 700 window', (tester) async {
    await tester.runAsync(loadRealFonts);
    tester.view.physicalSize = const Size(1024, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ManagerApp(services: fakeServices()));
    await tester.pumpAndSettle();
    const name = 'store.manager.2026';
    await tester.enterText(find.byType(TextField).at(0), name);
    await tester.enterText(find.byType(TextField).at(1), 'right-password');
    await tester.tap(find.widgetWithText(AppButton, 'Log in'));
    await tester.pumpAndSettle();

    final text = tester.renderObject<RenderParagraph>(find.text(name));
    expect(text.didExceedMaxLines, isFalse, reason: 'an 18-character name is not cut short at 1024 px');
    await tester.pumpAndSettle(const Duration(seconds: 7));
  });
}
