/// The result of checking the book form: the problems, one per field, and
/// the values read from the text the manager typed.
class BookCheck {
  const BookCheck(this.problems, {this.price, this.copies, this.coverUrl});

  final Map<String, String> problems;
  final double? price;
  final int? copies;
  final String? coverUrl;
}

/// FR14: the rules for a book, the same ones book-service applies (api-design.md).
///
/// Checked in the app first so each problem appears next to its field before
/// anything is sent. book-service still checks again: the app is not trusted.
BookCheck checkBook({required String title, required String author, required String price, required String copies, required String coverUrl}) {
  final problems = <String, String>{};

  String? text(String value, String field, String label) {
    if (value.trim().isEmpty) return problems[field] = 'Enter the $label';
    if (value.trim().length > 255) return problems[field] = 'At most 255 characters';
    return null;
  }

  text(title, 'title', 'title');
  text(author, 'author', 'author');

  final priceText = price.trim();
  final priceValue = double.tryParse(priceText);
  if (priceText.isEmpty) {
    problems['price'] = 'Enter the price';
  } else if (priceValue == null || !priceValue.isFinite) {
    problems['price'] = 'Enter the price as a number, e.g. 40.00';
  } else if (priceValue <= 0) {
    problems['price'] = 'The price must be more than 0';
  } else if (priceValue > 100000) {
    problems['price'] = 'The price can be at most 100,000';
  } else if (priceText.contains('.') && priceText.split('.').last.length > 2) {
    problems['price'] = 'At most two decimals';
  }

  final copiesText = copies.trim();
  final copiesValue = int.tryParse(copiesText);
  if (copiesText.isEmpty) {
    problems['copies'] = 'Enter the number of copies';
  } else if (copiesValue == null) {
    problems['copies'] = 'Enter a whole number';
  } else if (copiesValue < 0) {
    problems['copies'] = 'Copies cannot be negative';
  } else if (copiesValue > 1000000) {
    problems['copies'] = 'At most 1,000,000 copies';
  }

  final cover = coverUrl.trim();
  if (cover.isNotEmpty && !(cover.startsWith('http://') || cover.startsWith('https://'))) {
    problems['cover'] = 'Start the address with http:// or https://';
  }

  return BookCheck(problems, price: priceValue, copies: copiesValue, coverUrl: cover.isEmpty ? null : cover);
}
