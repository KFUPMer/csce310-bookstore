import 'dart:async';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../api/api_client.dart';
import '../main.dart';
import '../models/book.dart';
import 'order_screen.dart';

/// Search the books and add them to the order (FR4, FR5, FR6). Also where
/// the customer logs out (FR2).
///
/// Searches as the customer types, a moment after they stop, so not every
/// keystroke becomes a request. An answer to an older search is ignored if a
/// newer one has started.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const double _barHeight = 64;
  static const double _panelWidth = 340;
  static const Duration _typingPause = Duration(milliseconds: 250);

  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _scroll = ScrollController();

  bool _list = false;
  String _query = '';
  Book? _selected;

  List<Book> _results = const [];

  /// How many books the catalog has, from the last search without a keyword.
  int? _total;
  bool _loading = true;
  String? _error;

  Timer? _typing;

  /// Numbers each search, so a late answer to an older one can be recognised and dropped.
  int _searchNumber = 0;
  bool _started = false;

  AppServices get _services => AppScope.of(context).services;

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
    _scroll.dispose();
    super.dispose();
  }

  /// FR4: asks book-service for the books whose title or author contains the keyword.
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
        _results = books;
        if (query.trim().isEmpty) _total = books.length;
        // Keep the open book, with its new number of copies, if it is still among the results.
        // If not, close it: a panel about a book that is not in the list is confusing.
        if (_selected != null) {
          final id = _selected!.id;
          _selected = null;
          for (final b in books) {
            if (b.id == id) _selected = b;
          }
        }
      });
    } on ApiException catch (e) {
      if (!mounted || number != _searchNumber) return;
      setState(() => _error = e.message);
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

  void _add(Book book, ItemType type) {
    final draft = _services.draft;
    if (!draft.add(book, type)) return;
    ToastHost.of(context).show(
      '${type == ItemType.buy ? 'Added to order' : 'Added as a 7-day rental'}: ${book.title}',
      undo: () {
        for (final item in draft.items) {
          if (item.book.id == book.id) draft.remove(item);
        }
      },
    );
  }

  Future<void> _openOrder() async {
    if (_services.draft.isEmpty) {
      ToastHost.of(context).show('Your order is empty. Pick a book to start.', icon: Icons.info_outline_rounded);
      return;
    }
    await Navigator.of(context).push(fadeRoute(const OrderScreen()));
    // Placing an order changes the number of copies: show the new numbers.
    if (mounted) _load();
  }

  Future<void> _logout() => _services.users.logout(); // the app goes back to log in by itself

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final c = BookstoreColors.of(context);
    final draft = scope.services.draft;
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
        child: ListenableBuilder(
          listenable: draft,
          builder: (context, _) => Scaffold(
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
                                child: _Heading(query: _query, count: _results.length, total: _total, loading: _loading && _results.isEmpty),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
                            ..._body(draft.contains),
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
                                searching: _loading && _results.isNotEmpty,
                                onChanged: _onTyping,
                                onClear: _clearSearch,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.lg),
                        AppIconButton(
                          icon: Icons.grid_view_rounded,
                          tooltip: 'Show as covers',
                          selected: !_list,
                          onPressed: () => setState(() => _list = false),
                        ),
                        const SizedBox(width: Space.xs),
                        AppIconButton(
                          icon: Icons.view_list_rounded,
                          tooltip: 'Show as a list',
                          selected: _list,
                          onPressed: () => setState(() => _list = true),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: Space.md),
                          color: c.hairline,
                        ),
                        AppIconButton(
                          icon: scope.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          tooltip: scope.isDark ? 'Switch to light mode' : 'Switch to dark mode',
                          onPressed: scope.toggleTheme,
                        ),
                        const SizedBox(width: Space.sm),
                        AppButton(
                          label: draft.isEmpty ? 'Your order' : 'Your order (${draft.length})',
                          icon: Icons.shopping_bag_outlined,
                          style: draft.isEmpty ? AppButtonStyle.secondary : AppButtonStyle.primary,
                          onPressed: _openOrder,
                        ),
                        const SizedBox(width: Space.md),
                        Text(scope.services.session.username ?? '', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c.textSecondary)),
                        const SizedBox(width: Space.xs),
                        AppIconButton(icon: Icons.logout_rounded, tooltip: 'Log out', onPressed: _logout),
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
                            inOrder: draft.contains(_selected!),
                            onClose: () => setState(() => _selected = null),
                            onAdd: (type) => _add(_selected!, type),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// What is under the heading: books, nothing found, still loading, or a failure.
  List<Widget> _body(bool Function(Book) inOrder) {
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Message(
            icon: Icons.cloud_off_rounded,
            title: 'The books could not be loaded',
            text: _error!,
            action: AppButton(label: 'Try again', icon: Icons.refresh_rounded, style: AppButtonStyle.secondary, loading: _loading, onPressed: _load),
          ),
        ),
      ];
    }
    if (_loading && _results.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xxxl - Space.md),
          sliver: SliverGrid(gridDelegate: _grid, delegate: SliverChildListDelegate.fixed([for (var i = 0; i < 6; i++) const _PlaceholderCard()])),
        ),
      ];
    }
    if (_results.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _query.trim().isEmpty
              ? const _Message(icon: Icons.menu_book_outlined, title: 'The catalog is empty', text: 'No books have been added yet.')
              : _Message(
                  icon: Icons.menu_book_outlined,
                  title: 'No books match "${_query.trim()}"',
                  text: 'Check the spelling, or try part of the title or the author\'s name.',
                  action: AppButton(label: 'Clear search', style: AppButtonStyle.secondary, onPressed: _clearSearch),
                ),
        ),
      ];
    }
    if (_list) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xxxl - Space.md),
          sliver: SliverList.builder(
            itemCount: _results.length,
            itemBuilder: (_, i) => _BookRow(
              book: _results[i],
              selected: _selected?.id == _results[i].id,
              inOrder: inOrder(_results[i]),
              onTap: () => setState(() => _selected = _results[i]),
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xxxl - Space.md),
        sliver: SliverGrid.builder(
          gridDelegate: _grid,
          itemCount: _results.length,
          itemBuilder: (_, i) => _BookCard(
            book: _results[i],
            selected: _selected?.id == _results[i].id,
            inOrder: inOrder(_results[i]),
            onTap: () => setState(() => _selected = _results[i]),
          ),
        ),
      ),
    ];
  }

  static const _grid = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 196,
    mainAxisExtent: 344,
    crossAxisSpacing: Space.sm,
    mainAxisSpacing: Space.md,
  );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.query, required this.count, required this.total, required this.loading});

  final String query;
  final int count;
  final int? total;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final searching = query.trim().isNotEmpty;
    final String line;
    if (loading) {
      line = 'Loading the catalog…';
    } else if (searching) {
      line = total == null
          ? '$count ${count == 1 ? 'book matches' : 'books match'} in title or author'
          : '$count of $total books match in title or author';
    } else {
      line = '$count books. Search by title or author, or pick a cover.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(searching ? 'Results for "${query.trim()}"' : 'All books', style: t.displaySmall),
        const SizedBox(height: Space.sm),
        Text(line, style: t.bodyLarge!.copyWith(color: BookstoreColors.of(context).textSecondary)),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.focusNode, required this.searching, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final FocusNode focusNode;

  /// A search is running: a small spinner replaces the search icon.
  final bool searching;
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
            SizedBox(
              width: 18,
              child: searching
                  ? Padding(
                      padding: const EdgeInsets.all(2),
                      child: CircularProgressIndicator(strokeWidth: 1.6, color: c.textSecondary, semanticsLabel: 'Searching'),
                    )
                  : Icon(Icons.search_rounded, size: 18, color: c.textSecondary),
            ),
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

/// Where a book card will be, while the catalog loads.
class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();

  @override
  Widget build(BuildContext context) {
    final fill = BookstoreColors.of(context).hover;
    Widget bar(double width) => Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(5)),
    );
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.all(Space.md + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 148,
                height: 222,
                decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(Radii.cover)),
              ),
            ),
            const SizedBox(height: Space.lg),
            bar(120),
            const SizedBox(height: Space.sm),
            bar(80),
          ],
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

/// A full-width message in place of the books: nothing found, or a failure.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.text, this.action});

  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    return Center(
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: c.textTertiary),
            const SizedBox(height: Space.lg),
            Text(title, style: t.titleLarge),
            const SizedBox(height: Space.sm),
            Text(
              text,
              textAlign: TextAlign.center,
              style: t.bodyMedium!.copyWith(color: c.textSecondary),
            ),
            if (action != null) ...[const SizedBox(height: Space.xl), action!],
          ],
        ),
      ),
    );
  }
}
