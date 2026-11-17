import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Book book({double price = 40, int copies = 4}) =>
    Book(id: 'a' * 24, title: 'Clean Code', author: 'Robert C. Martin', price: price, copiesAvailable: copies);

void main() {
  test('renting costs 10% of the price', () {
    expect(book(price: 80).rentPrice, 8.0);
    expect(money(book(price: 80).rentPrice), '\$8.00');
  });

  test('the rent price is rounded to the cent half up, exactly as order-service charges it', () {
    // 35.55 is stored as 35.54999...; rounding the float would give 3.55, but the bill says 3.56.
    expect(book(price: 35.55).rentPrice, 3.56);
    expect(book(price: 35.54).rentPrice, 3.55);
    expect(book(price: 0.01).rentPrice, 0.0);
  });

  test('a book with no copies is not available', () {
    expect(book(copies: 0).isAvailable, isFalse);
  });

  test('a book is built from the JSON that book-service returns', () {
    final b = Book.fromJson({'id': 'abc', 'title': 'Clean Code', 'author': 'Robert C. Martin', 'price': 40, 'copiesAvailable': 4, 'coverUrl': null});
    expect(b.title, 'Clean Code');
    expect(b.price, 40.0);
    expect(b.coverUrl, isNull);
  });

  test('money is shown with two decimals and thousands separators', () {
    expect(money(4), '\$4.00');
    expect(money(12345.6), '\$12,345.60');
  });
}
