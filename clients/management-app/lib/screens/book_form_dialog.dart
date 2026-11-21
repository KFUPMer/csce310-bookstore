import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';
import '../models/book_rules.dart';

/// Add a new book, or edit one (FR14), including its number of copies.
///
/// Each field's problem is shown under it before anything is sent. Closes
/// with the saved book, or with nothing when cancelled.
class BookFormDialog extends StatefulWidget {
  const BookFormDialog({super.key, this.book});

  /// The book to edit; null to add a new one.
  final Book? book;

  /// Opens the dialog and returns the saved book, or null.
  static Future<Book?> open(BuildContext context, {Book? book}) {
    final scope = ManagerScope.of(context);
    return showDialog<Book>(
      context: context,
      barrierColor: BookstoreColors.of(context).shadow,
      builder: (_) => ManagerScope(
        services: scope.services,
        isDark: scope.isDark,
        toggleTheme: scope.toggleTheme,
        child: BookFormDialog(book: book),
      ),
    );
  }

  @override
  State<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<BookFormDialog> {
  late final _title = TextEditingController(text: widget.book?.title);
  late final _author = TextEditingController(text: widget.book?.author);
  late final _price = TextEditingController(text: widget.book?.price.toStringAsFixed(2));
  late final _copies = TextEditingController(text: widget.book?.copiesAvailable.toString());
  late final _cover = TextEditingController(text: widget.book?.coverUrl);

  /// The shelf; a new book (or one stored before shelves existed) has none until the manager picks one.
  late String? _category = widget.book?.category;

  bool _saving = false;
  String? _error;
  Map<String, String> _problems = {};

  /// After the first attempt, problems are re-checked as the manager types, so they disappear once fixed.
  bool _tried = false;

  bool get _adding => widget.book == null;

  @override
  void dispose() {
    for (final c in [_title, _author, _price, _copies, _cover]) {
      c.dispose();
    }
    super.dispose();
  }

  BookCheck _check() =>
      checkBook(title: _title.text, author: _author.text, price: _price.text, copies: _copies.text, coverUrl: _cover.text, category: _category);

  void _pickShelf(String shelf) {
    setState(() => _category = shelf);
    _recheck('');
  }

  void _recheck(String _) {
    if (_tried) setState(() => _problems = _check().problems);
  }

  Future<void> _save() async {
    final check = _check();
    setState(() {
      _tried = true;
      _problems = check.problems;
      _error = null;
    });
    if (check.problems.isNotEmpty) return;

    final book = Book(
      id: widget.book?.id ?? '',
      title: _title.text.trim(),
      author: _author.text.trim(),
      price: check.price!,
      copiesAvailable: check.copies!,
      coverUrl: check.coverUrl,
      category: _category,
    );
    final books = ManagerScope.of(context).services.books;
    setState(() => _saving = true);
    try {
      final saved = _adding ? await books.add(book) : await books.update(book, copiesBefore: widget.book!.copiesAvailable);
      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))];
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.enter, control: true): _save},
      child: Dialog(
        backgroundColor: c.surface,
        insetPadding: const EdgeInsets.all(Space.xxl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.panel)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620), // the five shelves fit on one row
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_adding) ...[
                      BookCover(title: _title.text, author: _author.text, imageUrl: widget.book?.coverUrl, width: 56),
                      const SizedBox(width: Space.lg),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_adding ? 'Add a book' : 'Edit book', style: t.headlineSmall),
                          const SizedBox(height: Space.xs),
                          Text(
                            _adding ? 'It appears in the customers\' search at once.' : 'Changes appear in the customers\' search at once.',
                            style: t.bodyMedium!.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    AppIconButton(icon: Icons.close_rounded, tooltip: 'Cancel (Esc)', onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
                const SizedBox(height: Space.xl),
                AppTextField(label: 'Title', controller: _title, autofocus: true, error: _problems['title'], onChanged: _recheck),
                const SizedBox(height: Space.lg),
                AppTextField(label: 'Author', controller: _author, error: _problems['author'], onChanged: _recheck),
                const SizedBox(height: Space.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Price (\$)',
                        controller: _price,
                        hint: 'e.g. 40.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: decimal,
                        error: _problems['price'],
                        onChanged: _recheck,
                      ),
                    ),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: AppTextField(
                        label: 'Copies available',
                        controller: _copies,
                        hint: '0 or more',
                        keyboardType: TextInputType.number,
                        inputFormatters: digits,
                        error: _problems['copies'],
                        onChanged: _recheck,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                _ShelfChoice(selected: _category, error: _problems['category'], onPick: _pickShelf),
                const SizedBox(height: Space.lg),
                AppTextField(
                  label: 'Cover image address (optional)',
                  controller: _cover,
                  hint: 'https://…   Without one, a cover is drawn from the title',
                  keyboardType: TextInputType.url,
                  error: _problems['cover'],
                  textInputAction: TextInputAction.done,
                  onChanged: _recheck,
                  onSubmitted: (_) => _save(),
                ),
                if (_error != null) ...[const SizedBox(height: Space.lg), ErrorMessage(_error!)],
                const SizedBox(height: Space.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(label: 'Cancel', style: AppButtonStyle.quiet, onPressed: _saving ? null : () => Navigator.of(context).pop()),
                    const SizedBox(width: Space.sm),
                    AppButton(
                      label: _saving ? 'Saving…' : (_adding ? 'Add book' : 'Save changes'),
                      icon: Icons.check_rounded,
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The shelf of the book: one button per shelf. The chosen one is filled and shows a check,
/// so the choice is not told by color alone. Its problem is shown under it, like a field's.
class _ShelfChoice extends StatelessWidget {
  const _ShelfChoice({required this.selected, required this.error, required this.onPick});

  final String? selected;
  final String? error;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shelf', style: t.labelMedium!.copyWith(color: c.textSecondary)),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final shelf in categories)
              Semantics(
                button: true,
                selected: shelf == selected,
                label: '$shelf shelf',
                excludeSemantics: true,
                child: AppButton(
                  label: shelf,
                  icon: shelf == selected ? Icons.check_rounded : null,
                  style: shelf == selected ? AppButtonStyle.primary : AppButtonStyle.secondary,
                  onPressed: () => onPick(shelf),
                ),
              ),
          ],
        ),
        if (error != null) ...[const SizedBox(height: Space.sm), ErrorMessage(error!)],
      ],
    );
  }
}
