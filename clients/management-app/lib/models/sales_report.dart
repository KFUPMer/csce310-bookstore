import 'package:bookstore_ui/bookstore_ui.dart';

/// The sales report of one period, as order-service returns it (GET /api/reports/sales).
///
/// Money is a double here, as in the shared [Order]; the service adds it up with Decimal.
class SalesReport {
  const SalesReport({
    required this.from,
    required this.to,
    required this.orderCount,
    required this.paidCount,
    required this.pendingCount,
    required this.revenue,
    required this.paidRevenue,
    required this.booksSold,
    required this.booksRented,
    required this.byDay,
    required this.bestSellers,
    required this.orders,
  });

  /// The first and last day of the period, both included; null when it has no start or no end.
  final DateTime? from;
  final DateTime? to;

  final int orderCount;
  final int paidCount;
  final int pendingCount;

  /// The totals of every order in the period, and of the paid ones.
  final double revenue;
  final double paidRevenue;

  /// Copies bought and copies rented.
  final int booksSold;
  final int booksRented;

  /// Only the days that have orders, oldest first.
  final List<DayTotal> byDay;

  /// Most copies first.
  final List<BestSeller> bestSellers;

  /// The orders as list rows (no items), newest first.
  final List<Order> orders;

  bool get isEmpty => orderCount == 0;

  factory SalesReport.fromJson(Map<String, dynamic> json) => SalesReport(
    from: _day(json['from']),
    to: _day(json['to']),
    orderCount: json['orderCount'] as int,
    paidCount: json['paidCount'] as int,
    pendingCount: json['pendingCount'] as int,
    revenue: (json['revenue'] as num).toDouble(),
    paidRevenue: (json['paidRevenue'] as num).toDouble(),
    booksSold: json['booksSold'] as int,
    booksRented: json['booksRented'] as int,
    byDay: [for (final d in json['byDay'] as List) DayTotal.fromJson(d as Map<String, dynamic>)],
    bestSellers: [for (final b in json['bestSellers'] as List) BestSeller.fromJson(b as Map<String, dynamic>)],
    orders: [for (final o in json['orders'] as List) Order.fromJson(o as Map<String, dynamic>)],
  );

  static DateTime? _day(Object? value) => value == null ? null : DateTime.parse(value as String);
}

/// One day of the period that has orders.
class DayTotal {
  const DayTotal({required this.date, required this.orders, required this.revenue});

  final DateTime date;
  final int orders;
  final double revenue;

  factory DayTotal.fromJson(Map<String, dynamic> json) =>
      DayTotal(date: DateTime.parse(json['date'] as String), orders: json['orders'] as int, revenue: (json['revenue'] as num).toDouble());
}

/// One book of the best sellers: the copies bought and rented, and what they brought in.
class BestSeller {
  const BestSeller({
    required this.bookId,
    required this.title,
    required this.author,
    required this.bought,
    required this.rented,
    required this.copies,
    required this.revenue,
  });

  final String bookId;
  final String title;
  final String author;
  final int bought;
  final int rented;

  /// bought + rented.
  final int copies;
  final double revenue;

  factory BestSeller.fromJson(Map<String, dynamic> json) => BestSeller(
    bookId: json['bookId'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    bought: json['bought'] as int,
    rented: json['rented'] as int,
    copies: json['copies'] as int,
    revenue: (json['revenue'] as num).toDouble(),
  );
}

/// The periods a manager can choose. Each is whole calendar days, today included.
enum ReportPeriod {
  today('Today'),
  last7Days('Last 7 days'),
  last30Days('Last 30 days'),
  thisMonth('This month'),
  allTime('All time');

  const ReportPeriod(this.label);

  final String label;

  /// The first and last day of the period on the day of [now]; (null, null) for all time.
  (DateTime?, DateTime?) range(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    // DateTime rolls a day of 0 or less back into the month before, so these work across months and years.
    return switch (this) {
      ReportPeriod.today => (day, day),
      ReportPeriod.last7Days => (DateTime(now.year, now.month, now.day - 6), day),
      ReportPeriod.last30Days => (DateTime(now.year, now.month, now.day - 29), day),
      ReportPeriod.thisMonth => (DateTime(now.year, now.month), day),
      ReportPeriod.allTime => (null, null),
    };
  }
}
