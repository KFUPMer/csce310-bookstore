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

/// An order, as order-service returns it. Used by both apps.
///
/// A row of the manager's list (GET /api/orders) has no items and no email; a
/// whole order (POST /api/orders, GET /api/orders/{id}) has both.
class Order {
  const Order({
    required this.id,
    required this.username,
    required this.createdAt,
    required this.paymentStatus,
    required this.total,
    this.email,
    this.items = const [],
    this.emailQueued = false,
  });

  final int id;
  final String username;
  final String? email;
  final DateTime createdAt;

  /// PENDING or PAID (FR13).
  final String paymentStatus;
  final List<PlacedItem> items;
  final double total;

  /// True when the bill is being emailed to the customer (FR10). Not a promise it arrived.
  final bool emailQueued;

  static const pending = 'PENDING';
  static const paid = 'PAID';

  bool get isPaid => paymentStatus == paid;

  Order copyWith({String? paymentStatus}) => Order(
    id: id,
    username: username,
    email: email,
    createdAt: createdAt,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    total: total,
    items: items,
    emailQueued: emailQueued,
  );

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as int,
    username: json['username'] as String,
    email: json['email'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    paymentStatus: json['paymentStatus'] as String,
    items: [for (final i in json['items'] as List? ?? const []) PlacedItem.fromJson(i as Map<String, dynamic>)],
    total: (json['total'] as num).toDouble(),
    emailQueued: json['emailQueued'] as bool? ?? false,
  );
}
