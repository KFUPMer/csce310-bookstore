import 'dart:io';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';
import 'home_screen.dart';
import 'widgets.dart';

/// The Orders tab (FR12, FR13): every order, newest first; mark an order as
/// paid (with Undo); open an order to see its bill and print it (FR8, FR9).
class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  List<Order> _orders = const [];
  bool _loading = true;
  String? _error;

  /// 0 all, 1 pending, 2 paid.
  int _filter = 0;

  /// Orders whose status is being changed: their buttons wait.
  final Set<int> _changing = {};
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _services.orders.listOrders();
      if (mounted) setState(() => _orders = orders);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Order> get _shown => switch (_filter) {
    1 => [
      for (final o in _orders)
        if (!o.isPaid) o,
    ],
    2 => [
      for (final o in _orders)
        if (o.isPaid) o,
    ],
    _ => _orders,
  };

  /// FR13. With [undoable], the toast offers to put the old status back.
  Future<void> _setStatus(Order order, String status, {bool undoable = true}) async {
    final toast = ToastHost.of(context);
    setState(() => _changing.add(order.id));
    try {
      final updated = await _services.orders.setPaymentStatus(order.id, status);
      _replace(updated);
      toast.show(
        status == Order.paid ? 'Order ${order.id} marked as paid' : 'Order ${order.id} is waiting for payment again',
        undo: undoable ? () => _setStatus(updated, order.paymentStatus, undoable: false) : null,
      );
    } on ApiException catch (e) {
      toast.show(e.message, icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _changing.remove(order.id));
    }
  }

  void _replace(Order updated) {
    if (!mounted) return;
    setState(() => _orders = [for (final o in _orders) o.id == updated.id ? o.copyWith(paymentStatus: updated.paymentStatus) : o]);
  }

  Future<void> _open(Order order) => showDialog<void>(
    context: context,
    barrierColor: BookstoreColors.of(context).shadow,
    builder: (_) => ManagerScope(
      services: _services,
      isDark: ManagerScope.of(context).isDark,
      toggleTheme: ManagerScope.of(context).toggleTheme,
      child: _OrderDialog(orderId: order.id, onStatusChanged: _replace),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final pending = _orders.where((o) => !o.isPaid).length;
    final shown = _shown;

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.f5): _load},
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
                  Text('Orders', style: t.displaySmall),
                  const SizedBox(height: Space.sm),
                  Text(
                    _loading && _orders.isEmpty
                        ? 'Loading the orders…'
                        : '${_orders.length} ${_orders.length == 1 ? 'order' : 'orders'}, $pending waiting for payment. Newest first.',
                    style: t.bodyLarge!.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tabs(
                    labels: const ['All', 'Pending', 'Paid'],
                    counts: [_orders.length, pending, _orders.length - pending],
                    selected: _filter,
                    onSelected: (i) => setState(() => _filter = i),
                  ),
                  const SizedBox(width: Space.sm),
                  AppIconButton(icon: Icons.refresh_rounded, tooltip: 'Refresh (F5)', onPressed: _loading ? null : _load),
                ],
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          if (_error != null)
            Message(
              icon: Icons.cloud_off_rounded,
              title: 'The orders could not be loaded',
              text: _error!,
              action: AppButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                style: AppButtonStyle.secondary,
                loading: _loading,
                onPressed: _load,
              ),
            )
          else if (_loading && _orders.isEmpty)
            const Center(
              child: Padding(padding: EdgeInsets.all(Space.xxxl), child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (shown.isEmpty)
            Message(
              icon: Icons.receipt_long_outlined,
              title: _orders.isEmpty ? 'No orders yet' : (_filter == 1 ? 'Nothing is waiting for payment' : 'No paid orders yet'),
              text: _orders.isEmpty ? 'Orders appear here as soon as customers place them.' : 'Choose All to see every order.',
            )
          else
            _Table(orders: shown, changing: _changing, onOpen: _open, onMarkPaid: (o) => _setStatus(o, Order.paid)),
        ],
      ),
    );
  }
}

/// The list of orders, in columns: order, customer, date, total, status.
class _Table extends StatelessWidget {
  const _Table({required this.orders, required this.changing, required this.onOpen, required this.onMarkPaid});

  final List<Order> orders;
  final Set<int> changing;
  final ValueChanged<Order> onOpen;
  final ValueChanged<Order> onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    Widget head(String text, {int flex = 1, TextAlign align = TextAlign.left}) => Expanded(
      flex: flex,
      child: Text(text.toUpperCase(), textAlign: align, style: t.labelSmall),
    );

    return Container(
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
                head('Order', flex: 2),
                head('Customer', flex: 3),
                head('Date', flex: 4),
                head('Total', flex: 2, align: TextAlign.right),
                const SizedBox(width: Space.xl),
                SizedBox(
                  width: _paymentWidth + 4,
                  child: Text('PAYMENT', style: t.labelSmall),
                ),
              ],
            ),
          ),
          Container(height: 1, color: c.hairline),
          for (final (i, order) in orders.indexed) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: Space.lg),
                color: c.hairline,
              ),
            _Row(order: order, changing: changing.contains(order.id), onOpen: () => onOpen(order), onMarkPaid: () => onMarkPaid(order)),
          ],
        ],
      ),
    );
  }
}

/// The width of the payment column: the status, the "Mark as paid" button, and the arrow.
const double _paymentWidth = 290;

class _Row extends StatefulWidget {
  const _Row({required this.order, required this.changing, required this.onOpen, required this.onMarkPaid});

  final Order order;
  final bool changing;
  final VoidCallback onOpen;
  final VoidCallback onMarkPaid;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final o = widget.order;
    return Semantics(
      button: true,
      label: 'Order ${o.id} by ${o.username}, ${money(o.total)}, ${o.isPaid ? 'paid' : 'payment pending'}. Open the bill.',
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onOpen())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onOpen,
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
                Expanded(flex: 2, child: Text('${o.id}', style: t.titleSmall)),
                Expanded(
                  flex: 3,
                  child: Text(o.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    formatMoment(o.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium!.copyWith(color: c.textSecondary),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(money(o.total), textAlign: TextAlign.right, style: t.titleSmall),
                ),
                const SizedBox(width: Space.xl),
                // A fixed width, so the button always fits; the columns before it share what is left.
                SizedBox(
                  width: _paymentWidth,
                  child: Row(
                    children: [
                      StatusChip(
                        label: o.isPaid ? 'Paid' : 'Pending',
                        icon: o.isPaid ? Icons.check_rounded : Icons.schedule_rounded,
                        filled: o.isPaid,
                      ),
                      const SizedBox(width: Space.sm),
                      if (!o.isPaid)
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AppButton(
                              label: 'Mark as paid',
                              style: AppButtonStyle.secondary,
                              loading: widget.changing,
                              onPressed: widget.onMarkPaid,
                            ),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox(height: 42)),
                      const SizedBox(width: Space.xs),
                      Icon(Icons.chevron_right_rounded, size: 18, color: c.textTertiary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One order, opened: its bill, the payment status, and printing.
class _OrderDialog extends StatefulWidget {
  const _OrderDialog({required this.orderId, required this.onStatusChanged});

  final int orderId;
  final ValueChanged<Order> onStatusChanged;

  @override
  State<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<_OrderDialog> {
  Order? _order;
  String? _error;
  bool _changing = false;
  bool _printing = false;
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

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final order = await _services.orders.getOrder(widget.orderId);
      if (mounted) setState(() => _order = order);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _setStatus(String status) async {
    setState(() {
      _changing = true;
      _error = null;
    });
    try {
      final updated = await _services.orders.setPaymentStatus(widget.orderId, status);
      widget.onStatusChanged(updated);
      if (mounted) setState(() => _order = _order!.copyWith(paymentStatus: updated.paymentStatus));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  /// FR9: the saved HTML bill, opened in the browser to print and post.
  Future<void> _print() async {
    setState(() {
      _printing = true;
      _error = null;
    });
    try {
      final html = await _services.orders.billHtml(widget.orderId);
      final file = File('${Directory.systemTemp.path}${Platform.pathSeparator}bookstore-bill-${widget.orderId}.html');
      await file.writeAsString(html);
      await _services.openFile(file.path);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on FileSystemException {
      if (mounted) setState(() => _error = 'The bill could not be saved for printing. Please try again.');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final order = _order;

    return Dialog(
      backgroundColor: c.background,
      insetPadding: const EdgeInsets.all(Space.xxl),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.panel)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Order ${widget.orderId}', style: t.headlineSmall)),
                  AppIconButton(icon: Icons.close_rounded, tooltip: 'Close (Esc)', onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: Space.lg),
              if (order == null && _error == null)
                const Center(
                  child: Padding(padding: EdgeInsets.all(Space.xxxl), child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (order != null)
                BillView(order: order),
              if (_error != null) ...[const SizedBox(height: Space.lg), ErrorMessage(_error!)],
              const SizedBox(height: Space.xl),
              Wrap(
                spacing: Space.md,
                runSpacing: Space.md,
                children: [
                  if (order != null && !order.isPaid)
                    AppButton(label: 'Mark as paid', icon: Icons.check_rounded, loading: _changing, onPressed: () => _setStatus(Order.paid))
                  else if (order != null)
                    AppButton(
                      label: 'Mark as pending',
                      icon: Icons.undo_rounded,
                      style: AppButtonStyle.secondary,
                      loading: _changing,
                      onPressed: () => _setStatus(Order.pending),
                    ),
                  AppButton(
                    label: 'Print bill',
                    icon: Icons.print_outlined,
                    style: AppButtonStyle.secondary,
                    loading: _printing,
                    onPressed: order == null ? null : _print,
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              Text('Print opens the saved bill in your browser.', style: t.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
