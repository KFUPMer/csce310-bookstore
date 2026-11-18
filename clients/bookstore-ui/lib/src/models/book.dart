/// A book as returned by book-service.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    required this.copiesAvailable,
    this.coverUrl,
    this.category,
  });

  final String id;
  final String title;
  final String author;
  final double price;
  final int copiesAvailable;

  /// Address of the cover image, if the book has one.
  final String? coverUrl;

  /// Its shelf, one of [categories]; null for a book stored before shelves existed.
  final String? category;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    price: (json['price'] as num).toDouble(),
    copiesAvailable: json['copiesAvailable'] as int,
    coverUrl: json['coverUrl'] as String?,
    category: json['category'] as String?,
  );

  /// The body of POST and PUT /api/books (FR14). The id is in the address, not the body.
  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'price': price,
    'copiesAvailable': copiesAvailable,
    'coverUrl': coverUrl,
    'category': category,
  };

  bool get isAvailable => copiesAvailable > 0;

  /// FR7: renting costs 10% of the price. Worked out in whole cents, rounded half up,
  /// the same as order-service, so the price shown is the price on the bill.
  double get rentPrice {
    final priceCents = (price * 100).round();
    return ((priceCents * rentPercent + 50) ~/ 100) / 100;
  }
}

/// The store's shelves, in the order the apps show them. book-service accepts exactly these
/// (CATEGORIES in book_service/models.py). Added at the owner's request, beyond the PRD.
const categories = ['Fiction', 'Nonfiction', 'Kids', 'Science', 'Technology'];

/// The renting rule (FR7), as order-service applies it.
const rentPercent = 10;
const rentDays = 7;

/// Whether a book in an order is bought or rented.
enum ItemType {
  buy('BUY'),
  rent('RENT');

  const ItemType(this.json);

  /// How order-service writes it.
  final String json;

  static ItemType fromJson(String value) => values.firstWhere((t) => t.json == value);
}
