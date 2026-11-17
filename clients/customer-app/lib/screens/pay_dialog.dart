import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';

/// The pretend checkout. Asks for no card details and charges nothing: paying
/// only marks the customer's order as paid. Asked for by the owner, beyond the
/// PRD (which leaves payment to the manager, FR13).
///
/// Returns the paid order, or null if the customer closed the dialog.
Future<Order?> showPayDialog(BuildContext context, Order order) => showDialog<Order>(
  context: context,
  barrierColor: Colors.black38,
  builder: (_) => _PayDialog(order: order),
);

class _PayDialog extends StatefulWidget {
  const _PayDialog({required this.order});

  final Order order;

  @override
  State<_PayDialog> createState() => _PayDialogState();
}

class _PayDialogState extends State<_PayDialog> {
  bool _paying = false;
  String? _error;

  Future<void> _pay() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final paid = await AppScope.of(context).services.orders.pay(widget.order.id);
      if (!mounted) return;
      ToastHost.of(context).show('Order ${paid.id} is paid. Thank you!');
      Navigator.of(context).pop(paid);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final order = widget.order;

    return Dialog(
      backgroundColor: c.background,
      insetPadding: const EdgeInsets.all(Space.xxl),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.panel)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Pay for order ${order.id}', style: t.headlineSmall)),
                  AppIconButton(icon: Icons.close_rounded, tooltip: 'Close (Esc)', onPressed: _paying ? null : () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: Space.xl),
              Text('Total', style: t.labelMedium!.copyWith(color: c.textTertiary)),
              const SizedBox(height: Space.xs),
              Text(money(order.total), style: t.displaySmall),
              const SizedBox(height: Space.xl),
              InfoNote(
                'This is a demonstration checkout. No card is needed and nothing is charged: '
                'paying marks your order as paid, as the store would once it received your payment.',
              ),
              if (_error != null) ...[const SizedBox(height: Space.lg), ErrorMessage(_error!)],
              const SizedBox(height: Space.xl),
              AppButton(label: 'Pay ${money(order.total)}', icon: Icons.lock_outline_rounded, loading: _paying, expand: true, onPressed: _pay),
            ],
          ),
        ),
      ),
    );
  }
}
