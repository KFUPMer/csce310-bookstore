import 'package:bookstore_ui/bookstore_ui.dart';

/// A rented book and when it is due back, for the account page.
class Rental {
  const Rental({required this.orderId, required this.title, required this.author, required this.dueBack});

  final int orderId;
  final String title;
  final String author;
  final DateTime dueBack;
}

/// Every rented book in [orders], the one due soonest first.
///
/// Returning a book is not built (the PRD does not ask for it), so a rental
/// stays on the list after its date and is shown as late.
List<Rental> rentalsOf(Iterable<Order> orders) => [
  for (final order in orders)
    for (final item in order.items)
      if (item.type == ItemType.rent && item.dueBack != null)
        Rental(orderId: order.id, title: item.title, author: item.author, dueBack: item.dueBack!),
]..sort((a, b) => a.dueBack.compareTo(b.dueBack));

/// "Due back in 3 days", "Due back today", "Was due back yesterday". Counted in whole days.
String dueText(DateTime dueBack, DateTime today) {
  final days = DateTime(dueBack.year, dueBack.month, dueBack.day).difference(DateTime(today.year, today.month, today.day)).inDays;
  return switch (days) {
    0 => 'Due back today',
    1 => 'Due back tomorrow',
    -1 => 'Was due back yesterday',
    > 1 => 'Due back in $days days',
    _ => 'Was due back ${-days} days ago',
  };
}
