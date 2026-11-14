import 'package:customer_app/models/book.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renting costs 10% of the price', () {
    const book = Book(id: '1', title: 'Java Concurrency in Practice', author: 'Brian Goetz', price: 80, copiesAvailable: 6);
    expect(book.rentPrice, 8.0);
    expect(money(book.rentPrice), '\$8.00');
  });

  test('a book with no copies is not available', () {
    const book = Book(id: '2', title: 'T', author: 'A', price: 44, copiesAvailable: 0);
    expect(book.isAvailable, isFalse);
  });

  test('a book is built from the JSON that book-service returns', () {
    final book = Book.fromJson({'id': 'abc', 'title': 'Clean Code', 'author': 'Robert C. Martin', 'price': 40, 'copiesAvailable': 4});
    expect(book.title, 'Clean Code');
    expect(book.price, 40.0);
    expect(book.coverUrl, isNull);
  });
}
