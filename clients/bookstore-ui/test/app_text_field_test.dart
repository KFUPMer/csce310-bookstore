import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('a field of several lines grows to them and keeps new lines', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBookstoreTheme(Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: AppTextField(label: 'Your review', controller: controller, lines: 4),
          ),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 4);
    expect(field.maxLines, 4);
    expect(field.keyboardType, TextInputType.multiline);
    expect(tester.getSize(find.byType(TextField)).height, greaterThan(44), reason: 'not the one-line height');
    await tester.enterText(find.byType(TextField), 'Line one\nLine two');
    expect(controller.text, 'Line one\nLine two');
  });
}
