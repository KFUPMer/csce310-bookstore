import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an order is built from the answer of POST /api/orders', () {
    final order = Order.fromJson({
      'id': 1042,
      'username': 'alice',
      'createdAt': '2026-11-13T10:05:00',
      'paymentStatus': 'PENDING',
      'items': [
        {'title': 'Clean Code', 'author': 'Robert C. Martin', 'type': 'BUY', 'quantity': 1, 'unitPrice': 40.0, 'rentDueDate': null},
        {
          'title': 'Java Concurrency in Practice',
          'author': 'Brian Goetz',
          'type': 'RENT',
          'quantity': 1,
          'unitPrice': 8,
          'rentDueDate': '2026-11-20',
        },
      ],
      'total': 48.0,
      'billFile': 'bills/bill-1042.html',
      'billHtml': '<!DOCTYPE html>',
      'emailQueued': true,
    });
    expect(order.id, 1042);
    expect(order.createdAt, DateTime(2026, 11, 13, 10, 5));
    expect(order.isPaid, isFalse);
    expect(order.total, 48.0);
    expect(order.emailQueued, isTrue);
    expect(order.items.first.type, ItemType.buy);
    expect(order.items.first.dueBack, isNull);
    expect(order.items.last.type, ItemType.rent);
    expect(order.items.last.unitPrice, 8.0);
    expect(order.items.last.dueBack, DateTime(2026, 11, 20));
  });
}
