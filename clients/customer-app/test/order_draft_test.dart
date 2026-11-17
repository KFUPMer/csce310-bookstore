import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:customer_app/models/order_draft.dart';
import 'package:flutter_test/flutter_test.dart';

const cleanCode = Book(id: 'aaaaaaaaaaaaaaaaaaaaaaaa', title: 'Clean Code', author: 'Robert C. Martin', price: 40, copiesAvailable: 4);
const concurrency = Book(
  id: 'bbbbbbbbbbbbbbbbbbbbbbbb',
  title: 'Java Concurrency in Practice',
  author: 'Brian Goetz',
  price: 35.55,
  copiesAvailable: 1,
);
const soldOut = Book(id: 'cccccccccccccccccccccccc', title: 'MongoDB', author: 'Shannon Bradshaw', price: 44, copiesAvailable: 0);

void main() {
  late OrderDraft draft;
  late int changes;

  setUp(() {
    draft = OrderDraft();
    changes = 0;
    draft.addListener(() => changes++);
  });

  test('starts empty', () {
    expect(draft.isEmpty, isTrue);
    expect(draft.total, 0);
  });

  test('adds a book as bought or rented and tells its listeners', () {
    expect(draft.add(cleanCode, ItemType.buy), isTrue);
    expect(draft.add(concurrency, ItemType.rent), isTrue);
    expect(draft.items.map((i) => (i.book.title, i.type)), [('Clean Code', ItemType.buy), ('Java Concurrency in Practice', ItemType.rent)]);
    expect(draft.contains(cleanCode), isTrue);
    expect(changes, 2);
  });

  test('a book cannot be added twice, and a sold-out book not at all', () {
    draft.add(cleanCode, ItemType.buy);
    expect(draft.add(cleanCode, ItemType.rent), isFalse);
    expect(draft.add(soldOut, ItemType.buy), isFalse);
    expect(draft.items.length, 1);
  });

  test('the total is the sum of the charges, exact to the cent', () {
    draft.add(cleanCode, ItemType.buy); // 40.00
    draft.add(concurrency, ItemType.rent); // 10% of 35.55 = 3.56
    expect(draft.total, 43.56);
  });

  test('switching between buy and rent changes the charge', () {
    draft.add(cleanCode, ItemType.buy);
    draft.setType(draft.items.first, ItemType.rent);
    expect(draft.items.first.type, ItemType.rent);
    expect(draft.total, 4.0);
  });

  test('a removed book can be put back where it was (Undo)', () {
    draft.add(cleanCode, ItemType.buy);
    draft.add(concurrency, ItemType.rent);
    final removed = draft.items.first;
    final index = draft.remove(removed);
    expect(draft.items.length, 1);
    draft.restore(removed, index);
    expect(draft.items.map((i) => i.book.title), ['Clean Code', 'Java Concurrency in Practice']);
  });

  test('a rented book is due back 7 days after the order', () {
    draft.add(concurrency, ItemType.rent);
    draft.add(cleanCode, ItemType.buy);
    final today = DateTime(2026, 11, 17, 15, 30);
    expect(draft.items.first.dueBack(today), DateTime(2026, 11, 24));
    expect(draft.items.last.dueBack(today), isNull);
  });

  test('is sent to order-service as book ids and types', () {
    draft.add(cleanCode, ItemType.buy);
    draft.add(concurrency, ItemType.rent);
    expect(draft.toJson(), {
      'items': [
        {'bookId': cleanCode.id, 'type': 'BUY'},
        {'bookId': concurrency.id, 'type': 'RENT'},
      ],
    });
  });

  test('clear empties it after the order is placed', () {
    draft.add(cleanCode, ItemType.buy);
    draft.clear();
    expect(draft.isEmpty, isTrue);
  });
}
