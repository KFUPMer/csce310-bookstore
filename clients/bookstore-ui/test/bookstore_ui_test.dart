import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a title always gets the same cover hue', () {
    expect(BookCover.hueFor('Clean Code'), BookCover.hueFor('Clean Code'));
    expect(BookCover.hueFor('Clean Code'), inInclusiveRange(0, 359));
  });

  test('different titles usually get different hues', () {
    final hues = {
      for (final t in ['Clean Code', 'Refactoring', 'Effective Java', 'Design Patterns']) BookCover.hueFor(t),
    };
    expect(hues.length, greaterThan(2));
  });
}
