/// A book as returned by book-service.
class Book {
  const Book({required this.id, required this.title, required this.author, required this.price, required this.copiesAvailable, this.coverUrl});

  final String id;
  final String title;
  final String author;
  final double price;
  final int copiesAvailable;

  /// Address of the cover image, if the book has one.
  final String? coverUrl;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    price: (json['price'] as num).toDouble(),
    copiesAvailable: json['copiesAvailable'] as int,
    coverUrl: json['coverUrl'] as String?,
  );

  bool get isAvailable => copiesAvailable > 0;

  /// Renting costs 10% of the price, for 7 days.
  double get rentPrice => (price * 10).roundToDouble() / 100;
}

/// Whether a book in an order is bought or rented.
enum ItemType { buy, rent }

String money(double value) => '\$${value.toStringAsFixed(2)}';
