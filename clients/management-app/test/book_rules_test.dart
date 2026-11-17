import 'package:flutter_test/flutter_test.dart';
import 'package:management_app/models/book_rules.dart';

/// The same rules book-service applies to a new or changed book (api-design.md).
void main() {
  BookCheck check({String title = 'Clean Code', String author = 'Robert C. Martin', String price = '40', String copies = '4', String cover = ''}) =>
      checkBook(title: title, author: author, price: price, copies: copies, coverUrl: cover);

  test('a correct book has no problems, and its values are read', () {
    final c = check(price: ' 42.5 ', cover: 'https://example.com/c.jpg');
    expect(c.problems, isEmpty);
    expect((c.price, c.copies, c.coverUrl), (42.5, 4, 'https://example.com/c.jpg'));
  });

  test('an empty cover address means no cover', () {
    expect(check().coverUrl, isNull);
  });

  test('title and author are needed, and at most 255 characters', () {
    expect(check(title: '  ').problems['title'], 'Enter the title');
    expect(check(author: '').problems['author'], 'Enter the author');
    expect(check(title: 'x' * 256).problems['title'], 'At most 255 characters');
  });

  test('the price is a number above 0, at most 100,000, with at most two decimals', () {
    expect(check(price: '').problems['price'], 'Enter the price');
    expect(check(price: 'forty').problems['price'], 'Enter the price as a number, e.g. 40.00');
    expect(check(price: '0').problems['price'], 'The price must be more than 0');
    expect(check(price: '100001').problems['price'], 'The price can be at most 100,000');
    expect(check(price: '9.999').problems['price'], 'At most two decimals');
  });

  test('copies are a whole number from 0 to 1,000,000', () {
    expect(check(copies: '').problems['copies'], 'Enter the number of copies');
    expect(check(copies: '2.5').problems['copies'], 'Enter a whole number');
    expect(check(copies: '-1').problems['copies'], 'Copies cannot be negative');
    expect(check(copies: '1000001').problems['copies'], 'At most 1,000,000 copies');
    expect(check(copies: '0').problems, isEmpty, reason: 'a sold-out book is allowed');
  });

  test('a cover address must start with http:// or https://', () {
    expect(check(cover: 'example.com/c.jpg').problems['cover'], 'Start the address with http:// or https://');
  });
}
