import 'dart:async';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/book.dart';
import '../preview/mock_books.dart';

/// Browse and search the books, and add them to the order.
///
/// STYLE PREVIEW: this screen runs on [mockBooks] so that the look can be
/// judged before book-service exists. In M4 it loads books from the API.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.isDark, required this.onToggleTheme, this.startList = false, this.startSelected, this.startQuery = ''});

  final bool isDark;
  final VoidCallback onToggleTheme;
  final bool startList;
  final String? startSelected;
  final String startQuery;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _OrderLine {
  _OrderLine(this.book, this.type);
  final Book book;
  final ItemType type;
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const double _barHeight = 64;
  static const double _panelWidth = 340;

  late final _search = TextEditingController(text: widget.startQuery);
  final _searchFocus = FocusNode();
  final _scroll = ScrollController();

  late bool _list = widget.startList;
  late String _query = widget.startQuery;
  Book? _selected;
  final List<_OrderLine> _order = [];

  String? _toast;
  VoidCallback? _toastUndo;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    if (widget.startSelected != null) {
      for (final b in mockBooks) {
        if (b.id == widget.startSelected) _selected = b;
      }
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// FR4: the keyword is matched against both title and author.
  List<Book> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return mockBooks;
    return [
      for (final b in mockBooks)
        if (b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q)) b,
    ];
  }

  bool _inOrder(Book book) => _order.any((l) => l.book.id == book.id);

  void _add(Book book, ItemType type) {
    if (_inOrder(book) || !book.isAvailable) return;
    final line = _OrderLine(book, type);
    setState(() => _order.add(line));
    _showToast('${type == ItemType.buy ? 'Added to order' : 'Added as a 7-day rental'}: ${book.title}', undo: () => setState(() => _order.remove(line)));
  }

  void _showToast(String message, {VoidCallback? undo}) {
    _toastTimer?.cancel();
    setState(() {
      _toast = message;
      _toastUndo = undo;
    });
    _toastTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final results = _results;
    final panelOpen = _selected != null;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _searchFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_selected != null) {
            setState(() => _selected = null);
          } else if (_query.isNotEmpty) {
            _clearSearch();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            children: [
              // The books scroll under the glass bar, so their colors tint it.
              Positioned.fill(
                child: AnimatedPadding(
                  duration: Motion.slow,
                  curve: Motion.curve,
                  padding: EdgeInsets.only(right: panelOpen ? _panelWidth + Space.lg : 0),
                  child: SmoothScroll(
                    controller: _scroll,
                    child: Scrollbar(
                      controller: _scroll,
                      child: CustomScrollView(
                        controller: _scroll,
                        physics: SmoothScroll.physics,
                        slivers: [
                          const SliverToBoxAdapter(child: SizedBox(height: _barHeight + Space.xxl + Space.lg)),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: Space.xxxl),
                            sliver: SliverToBoxAdapter(
                              child: _Heading(query: _query, count: results.length, total: mockBooks.length),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
                          if (results.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyState(query: _query, onClear: _clearSearch),
                            )
                          else if (_list)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: Space.xxxl - Space.md),
                              sliver: SliverList.builder(
                                itemCount: results.length,
                                itemBuilder: (_, i) => _BookRow(
                                  book: results[i],
                                  selected: _selected?.id == results[i].id,
                                  inOrder: _inOrder(results[i]),
                                  onTap: () => setState(() => _selected = results[i]),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: Space.xxxl - Space.md),
                              sliver: SliverGrid.builder(
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 196,
                                  mainAxisExtent: 344,
                                  crossAxisSpacing: Space.sm,
                                  mainAxisSpacing: Space.md,
                                ),
                                itemCount: results.length,
                                itemBuilder: (_, i) => _BookCard(
                                  book: results[i],
                                  selected: _selected?.id == results[i].id,
                                  inOrder: _inOrder(results[i]),
                                  onTap: () => setState(() => _selected = results[i]),
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: Space.xxxl * 2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Top bar.
              Positioned(
                top: Space.md,
                left: Space.lg,
                right: Space.lg,
                height: _barHeight,
                child: Glass(
                  radius: Radii.panel,
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                  child: Row(
                    children: [
                      Text('Bookstore', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(width: Space.xl),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: _SearchField(
                              controller: _search,
                              focusNode: _searchFocus,
                              onChanged: (v) => setState(() => _query = v),
                              onClear: _clearSearch,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.lg),
                      AppIconButton(icon: Icons.grid_view_rounded, tooltip: 'Show as covers', selected: !_list, onPressed: () => setState(() => _list = false)),
                      const SizedBox(width: Space.xs),
                      AppIconButton(icon: Icons.view_list_rounded, tooltip: 'Show as a list', selected: _list, onPressed: () => setState(() => _list = true)),
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: Space.md),
                        color: c.hairline,
                      ),
                      AppIconButton(
                        icon: widget.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        tooltip: widget.isDark ? 'Switch to light mode' : 'Switch to dark mode',
                        onPressed: widget.onToggleTheme,
                      ),
                      const SizedBox(width: Space.sm),
                      AppButton(
                        label: _order.isEmpty ? 'Your order' : 'Your order (${_order.length})',
                        icon: Icons.shopping_bag_outlined,
                        style: _order.isEmpty ? AppButtonStyle.secondary : AppButtonStyle.primary,
                        onPressed: () => _showToast(
                          _order.isEmpty ? 'Your order is empty. Pick a book to start.' : 'The order screen comes next (not part of this preview).',
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Text('alice', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c.textSecondary)),
                      const SizedBox(width: Space.xs),
                      AppIconButton(icon: Icons.logout_rounded, tooltip: 'Log out', onPressed: () => _showToast('Log out is not part of this preview.')),
                    ],
                  ),
                ),
              ),

              // Detail panel: slides in from the right.
              AnimatedPositioned(
                duration: Motion.slow,
                curve: Motion.curve,
                top: _barHeight + Space.md + Space.lg,
                bottom: Space.lg,
                right: panelOpen ? Space.lg : -_panelWidth - Space.xl,
                width: _panelWidth,
                child: AnimatedOpacity(
                  duration: Motion.base,
                  opacity: panelOpen ? 1 : 0,
                  child: _selected == null
                      ? const SizedBox.shrink()
                      : _DetailPanel(
                          key: ValueKey(_selected!.id),
                          book: _selected!,
                          inOrder: _inOrder(_selected!),
                          onClose: () => setState(() => _selected = null),
                          onAdd: (type) => _add(_selected!, type),
                        ),
                ),
              ),

              // Toast: says what just happened and offers to undo it.
              Positioned(
                left: 0,
                right: panelOpen ? _panelWidth + Space.lg : 0,
                bottom: Space.xl,
                child: IgnorePointer(
                  ignoring: _toast == null,
                  child: AnimatedSlide(
                    duration: Motion.base,
                    curve: Motion.curve,
                    offset: _toast == null ? const Offset(0, 0.6) : Offset.zero,
                    child: AnimatedOpacity(
                      duration: Motion.base,
                      opacity: _toast == null ? 0 : 1,
                      child: Center(
                        child: Semantics(
                          liveRegion: true,
                          child: Glass(
                            radius: Radii.pill,
                            padding: const EdgeInsets.fromLTRB(Space.lg, Space.xs, Space.xs, Space.xs),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 17, color: c.text),
                                const SizedBox(width: Space.sm),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 420),
                                  child: Text(_toast ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                                ),
                                const SizedBox(width: Space.sm),
                                if (_toastUndo != null)
                                  AppButton(
                                    label: 'Undo',
                                    style: AppButtonStyle.quiet,
                                    onPressed: () {
                                      _toastUndo?.call();
                                      _toastTimer?.cancel();
                                      setState(() => _toast = null);
                                    },
                                  )
                                else
                                  const SizedBox(width: Space.md, height: 42),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.query, required this.count, required this.total});

  final String query;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final searching = query.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(searching ? 'Results for "${query.trim()}"' : 'All books', style: t.displaySmall),
        const SizedBox(height: Space.sm),
        Text(
          searching ? '$count of $total books match in title or author' : '$total books. Search by title or author, or pick a cover.',
          style: t.bodyLarge!.copyWith(color: BookstoreColors.of(context).textSecondary),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.focusNode, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) => AnimatedContainer(
        duration: Motion.fast,
        height: 40,
        padding: const EdgeInsets.only(left: Space.md, right: Space.xs),
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: focusNode.hasFocus ? 1 : 0.6),
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: focusNode.hasFocus ? c.accent : c.hairline, width: focusNode.hasFocus ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: c.textSecondary),
            const SizedBox(width: Space.sm),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search by title or author',
                  hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c.textTertiary),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              AppIconButton(icon: Icons.close_rounded, tooltip: 'Clear search (Esc)', onPressed: onClear)
            else
              Padding(
                padding: const EdgeInsets.only(right: Space.sm),
                child: Text('Ctrl F', style: Theme.of(context).textTheme.labelSmall),
              ),
          ],
        ),
      ),
    );
  }
}

/// Availability in words and an icon, never by color alone.
class _Availability extends StatelessWidget {
  const _Availability({required this.book, required this.inOrder, this.compact = false});

  final Book book;
  final bool inOrder;

  /// Shorter wording, for the narrow cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final (IconData icon, String label) = inOrder
        ? (Icons.check_rounded, compact ? 'In order' : 'In your order')
        : !book.isAvailable
        ? (Icons.block_rounded, 'Unavailable')
        : book.copiesAvailable <= 2
        ? (Icons.hourglass_bottom_rounded, compact ? '${book.copiesAvailable} left' : 'Only ${book.copiesAvailable} left')
        : (Icons.inventory_2_outlined, compact ? '${book.copiesAvailable} left' : '${book.copiesAvailable} available');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

/// A book in the covers view. Lifts slightly under the pointer.
class _BookCard extends StatefulWidget {
  const _BookCard({required this.book, required this.selected, required this.inOrder, required this.onTap});

  final Book book;
  final bool selected;
  final bool inOrder;
  final VoidCallback onTap;

  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final book = widget.book;
    return Semantics(
      button: true,
      label: '${book.title} by ${book.author}, ${money(book.price)}',
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Motion.base,
            curve: Motion.curve,
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: widget.selected ? c.surface : (_hover ? c.hover : Colors.transparent),
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: _focus || widget.selected ? c.accent : Colors.transparent, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: AnimatedSlide(
                    duration: Motion.base,
                    curve: Motion.curve,
                    offset: Offset(0, _hover ? -0.02 : 0),
                    child: AnimatedScale(
                      duration: Motion.base,
                      curve: Motion.curve,
                      scale: _hover ? 1.03 : 1,
                      child: BookCover(title: book.title, author: book.author, imageUrl: book.coverUrl, width: 148, dimmed: !book.isAvailable),
                    ),
                  ),
                ),
                const SizedBox(height: Space.md),
                Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                const SizedBox(height: 2),
                Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                const Spacer(),
                Row(
                  children: [
                    Text(money(book.price), style: t.titleMedium),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _Availability(book: book, inOrder: widget.inOrder, compact: true),
                      ),
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

/// A book in the list view: title, author, and price in columns (FR5).
class _BookRow extends StatefulWidget {
  const _BookRow({required this.book, required this.selected, required this.inOrder, required this.onTap});

  final Book book;
  final bool selected;
  final bool inOrder;
  final VoidCallback onTap;

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
    final book = widget.book;
    return Semantics(
      button: true,
      label: '${book.title} by ${book.author}, ${money(book.price)}',
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Motion.fast,
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
            decoration: BoxDecoration(
              color: widget.selected ? c.surface : (_hover ? c.hover : Colors.transparent),
              borderRadius: BorderRadius.circular(Radii.control + 2),
              border: Border.all(color: _focus || widget.selected ? c.accent : Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                BookCover(title: book.title, author: book.author, imageUrl: book.coverUrl, width: 34, dimmed: !book.isAvailable),
                const SizedBox(width: Space.lg),
                Expanded(
                  flex: 5,
                  child: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  flex: 4,
                  child: Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium!.copyWith(color: c.textSecondary),
                  ),
                ),
                const SizedBox(width: Space.lg),
                SizedBox(
                  width: 140,
                  child: _Availability(book: book, inOrder: widget.inOrder),
                ),
                SizedBox(
                  width: 80,
                  child: Text(money(book.price), textAlign: TextAlign.right, style: t.titleMedium),
                ),
                const SizedBox(width: Space.sm),
                Icon(Icons.chevron_right_rounded, size: 18, color: c.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Everything about one book, with the two ways to order it.
class _DetailPanel extends StatelessWidget {
  const _DetailPanel({super.key, required this.book, required this.inOrder, required this.onClose, required this.onAdd});

  final Book book;
  final bool inOrder;
  final VoidCallback onClose;
  final ValueChanged<ItemType> onAdd;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final canOrder = book.isAvailable && !inOrder;
    return Glass(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.md, Space.xl, Space.xl),
      // Scrolls when the window is too short to show everything.
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppIconButton(icon: Icons.close_rounded, tooltip: 'Close (Esc)', onPressed: onClose),
                  ),
                  Center(
                    child: BookCover(title: book.title, author: book.author, imageUrl: book.coverUrl, width: 140, dimmed: !book.isAvailable),
                  ),
                  const SizedBox(height: Space.lg),
                  Text(book.title, style: t.headlineSmall),
                  const SizedBox(height: Space.xs),
                  Text(book.author, style: t.bodyLarge!.copyWith(color: c.textSecondary)),
                  const SizedBox(height: Space.md),
                  _Availability(book: book, inOrder: inOrder),
                  const SizedBox(height: Space.lg),
                  const Spacer(),
                  if (inOrder)
                    Text('This book is already in your order.', style: t.bodySmall)
                  else if (!book.isAvailable)
                    Text('No copies are available right now, so it cannot be ordered.', style: t.bodySmall)
                  else
                    Text('Renting costs 10% of the price. The book is due back after 7 days.', style: t.bodySmall),
                  const SizedBox(height: Space.md),
                  AppButton(label: 'Buy', trailing: money(book.price), expand: true, onPressed: canOrder ? () => onAdd(ItemType.buy) : null),
                  const SizedBox(height: Space.sm),
                  AppButton(
                    label: 'Rent for 7 days',
                    trailing: money(book.rentPrice),
                    expand: true,
                    style: AppButtonStyle.secondary,
                    onPressed: canOrder ? () => onAdd(ItemType.rent) : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 40, color: c.textTertiary),
          const SizedBox(height: Space.lg),
          Text('No books match "${query.trim()}"', style: t.titleLarge),
          const SizedBox(height: Space.sm),
          Text('Check the spelling, or try part of the title or the author\'s name.', style: t.bodyMedium!.copyWith(color: c.textSecondary)),
          const SizedBox(height: Space.xl),
          AppButton(label: 'Clear search', style: AppButtonStyle.secondary, onPressed: onClear),
        ],
      ),
    );
  }
}
