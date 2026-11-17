import 'package:material_ui/material_ui.dart';

import 'format.dart';
import 'status_chip.dart';
import 'tokens.dart';

/// One line of a bill.
class BillLine {
  const BillLine({required this.title, required this.author, required this.rented, required this.quantity, required this.unitPrice, this.dueBack});

  final String title;
  final String author;
  final bool rented;
  final int quantity;

  /// What was charged for one copy.
  final double unitPrice;
  final DateTime? dueBack;
}

/// A bill drawn in the app (FR8), with the same parts in the same order as the
/// HTML bill that is saved and emailed (docs/02-design/bill-design.md): order id,
/// date, customer, one row per book, the total, and the payment status.
///
/// Used by both apps: the customer sees it after ordering, the manager when
/// opening an order.
class BillView extends StatelessWidget {
  const BillView({
    super.key,
    required this.orderId,
    required this.createdAt,
    required this.username,
    required this.email,
    required this.lines,
    required this.total,
    required this.paid,
  });

  final int orderId;
  final DateTime createdAt;
  final String username;
  final String? email;
  final List<BillLine> lines;
  final double total;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final label = t.labelSmall;
    final hairline = BorderSide(color: c.hairline);

    Widget meta(String name, String value, [String? second]) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name.toUpperCase(), style: label),
          const SizedBox(height: Space.xs),
          SelectableText(value, style: t.bodyMedium),
          if (second != null) SelectableText(second, style: t.bodySmall),
        ],
      ),
    );

    Widget header(String text, {TextAlign align = TextAlign.left}) => Text(text.toUpperCase(), textAlign: align, style: label);

    return Container(
      padding: const EdgeInsets.fromLTRB(Space.xxl, Space.xl, Space.xxl, Space.xl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: c.hairline),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: c.shadow.a * 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heading, ruled underneath like the printed bill.
          Container(
            padding: const EdgeInsets.only(bottom: Space.md),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.text, width: 1.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text('Bookstore', style: t.headlineSmall)),
                Text('BILL', style: label!.copyWith(fontSize: 12, letterSpacing: 2.4, color: c.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [meta('Order ID', '$orderId'), meta('Date', formatMoment(createdAt)), meta('Customer', username, email)],
          ),
          const SizedBox(height: Space.xl),

          // The books.
          Table(
            columnWidths: const {
              0: FlexColumnWidth(5),
              1: FlexColumnWidth(2.2),
              2: FlexColumnWidth(2.6),
              3: IntrinsicColumnWidth(),
              4: FixedColumnWidth(96),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.textSecondary)),
                ),
                children: [
                  for (final (i, name) in ['Item', 'Type', 'Due back', 'Qty', 'Price'].indexed)
                    Padding(
                      padding: EdgeInsets.only(bottom: Space.sm, left: i == 3 ? Space.md : 0),
                      child: header(name, align: i >= 3 ? TextAlign.right : TextAlign.left),
                    ),
                ],
              ),
              for (final line in lines)
                TableRow(
                  decoration: BoxDecoration(border: Border(bottom: hairline)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.title, style: t.titleSmall),
                          const SizedBox(height: 2),
                          Text(line.author, style: t.bodySmall),
                        ],
                      ),
                    ),
                    _cell(context, line.rented ? 'Rent (7 days)' : 'Buy'),
                    _cell(context, line.rented && line.dueBack != null ? formatDay(line.dueBack!) : '—'),
                    _cell(context, '${line.quantity}', right: true),
                    _cell(context, money(line.unitPrice * line.quantity), right: true),
                  ],
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              StatusChip(label: paid ? 'Paid' : 'Payment pending', icon: paid ? Icons.check_rounded : Icons.schedule_rounded, filled: paid),
              const Spacer(),
              Text('Total amount due', style: t.titleMedium),
              const SizedBox(width: Space.xl),
              Text(money(total), style: t.headlineSmall),
            ],
          ),
          const SizedBox(height: Space.xl),
          Container(height: 1, color: c.hairline),
          const SizedBox(height: Space.md),
          Text('Rented books are charged at 10% of the book price and are due back 7 days after the order date.', style: t.bodySmall),
        ],
      ),
    );
  }

  static Widget _cell(BuildContext context, String text, {bool right = false}) => Padding(
    padding: EdgeInsets.only(top: Space.md, left: right ? Space.md : 0, right: right ? 0 : Space.sm),
    child: Text(text, textAlign: right ? TextAlign.right : TextAlign.left, style: Theme.of(context).textTheme.bodyMedium),
  );
}
