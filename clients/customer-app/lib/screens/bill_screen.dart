import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';
import 'pay_dialog.dart';

/// The bill of the order just placed (FR8), whether a copy was emailed (FR10),
/// and the pretend checkout to pay it.
class BillScreen extends StatefulWidget {
  const BillScreen({super.key, required this.order});

  final Order order;

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  late Order _order = widget.order;

  Future<void> _pay() async {
    final paid = await showPayDialog(context, _order);
    if (paid != null && mounted) setState(() => _order = _order.copyWith(paymentStatus: paid.paymentStatus));
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context).services;
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final email = services.session.email;
    final order = _order;
    void back() => Navigator.of(context).pop();

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): back},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Space.xxxl, Space.xxxl, Space.xxxl, Space.xxxl * 2),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back to search (Esc)', onPressed: back),
                        const SizedBox(width: Space.md),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded, color: c.onInk, size: 22),
                        ),
                        const SizedBox(width: Space.lg),
                        Expanded(child: Text('Order ${order.id} placed', style: t.displaySmall)),
                      ],
                    ),
                    const SizedBox(height: Space.md),
                    Semantics(
                      liveRegion: true,
                      child: Row(
                        children: [
                          Icon(order.emailQueued ? Icons.mail_outline_rounded : Icons.receipt_long_outlined, size: 17, color: c.textSecondary),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: Text(
                              order.emailQueued && email != null
                                  ? 'A copy of this bill is on its way to $email.'
                                  : 'This bill is saved with your order. You can see it again on your account page.',
                              style: t.bodyLarge!.copyWith(color: c.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.xl),
                    BillView(order: order, email: email),
                    const SizedBox(height: Space.xl),
                    Wrap(
                      spacing: Space.md,
                      runSpacing: Space.md,
                      children: [
                        if (!order.isPaid) AppButton(label: 'Pay now', icon: Icons.lock_outline_rounded, onPressed: _pay),
                        AppButton(label: 'Log out', icon: Icons.logout_rounded, style: AppButtonStyle.secondary, onPressed: services.users.logout),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
