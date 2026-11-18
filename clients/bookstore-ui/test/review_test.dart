import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a review is built from the JSON that book-service returns', () {
    final r = Review.fromJson({
      'id': 'f' * 24,
      'bookId': 'a' * 24,
      'username': 'alice',
      'rating': 4,
      'text': 'Loved it',
      'createdAt': '2026-11-18T10:05:00',
      'updatedAt': '2026-11-19T08:30:00',
    });
    expect(r.id, 'f' * 24);
    expect(r.bookId, 'a' * 24);
    expect(r.username, 'alice');
    expect(r.rating, 4);
    expect(r.text, 'Loved it');
    expect(r.createdAt, DateTime(2026, 11, 18, 10, 5));
    expect(r.updatedAt, DateTime(2026, 11, 19, 8, 30), reason: 'local times, like the rest of the project');
  });

  test('a review without words has empty text', () {
    final json = {
      'id': 'f' * 24,
      'bookId': 'a' * 24,
      'username': 'bob',
      'rating': 5,
      'createdAt': '2026-11-18T10:05:00',
      'updatedAt': '2026-11-18T10:05:00',
    };
    expect(Review.fromJson({...json, 'text': ''}).text, '');
    expect(Review.fromJson(json).text, '');
    expect(Review.fromJson({...json, 'text': null}).text, '');
  });
}
