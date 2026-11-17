import 'package:bookstore_ui/bookstore_ui.dart' show toCents;

import 'package:flutter/foundation.dart';

import 'book.dart';

/// One book in the order being prepared, bought or rented.
class OrderItem {
  OrderItem(this.book, this.type);

  final Book book;
  ItemType type;

  /// What this book costs in the order: the price, or the rent price.
  double get charge => type == ItemType.buy ? book.price : book.rentPrice;

  /// When a rented book is due back if the order is placed on [orderDate]. Null when bought.
  DateTime? dueBack(DateTime orderDate) => type == ItemType.rent ? DateTime(orderDate.year, orderDate.month, orderDate.day + rentDays) : null;

  Map<String, dynamic> toJson() => {'bookId': book.id, 'type': type.json};
}

/// The order being prepared (FR6). Shared by the search and order screens, and kept
/// by the app, so it survives moving between screens and a failed attempt to order.
class OrderDraft extends ChangeNotifier {
  final List<OrderItem> _items = [];

  List<OrderItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;

  bool contains(Book book) => _items.any((i) => i.book.id == book.id);

  /// Adds [book]. False, and nothing changes, if it is already in the order or has no copies.
  bool add(Book book, ItemType type) {
    if (contains(book) || !book.isAvailable) return false;
    _items.add(OrderItem(book, type));
    notifyListeners();
    return true;
  }

  void setType(OrderItem item, ItemType type) {
    item.type = type;
    notifyListeners();
  }

  /// Removes [item] and returns where it was, so it can be put back.
  int remove(OrderItem item) {
    final index = _items.indexOf(item);
    _items.removeAt(index);
    notifyListeners();
    return index;
  }

  /// Puts back an item removed by [remove] (Undo).
  void restore(OrderItem item, int index) {
    _items.insert(index.clamp(0, _items.length), item);
    notifyListeners();
  }

  /// The sum of the charges, added in whole cents so it matches the bill exactly.
  double get total => _items.fold<int>(0, (sum, i) => sum + toCents(i.charge)) / 100;

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// The body of POST /api/orders.
  Map<String, dynamic> toJson() => {
    'items': [for (final i in _items) i.toJson()],
  };
}
