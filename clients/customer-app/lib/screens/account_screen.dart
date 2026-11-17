import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';
import '../models/account.dart';
import 'pay_dialog.dart';

/// The customer's account: who they are, their preferences, the books they
/// have rented and when each is due back, and every order they have placed,
/// with its bill and the pretend checkout. Asked for by the owner, beyond the PRD.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<Order>? _orders;
  String? _error;
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

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final orders = await _services.orders.myOrders();
      if (mounted) setState(() => _orders = orders);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _pay(Order order) async {
    final paid = await showPayDialog(context, order);
    if (paid == null || !mounted) return;
    setState(() => _orders = [for (final o in _orders!) o.id == paid.id ? o.copyWith(paymentStatus: paid.paymentStatus) : o]);
  }

  Future<void> _openBill(Order order) => showDialog<void>(
    context: context,
    barrierColor: Colors.black38,
    builder: (_) => _BillDialog(order: order, email: _services.session.email),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final session = _services.session;
    void back() => Navigator.of(context).pop();

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): back},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Space.xxxl, Space.xxl, Space.xxxl, Space.xxxl * 2),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        AppIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back to search (Esc)', onPressed: back),
                        const SizedBox(width: Space.md),
                        Expanded(child: Text('Your account', style: t.displaySmall)),
                        AppButton(label: 'Log out', icon: Icons.logout_rounded, style: AppButtonStyle.secondary, onPressed: _services.users.logout),
                      ],
                    ),
                    const SizedBox(height: Space.xl),
                    LayoutBuilder(
                      builder: (context, box) {
                        final profile = _Card(
                          title: 'Profile',
                          children: [
                            _Field('Username', session.username ?? ''),
                            _Field('Email', session.email ?? ''),
                            const _Field('Account', 'Customer'),
                            const SizedBox(height: Space.sm),
                            Text('Bills are emailed to this address.', style: t.bodySmall),
                          ],
                        );
                        const preferences = _Card(title: 'Preferences', children: [_Preferences()]);
                        if (box.maxWidth < 700) {
                          return Column(
                            children: [
                              profile,
                              const SizedBox(height: Space.lg),
                              preferences,
                            ],
                          );
                        }
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: profile),
                              const SizedBox(width: Space.lg),
                              const Expanded(child: preferences),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: Space.xxl),
                    ..._ordersAndRentals(t),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _ordersAndRentals(TextTheme t) {
    final orders = _orders;
    if (_error != null) {
      return [
        ErrorMessage(_error!),
        const SizedBox(height: Space.md),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(label: 'Try again', icon: Icons.refresh_rounded, style: AppButtonStyle.secondary, onPressed: _load),
        ),
      ];
    }
    if (orders == null) {
      return const [
        Center(
          child: Padding(padding: EdgeInsets.all(Space.xxxl), child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }
    final rentals = rentalsOf(orders);
    final today = _services.now();
    return [
      Text('Rentals due back', style: t.headlineSmall),
      const SizedBox(height: Space.md),
      if (rentals.isEmpty)
        Text('Nothing rented. A rented book is yours for $rentDays days, for $rentPercent% of its price.', style: t.bodyMedium)
      else
        for (final r in rentals) _RentalRow(rental: r, today: today),
      const SizedBox(height: Space.xxl),
      Text('Your orders', style: t.headlineSmall),
      const SizedBox(height: Space.md),
      if (orders.isEmpty)
        Text('No orders yet. Books you order appear here, with their bills.', style: t.bodyMedium)
      else
        for (final o in orders) _OrderRow(order: o, onOpen: () => _openBill(o), onPay: () => _pay(o)),
    ];
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Space.lg),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: t.bodyMedium!.copyWith(color: c.textTertiary)),
          ),
          Expanded(
            child: Text(value, style: t.bodyLarge, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _Preferences extends StatelessWidget {
  const _Preferences();

  @override
  Widget build(BuildContext context) {
    final prefs = AppScope.of(context).services.preferences;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SwitchRow(
            label: 'Dark mode',
            value: prefs.darkMode,
            onChanged: (v) => prefs.update(darkMode: v),
          ),
          _SwitchRow(
            label: 'Open search as a list',
            value: prefs.listView,
            onChanged: (v) => prefs.update(listView: v),
          ),
          const SizedBox(height: Space.sm),
          Text('Remembered on this computer, for your account only.', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// A setting that is on or off. The whole row can be clicked, and reads as one switch to a screen reader.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      toggled: value,
      onTap: () => onChanged(!value),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Row(
            children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _RentalRow extends StatelessWidget {
  const _RentalRow({required this.rental, required this.today});

  final Rental rental;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final due = dueText(rental.dueBack, today);
    final late = due.startsWith('Was');
    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.control),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        children: [
          Icon(late ? Icons.warning_amber_rounded : Icons.schedule_rounded, size: 20, color: late ? c.danger : c.textSecondary),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rental.title, style: t.titleSmall, overflow: TextOverflow.ellipsis),
                Text('${rental.author} · order ${rental.orderId}', style: t.bodySmall, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: Space.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                due,
                style: t.bodyMedium!.copyWith(color: late ? c.danger : c.text, fontWeight: FontWeight.w600),
              ),
              Text(formatDay(rental.dueBack), style: t.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatefulWidget {
  const _OrderRow({required this.order, required this.onOpen, required this.onPay});

  final Order order;
  final VoidCallback onOpen;
  final VoidCallback onPay;

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final order = widget.order;
    final books = order.items.fold<int>(0, (n, i) => n + i.quantity);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.curve,
          margin: const EdgeInsets.only(bottom: Space.sm),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
          decoration: BoxDecoration(
            color: _hover ? c.hover : c.surface,
            borderRadius: BorderRadius.circular(Radii.control),
            border: Border.all(color: c.hairline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ${order.id}', style: t.titleSmall),
                    Text('${formatMoment(order.createdAt)} · $books ${books == 1 ? 'book' : 'books'}', style: t.bodySmall),
                  ],
                ),
              ),
              Text(money(order.total), style: t.titleSmall),
              const SizedBox(width: Space.lg),
              SizedBox(
                width: 320, // fits "Payment pending" and Pay, so paid and pending rows line up
                height: 42, // the Pay button's height, so every row is as tall
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    StatusChip(
                      label: order.isPaid ? 'Paid' : 'Payment pending',
                      icon: order.isPaid ? Icons.check_rounded : Icons.schedule_rounded,
                      filled: order.isPaid,
                    ),
                    if (!order.isPaid) ...[const SizedBox(width: Space.sm), AppButton(label: 'Pay', onPressed: widget.onPay)],
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              Icon(Icons.chevron_right_rounded, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillDialog extends StatelessWidget {
  const _BillDialog({required this.order, required this.email});

  final Order order;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
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
                  Expanded(child: Text('Order ${order.id}', style: Theme.of(context).textTheme.headlineSmall)),
                  AppIconButton(icon: Icons.close_rounded, tooltip: 'Close (Esc)', onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: Space.lg),
              BillView(order: order, email: email),
            ],
          ),
        ),
      ),
    );
  }
}
