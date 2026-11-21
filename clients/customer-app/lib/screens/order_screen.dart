import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';
import '../models/order_draft.dart';
import 'bill_screen.dart';

/// Review the order and place it (FR6, FR7): switch each book between buy and
/// rent, remove books (with Undo), see the total, and place the order.
///
/// If placing fails, the order stays as it was, so nothing has to be chosen again.
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool _placing = false;
  String? _error;

  AppServices get _services => AppScope.of(context).services;

  void _remove(OrderItem item) {
    final draft = _services.draft;
    final index = draft.remove(item);
    setState(() => _error = null);
    ToastHost.of(context).show('Removed: ${item.book.title}', undo: () => draft.restore(item, index));
  }

  Future<void> _onPlaceOrder() async {
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final order = await _services.orders.createOrder(_services.draft);
      _services.draft.clear();
      if (mounted) Navigator.of(context).pushReplacement(fadeRoute(BillScreen(order: order)));
    } on ApiException catch (e) {
      // 404 and 409 name the book; say what to do about it. Nothing was saved or charged.
      final advice = e.status == 404 || e.status == 409 ? ' Remove it from the order and try again. Nothing was charged.' : '';
      // No answer (0) is not a failure: the order may have been saved after the app stopped waiting (P-024).
      final message = e.status == 0
          ? 'No answer yet. Your order may have gone through: check Your account before you order again.'
          : '${e.message}.$advice'.replaceAll('..', '.');
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _services.draft;
    final t = Theme.of(context).textTheme;
    final c = BookstoreColors.of(context);

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop()},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: ListenableBuilder(
            listenable: draft,
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Space.xxxl, Space.xl, Space.xxxl, Space.xxxl * 2),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppButton(
                        label: 'Back to search',
                        icon: Icons.arrow_back_rounded,
                        style: AppButtonStyle.quiet,
                        onPressed: _placing ? null : () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: Space.lg),
                      Text('Your order', style: t.displaySmall),
                      const SizedBox(height: Space.sm),
                      Text(
                        draft.isEmpty
                            ? 'Nothing in it yet.'
                            : '${draft.length} ${draft.length == 1 ? 'book' : 'books'}. Choose to buy or rent each one, then place the order.',
                        style: t.bodyLarge!.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: Space.xl),
                      if (draft.isEmpty)
                        _Empty(onBack: () => Navigator.of(context).pop())
                      else
                        LayoutBuilder(
                          builder: (context, box) {
                            final items = Column(
                              children: [
                                for (final item in draft.items)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: Space.md),
                                    child: _ItemRow(
                                      key: ObjectKey(item),
                                      item: item,
                                      enabled: !_placing,
                                      onType: (type) => draft.setType(item, type),
                                      onRemove: () => _remove(item),
                                    ),
                                  ),
                              ],
                            );
                            final summary = _Summary(
                              draft: draft,
                              email: _services.session.email,
                              placing: _placing,
                              error: _error,
                              onPlace: _onPlaceOrder,
                            );
                            // Below this the Buy / Rent choice no longer fits beside the summary.
                            if (box.maxWidth < 1000) {
                              return Column(
                                children: [
                                  items,
                                  const SizedBox(height: Space.md),
                                  summary,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: items),
                                const SizedBox(width: Space.xl),
                                SizedBox(width: 340, child: summary),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One book of the order: cover, title, buy or rent, what it costs, and remove.
class _ItemRow extends StatelessWidget {
  const _ItemRow({super.key, required this.item, required this.enabled, required this.onType, required this.onRemove});

  final OrderItem item;
  final bool enabled;
  final ValueChanged<ItemType> onType;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final book = item.book;
    final due = item.dueBack(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        children: [
          BookCover(title: book.title, author: book.author, imageUrl: book.coverUrl, width: 52),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleMedium),
                const SizedBox(height: 2),
                Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                const SizedBox(height: Space.md),
                _TypeChoice(book: book, value: item.type, enabled: enabled, onChanged: onType),
                AnimatedSize(
                  duration: Motion.base,
                  curve: Motion.curve,
                  alignment: Alignment.topLeft,
                  child: due == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: Space.sm),
                          child: Row(
                            children: [
                              Icon(Icons.event_outlined, size: 14, color: c.textSecondary),
                              const SizedBox(width: Space.xs),
                              Flexible(child: Text('Due back ${formatDay(due)} if ordered today', style: t.bodySmall)),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.lg),
          SizedBox(
            width: 90,
            child: Text(money(item.charge), textAlign: TextAlign.right, style: t.titleMedium),
          ),
          const SizedBox(width: Space.sm),
          AppIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Remove from order', onPressed: enabled ? onRemove : null),
        ],
      ),
    );
  }
}

/// Buy or rent, side by side, each with its price (FR7: the rent price is
/// shown, not left to be worked out).
class _TypeChoice extends StatelessWidget {
  const _TypeChoice({required this.book, required this.value, required this.enabled, required this.onChanged});

  final Book book;
  final ItemType value;
  final bool enabled;
  final ValueChanged<ItemType> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    return Semantics(
      label: 'Buy or rent',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: c.hover, borderRadius: BorderRadius.circular(Radii.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Segment(label: 'Buy', price: money(book.price), selected: value == ItemType.buy, onTap: enabled ? () => onChanged(ItemType.buy) : null),
            _Segment(
              label: 'Rent 7 days',
              price: money(book.rentPrice),
              selected: value == ItemType.rent,
              onTap: enabled ? () => onChanged(ItemType.rent) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({required this.label, required this.price, required this.selected, required this.onTap});

  final String label;
  final String price;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final fg = widget.selected ? c.onInk : c.text;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: '${widget.label}, ${widget.price}',
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: widget.onTap != null,
        mouseCursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call())},
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Motion.base,
            curve: Motion.curve,
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 6),
            decoration: BoxDecoration(
              color: widget.selected ? c.ink : (_hover ? c.hover : Colors.transparent),
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: _focus ? c.accent : Colors.transparent, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.selected) ...[Icon(Icons.check_rounded, size: 14, color: fg), const SizedBox(width: Space.xs)],
                Text(widget.label, style: t.labelLarge!.copyWith(color: fg, fontSize: 13)),
                const SizedBox(width: Space.sm),
                Text(widget.price, style: t.labelMedium!.copyWith(color: fg.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The total and the one main button of the screen.
class _Summary extends StatelessWidget {
  const _Summary({required this.draft, required this.email, required this.placing, required this.error, required this.onPlace});

  final OrderDraft draft;
  final String? email;
  final bool placing;
  final String? error;
  final VoidCallback onPlace;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final bought = draft.items.where((i) => i.type == ItemType.buy).toList();
    final rented = draft.items.where((i) => i.type == ItemType.rent).toList();
    double sum(List<OrderItem> items) => items.fold<int>(0, (s, i) => s + toCents(i.charge)) / 100;

    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: t.bodyMedium!.copyWith(color: c.textSecondary)),
          ),
          Text(value, style: t.bodyMedium),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.panel),
        border: Border.all(color: c.hairline),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: c.shadow.a * 0.4),
            blurRadius: 36,
            offset: const Offset(0, 14),
            spreadRadius: -16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SUMMARY', style: t.labelSmall),
          const SizedBox(height: Space.md),
          if (bought.isNotEmpty) line('Bought (${bought.length})', money(sum(bought))),
          if (rented.isNotEmpty) line('Rented for 7 days (${rented.length})', money(sum(rented))),
          const SizedBox(height: Space.sm),
          Container(height: 1, color: c.hairline),
          const SizedBox(height: Space.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('Total', style: t.titleMedium)),
              Text(money(draft.total), style: t.displaySmall!.copyWith(fontSize: 28)),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text('Paid later: the store marks your order as paid.', style: t.bodySmall),
          if (error != null) ...[const SizedBox(height: Space.lg), ErrorMessage(error!)],
          const SizedBox(height: Space.xl),
          AppButton(label: placing ? 'Placing order…' : 'Place order', icon: Icons.check_rounded, expand: true, loading: placing, onPressed: onPlace),
          const SizedBox(height: Space.md),
          Text(
            email == null ? 'Your bill is shown next.' : 'Your bill is shown next, and a copy is emailed to $email.',
            textAlign: TextAlign.center,
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: Space.xxxl * 1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.panel),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 40, color: c.textTertiary),
          const SizedBox(height: Space.lg),
          Text('Your order is empty', style: t.titleLarge),
          const SizedBox(height: Space.sm),
          Text('Open a book and choose Buy or Rent to add it here.', style: t.bodyMedium!.copyWith(color: c.textSecondary)),
          const SizedBox(height: Space.xl),
          AppButton(label: 'Find books', icon: Icons.search_rounded, onPressed: onBack),
        ],
      ),
    );
  }
}
