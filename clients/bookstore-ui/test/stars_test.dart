import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> show(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: buildBookstoreTheme(Brightness.light),
    home: Scaffold(body: Center(child: child)),
  ),
);

List<IconData> starIcons(WidgetTester tester) => [
  for (final i in tester.widgetList<Icon>(find.byType(Icon)))
    if (i.icon == Icons.star_rounded || i.icon == Icons.star_half_rounded || i.icon == Icons.star_outline_rounded) i.icon!,
];

void main() {
  testWidgets('the rating is read out in words, with the number of reviews', (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, const RatingStars(rating: 4.3, count: 12));
    expect(find.bySemanticsLabel('Rated 4.3 out of 5 from 12 reviews'), findsOneWidget);
    expect(find.text('4.3 · 12 reviews'), findsOneWidget);
    await show(tester, const RatingStars(rating: 5, count: 1));
    expect(find.bySemanticsLabel('Rated 5.0 out of 5 from 1 review'), findsOneWidget);
    expect(find.text('5.0 · 1 review'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a single review shows only its stars, read out as stars', (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, const RatingStars(rating: 4));
    expect(find.bySemanticsLabel('Rated 4 out of 5 stars'), findsOneWidget);
    expect(find.byType(Text), findsNothing);
    semantics.dispose();
  });

  testWidgets('the compact form, for the cards, is one star with the average and the count', (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, const RatingStars(rating: 4.3, count: 12, compact: true));
    expect(find.text('4.3 (12)'), findsOneWidget);
    expect(starIcons(tester), [Icons.star_rounded]);
    expect(find.bySemanticsLabel('Rated 4.3 out of 5 from 12 reviews'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('stars are filled, half, or outlined: told by shape, not by color', (tester) async {
    await show(tester, const RatingStars(rating: 3.5));
    expect(starIcons(tester), [Icons.star_rounded, Icons.star_rounded, Icons.star_rounded, Icons.star_half_rounded, Icons.star_outline_rounded]);
    await show(tester, const RatingStars(rating: 4.3));
    expect(starIcons(tester), [Icons.star_rounded, Icons.star_rounded, Icons.star_rounded, Icons.star_rounded, Icons.star_half_rounded]);
    await show(tester, const RatingStars(rating: 4.8));
    expect(starIcons(tester), List.filled(5, Icons.star_rounded));
    await show(tester, const RatingStars(rating: 1.1));
    expect(starIcons(tester), [Icons.star_rounded, ...List.filled(4, Icons.star_outline_rounded)]);
  });

  group('StarPicker', () {
    Future<List<int>> picker(WidgetTester tester, {int? value}) async {
      final chosen = <int>[];
      await show(tester, StarPicker(value: value, onChanged: chosen.add));
      return chosen;
    }

    testWidgets('each star has a tooltip and a name, "1 star" to "5 stars"', (tester) async {
      final semantics = tester.ensureSemantics();
      await picker(tester);
      for (final name in ['1 star', '2 stars', '3 stars', '4 stars', '5 stars']) {
        expect(find.byTooltip(name), findsOneWidget);
        expect(find.bySemanticsLabel(name), findsOneWidget);
      }
      semantics.dispose();
    });

    testWidgets('the chosen stars are filled, the rest outlined, and the choice is said in words', (tester) async {
      final semantics = tester.ensureSemantics();
      await picker(tester, value: 3);
      expect(starIcons(tester), [Icons.star_rounded, Icons.star_rounded, Icons.star_rounded, Icons.star_outline_rounded, Icons.star_outline_rounded]);
      expect(find.text('3 of 5 stars'), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel('3 stars')), isSemantics(label: '3 stars', isButton: true, isSelected: true));
      expect(tester.getSemantics(find.bySemanticsLabel('2 stars')), isSemantics(label: '2 stars', isButton: true, isSelected: false));
      await picker(tester);
      expect(starIcons(tester), List.filled(5, Icons.star_outline_rounded));
      expect(find.text('No stars chosen'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a click chooses a star', (tester) async {
      final chosen = await picker(tester);
      await tester.tap(find.byTooltip('4 stars'));
      expect(chosen, [4]);
    });

    testWidgets('Tab reaches each star, and Enter or Space chooses it', (tester) async {
      final chosen = await picker(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(chosen, [2, 3]);
    });
  });
}
