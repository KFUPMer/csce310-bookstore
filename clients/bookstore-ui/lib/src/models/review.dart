/// A customer's review of a book, as book-service returns it. One per customer per book.
class Review {
  const Review({
    required this.id,
    required this.bookId,
    required this.username,
    required this.rating,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String bookId;
  final String username;

  /// Whole stars, 1 to 5.
  final int rating;

  /// The customer's words; empty when they gave only stars.
  final String text;
  final DateTime createdAt;

  /// When it was last written; the list is newest first by this.
  final DateTime updatedAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    bookId: json['bookId'] as String,
    username: json['username'] as String,
    rating: json['rating'] as int,
    text: json['text'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
