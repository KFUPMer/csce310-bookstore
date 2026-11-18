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

  test('a book has its shelf, read from and sent back to book-service', () {
    final b = Book.fromJson({'id': 'abc', 'title': 'Matilda', 'author': 'Roald Dahl', 'price': 8.99, 'copiesAvailable': 4, 'category': 'Kids'});
    expect(b.category, 'Kids');
    expect(b.toJson()['category'], 'Kids');
    final old = Book.fromJson({'id': 'abc', 'title': 'Old', 'author': 'Someone', 'price': 1, 'copiesAvailable': 1});
    expect(old.category, isNull, reason: 'a book stored before shelves existed');
  });

  test('the shelves are the five book-service accepts, in the order the apps show them', () {
    expect(categories, ['Fiction', 'Nonfiction', 'Kids', 'Science', 'Technology']);
  });

  test('a book is built from the JSON that book-service returns', () {
    final b = Book.fromJson({'id': 'abc', 'title': 'Clean Code', 'author': 'Robert C. Martin', 'price': 40, 'copiesAvailable': 4, 'coverUrl': null});
    expect(b.title, 'Clean Code');
    expect(b.price, 40.0);
    expect(b.coverUrl, isNull);
  });

  test('a book has its rating from the reviews, and none when book-service sends none', () {
    final rated = Book.fromJson({
      'id': 'abc',
      'title': 'Matilda',
      'author': 'Roald Dahl',
      'price': 8.99,
      'copiesAvailable': 4,
      'ratingAverage': 4.3,
      'ratingCount': 12,
    });
    expect(rated.ratingAverage, 4.3);
    expect(rated.ratingCount, 12);
    final whole = Book.fromJson({'id': 'abc', 'title': 'M', 'author': 'R', 'price': 1, 'copiesAvailable': 1, 'ratingAverage': 4, 'ratingCount': 1});
    expect(whole.ratingAverage, 4.0, reason: 'a whole number in the JSON is still a double');
    final none = Book.fromJson({'id': 'abc', 'title': 'M', 'author': 'R', 'price': 1, 'copiesAvailable': 1, 'ratingAverage': null, 'ratingCount': 0});
    expect(none.ratingAverage, isNull);
    expect(none.ratingCount, 0);
    final old = Book.fromJson({'id': 'abc', 'title': 'M', 'author': 'R', 'price': 1, 'copiesAvailable': 1});
    expect(old.ratingAverage, isNull, reason: 'a service without reviews sends no rating at all');
    expect(old.ratingCount, 0);
  });

  test('the rating is not sent back when a manager saves a book: it comes from the reviews', () {
    final b = Book.fromJson({'id': 'abc', 'title': 'M', 'author': 'R', 'price': 1, 'copiesAvailable': 1, 'ratingAverage': 4.3, 'ratingCount': 12});
    expect(b.toJson().containsKey('ratingAverage'), isFalse);
    expect(b.toJson().containsKey('ratingCount'), isFalse);
  });

  test('money is shown with two decimals and thousands separators', () {
    expect(money(4), '\$4.00');
    expect(money(12345.6), '\$12,345.60');
  });
}
