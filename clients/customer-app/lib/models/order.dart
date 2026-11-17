import 'book.dart';

/// One line of a placed order, as order-service charged it.
class PlacedItem {
  const PlacedItem({required this.title, required this.author, required this.type, required this.quantity, required this.unitPrice, this.dueBack});

  final String title;
  final String author;
  final ItemType type;
  final int quantity;

  /// What was charged for one copy.
  final double unitPrice;

  /// When a rented book is due back; null when bought.
  final DateTime? dueBack;

  factory PlacedItem.fromJson(Map<String, dynamic> json) => PlacedItem(
    title: json['title'] as String,
    author: json['author'] as String,
    type: ItemType.fromJson(json['type'] as String),
    quantity: json['quantity'] as int,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    dueBack: json['rentDueDate'] == null ? null : DateTime.parse(json['rentDueDate'] as String),
  );
}

/// A placed order with its bill, as returned by POST /api/orders (FR8).
class Order {
  const Order({
    required this.id,
    required this.username,
    required this.createdAt,
    required this.paymentStatus,
    required this.items,
    required this.total,
    required this.emailQueued,
  });

  final int id;
  final String username;
  final DateTime createdAt;
  final String paymentStatus;
  final List<PlacedItem> items;
  final double total;

  /// True when the bill is being emailed to the customer (FR10). Not a promise it arrived.
  final bool emailQueued;

  bool get isPaid => paymentStatus == 'PAID';

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as int,
    username: json['username'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    paymentStatus: json['paymentStatus'] as String,
    items: [for (final i in json['items'] as List) PlacedItem.fromJson(i as Map<String, dynamic>)],
    total: (json['total'] as num).toDouble(),
    emailQueued: json['emailQueued'] as bool? ?? false,
  );
}
