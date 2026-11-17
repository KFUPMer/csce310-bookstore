import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';
import '../models/book.dart';
import '../models/order.dart';

/// The bill of the order just placed (FR8), and whether a copy was emailed (FR10).
class BillScreen extends StatelessWidget {
  const BillScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context).services;
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final email = services.session.email;
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
                                  : 'This bill is saved with your order. The store will mark it as paid once you have paid.',
                              style: t.bodyLarge!.copyWith(color: c.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.xl),
                    BillView(
                      orderId: order.id,
                      createdAt: order.createdAt,
                      username: order.username,
                      email: email,
                      paid: order.isPaid,
                      total: order.total,
                      lines: [
                        for (final i in order.items)
                          BillLine(
                            title: i.title,
                            author: i.author,
                            rented: i.type == ItemType.rent,
                            quantity: i.quantity,
                            unitPrice: i.unitPrice,
                            dueBack: i.dueBack,
                          ),
                      ],
                    ),
                    const SizedBox(height: Space.xl),
                    Row(
                      children: [
                        AppButton(label: 'Continue shopping', icon: Icons.search_rounded, onPressed: back),
                        const SizedBox(width: Space.md),
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
