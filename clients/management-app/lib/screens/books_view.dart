import 'dart:async';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';
import 'book_form_dialog.dart';
import 'widgets.dart';

/// The Books tab (FR14): search the catalog, add a book, and edit one,
/// including its number of copies.
class BooksView extends StatefulWidget {
  const BooksView({super.key});

  @override
  State<BooksView> createState() => _BooksViewState();
}

class _BooksViewState extends State<BooksView> {
  static const Duration _typingPause = Duration(milliseconds: 250);

  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  List<Book> _books = const [];
  int? _total;
  String _query = '';
  bool _loading = true;
  String? _error;
  Timer? _typing;

  /// Numbers each search, so a late answer to an older one is dropped.
  int _searchNumber = 0;
  bool _started = false;

  ManagerServices get _services => ManagerScope.of(context).services;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void dispose() {
    _typing?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final number = ++_searchNumber;
    final query = _query;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await _services.books.search(query);
      if (!mounted || number != _searchNumber) return;
      setState(() {
        _books = books;
        if (query.trim().isEmpty) _total = books.length;
      });
    } on ApiException catch (e) {
      if (mounted && number == _searchNumber) setState(() => _error = e.message);
    } finally {
      if (mounted && number == _searchNumber) setState(() => _loading = false);
    }
  }

  void _onTyping(String value) {
    setState(() => _query = value);
    _typing?.cancel();
    _typing = Timer(_typingPause, _load);
  }

  void _clearSearch() {
    _search.clear();
    _typing?.cancel();
    setState(() => _query = '');
    _load();
    _searchFocus.requestFocus();
  }

  Future<void> _edit([Book? book]) async {
    final toast = ToastHost.of(context);
    final saved = await BookFormDialog.open(context, book: book);
    if (saved == null || !mounted) return;
    toast.show(book == null ? 'Added: ${saved.title}' : 'Saved: ${saved.title}');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final searching = _query.trim().isNotEmpty;
    final String line;
    if (_loading && _books.isEmpty) {
      line = 'Loading the catalog…';
    } else if (searching) {
      line = _total == null ? '${_books.length} match' : '${_books.length} of $_total books match in title or author';
    } else {
      line = '${_books.length} books. Click a book to change it, including its copies.';
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _searchFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => _edit(),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_query.isNotEmpty) _clearSearch();
        },
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.xxxl, Space.xxl, Space.xxxl, Space.xxxl * 2),
        children: [
          Wrap(
            spacing: Space.lg,
            runSpacing: Space.lg,
            crossAxisAlignment: WrapCrossAlignment.end,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(searching ? 'Results for "${_query.trim()}"' : 'Books', style: t.displaySmall),
                  const SizedBox(height: Space.sm),
                  Text(line, style: t.bodyLarge!.copyWith(color: c.textSecondary)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 320,
                    child: SearchField(
                      controller: _search,
                      focusNode: _searchFocus,
                      searching: _loading && _books.isNotEmpty,
                      onChanged: _onTyping,
                      onClear: _clearSearch,
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Tooltip(
                    message: 'Ctrl N',
                    child: AppButton(label: 'Add book', icon: Icons.add_rounded, onPressed: () => _edit()),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          if (_error != null)
            Message(
              icon: Icons.cloud_off_rounded,
              title: 'The books could not be loaded',
              text: _error!,
              action: AppButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                style: AppButtonStyle.secondary,
                loading: _loading,
                onPressed: _load,
              ),
            )
          else if (_loading && _books.isEmpty)
            const Center(
              child: Padding(padding: EdgeInsets.all(Space.xxxl), child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_books.isEmpty)
            Message(
              icon: Icons.menu_book_outlined,
              title: searching ? 'No books match "${_query.trim()}"' : 'The catalog is empty',
              text: searching ? 'Check the spelling, or try part of the title or the author\'s name.' : 'Add the first book.',
              action: searching
                  ? AppButton(label: 'Clear search', style: AppButtonStyle.secondary, onPressed: _clearSearch)
                  : AppButton(label: 'Add book', icon: Icons.add_rounded, onPressed: () => _edit()),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.card),
                border: Border.all(color: c.hairline),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.xl, Space.md, Space.xl, Space.md),
                    child: Row(
                      children: [
                        const SizedBox(width: 34 + Space.lg),
                        Expanded(flex: 5, child: Text('TITLE', style: t.labelSmall)),
                        Expanded(flex: 4, child: Text('AUTHOR', style: t.labelSmall)),
                        Expanded(flex: 2, child: Text('SHELF', style: t.labelSmall)),
                        SizedBox(
                          width: 90,
                          child: Text('PRICE', textAlign: TextAlign.right, style: t.labelSmall),
                        ),
                        const SizedBox(width: Space.xl),
                        SizedBox(width: 150, child: Text('COPIES', style: t.labelSmall)),
                        const SizedBox(width: 38),
                      ],
                    ),
                  ),
                  Container(height: 1, color: c.hairline),
                  for (final (i, book) in _books.indexed) ...[
                    if (i > 0)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: Space.lg),
                        color: c.hairline,
                      ),
                    _BookRow(book: book, onEdit: () => _edit(book)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BookRow extends StatefulWidget {
  const _BookRow({required this.book, required this.onEdit});

  final Book book;
  final VoidCallback onEdit;

  @override
  State<_BookRow> createState() => _BookRowState();
}

class _BookRowState extends State<_BookRow> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final b = widget.book;
    // Stock in words and an icon, never by color alone.
    final (IconData icon, String stock) = b.copiesAvailable == 0
        ? (Icons.block_rounded, 'None left')
        : b.copiesAvailable <= 2
        ? (Icons.hourglass_bottom_rounded, 'Only ${b.copiesAvailable} left')
        : (Icons.inventory_2_outlined, '${b.copiesAvailable} copies');

    return Semantics(
      button: true,
      label: '${b.title} by ${b.author}, ${money(b.price)}, $stock, ${b.category ?? 'no shelf yet'}. Edit.',
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onEdit())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onEdit,
          child: AnimatedContainer(
            duration: Motion.fast,
            margin: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
            decoration: BoxDecoration(
              color: _hover ? c.hover : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.control),
              border: Border.all(color: _focus ? c.accent : Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                BookCover(title: b.title, author: b.author, imageUrl: b.coverUrl, width: 34, dimmed: !b.isAvailable),
                const SizedBox(width: Space.lg),
                Expanded(
                  flex: 5,
                  child: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    b.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium!.copyWith(color: c.textSecondary),
                  ),
                ),
                Expanded(
                  flex: 2,
                  // A book stored before shelves existed says so, so the manager knows to choose one.
                  child: Text(
                    b.category ?? 'No shelf yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: b.category == null
                        ? t.bodyMedium!.copyWith(color: c.textTertiary, fontStyle: FontStyle.italic)
                        : t.bodyMedium!.copyWith(color: c.textSecondary),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(money(b.price), textAlign: TextAlign.right, style: t.titleSmall),
                ),
                const SizedBox(width: Space.xl),
                SizedBox(
                  width: 150,
                  child: Row(
                    children: [
                      Icon(icon, size: 14, color: c.textSecondary),
                      const SizedBox(width: Space.xs),
                      Flexible(
                        child: Text(stock, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_outlined, size: 17, color: _hover || _focus ? c.text : c.textTertiary),
                const SizedBox(width: Space.sm + 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
