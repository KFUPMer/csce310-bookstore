import 'dart:math' as math;

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';
import '../models/sales_report.dart';
import 'widgets.dart';

/// The Reports tab (extra credit): the sales of a period, its sales by day, its
/// best sellers, and its orders.
///
/// Loads when it is first shown and again each time the manager comes back to
/// it, so an order marked as paid in the Orders tab is counted at once.
class ReportsView extends StatefulWidget {
  const ReportsView({super.key, required this.visible});

  /// Whether the tab is the one on screen.
  final bool visible;

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  ReportPeriod _period = ReportPeriod.last30Days;
  SalesReport? _report;
  bool _loading = false;
  String? _error;
  bool _started = false;

  /// Numbers each request, so a late answer for a period no longer chosen is dropped.
  int _requestNumber = 0;

  ManagerServices get _services => ManagerScope.of(context).services;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.visible && !_started) {
      _started = true;
      _load();
    }
  }

  @override
  void didUpdateWidget(ReportsView old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    final number = ++_requestNumber;
    final (from, to) = _period.range(_services.now());
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await _services.reports.salesReport(from: from, to: to);
      if (mounted && number == _requestNumber) setState(() => _report = report);
    } on ApiException catch (e) {
      if (mounted && number == _requestNumber) setState(() => _error = e.message);
    } finally {
      if (mounted && number == _requestNumber) setState(() => _loading = false);
    }
  }

  void _choose(ReportPeriod period) {
    if (period == _period) return;
    setState(() => _period = period);
    _load();
  }

  String get _periodInWords {
    final (from, to) = _period.range(_services.now());
    if (from == null || to == null) return 'All time';
    return from == to ? formatDay(from) : '${formatDay(from)} – ${formatDay(to)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final report = _report;

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
                  Text('Sales report', style: t.displaySmall),
                  const SizedBox(height: Space.sm),
                  Text(_periodInWords, style: t.bodyLarge!.copyWith(color: c.textSecondary)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PeriodChoice(selected: _period, onPick: _choose),
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
              title: 'The sales report could not be loaded',
              text: _error!,
              action: AppButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                style: AppButtonStyle.secondary,
                loading: _loading,
                onPressed: _load,
              ),
            )
          else if (report == null)
            // Nothing before the tab is first opened: a spinner there would keep turning out of sight.
            _loading
                ? const Center(
                    child: Padding(padding: EdgeInsets.all(Space.xxxl), child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : const SizedBox.shrink()
          else
            // While another period loads, the last report stays, faded, so the page does not jump.
            AnimatedOpacity(
              opacity: _loading ? 0.5 : 1,
              duration: Motion.base,
              curve: Motion.curve,
              child: report.isEmpty
                  ? Message(
                      icon: Icons.insights_outlined,
                      title: 'No orders in this period.',
                      text: _period == ReportPeriod.allTime
                          ? 'Orders appear here as soon as customers place them.'
                          : 'Choose a longer period, or All time.',
                    )
                  : _ReportBody(report: report),
            ),
        ],
      ),
    );
  }
}

/// One button per period. The chosen one is filled and shows a check, so the
/// choice is not told by color alone.
class _PeriodChoice extends StatelessWidget {
  const _PeriodChoice({required this.selected, required this.onPick});

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        for (final period in ReportPeriod.values)
          Semantics(
            button: true,
            selected: period == selected,
            label: 'Period: ${period.label}',
            excludeSemantics: true,
            child: AppButton(
              label: period.label,
              icon: period == selected ? Icons.check_rounded : null,
              style: period == selected ? AppButtonStyle.primary : AppButtonStyle.secondary,
              onPressed: () => onPick(period),
            ),
          ),
      ],
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final SalesReport report;

  @override
  Widget build(BuildContext context) {
    final r = report;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Tile(
              label: 'Orders',
              value: '${r.orderCount}',
              note: '${r.paidCount} paid · ${r.pendingCount} pending',
              semantics: 'Orders: ${r.orderCount}. ${r.paidCount} paid, ${r.pendingCount} pending.',
            ),
            const SizedBox(width: Space.md),
            _Tile(
              label: 'Revenue',
              value: money(r.revenue),
              note: '${money(r.paidRevenue)} paid',
              semantics: 'Revenue: ${money(r.revenue)}. ${money(r.paidRevenue)} paid.',
            ),
            const SizedBox(width: Space.md),
            _Tile(label: 'Books sold', value: '${r.booksSold}', note: 'Copies bought', semantics: 'Books sold: ${r.booksSold}'),
            const SizedBox(width: Space.md),
            _Tile(label: 'Books rented', value: '${r.booksRented}', note: 'Copies rented for 7 days', semantics: 'Books rented: ${r.booksRented}'),
          ],
        ),
        const SizedBox(height: Space.xxl),
        _Section(
          title: 'Sales by day',
          note: 'The revenue of each day that has orders. Point at a bar for its orders.',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.xl, Space.lg),
            child: _DayChart(days: r.byDay),
          ),
        ),
        const SizedBox(height: Space.xxl),
        _Section(
          title: 'Best sellers',
          note: 'Most copies first, bought and rented together.',
          child: _BestSellers(books: r.bestSellers),
        ),
        const SizedBox(height: Space.xxl),
        _Section(
          title: 'Orders in this period',
          note: '${r.orderCount} ${r.orderCount == 1 ? 'order' : 'orders'}, newest first.',
          child: _Orders(orders: r.orders),
        ),
      ],
    );
  }
}

/// A heading with a short note under it, over a card.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.note, required this.child});

  final String title;
  final String note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: t.titleLarge),
        const SizedBox(height: Space.xs),
        Text(note, style: t.bodyMedium!.copyWith(color: c.textSecondary)),
        const SizedBox(height: Space.md),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: c.hairline),
          ),
          child: child,
        ),
      ],
    );
  }
}

/// One total: a small label, a large number, and a line under it.
class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.note, required this.semantics});

  final String label;
  final String value;
  final String note;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Semantics(
        container: true,
        label: semantics,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.xl, Space.lg),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: c.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: t.labelSmall),
              const SizedBox(height: Space.sm),
              // A large amount is made smaller rather than cut off in a narrow window.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: t.displaySmall),
              ),
              const SizedBox(height: Space.xs),
              Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

const _shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "11 November": the day without the year.
String _dayAndMonth(DateTime d) {
  final day = formatDay(d);
  return day.substring(0, day.lastIndexOf(' '));
}

/// The revenue of each day as a bar, in the ink color. Each bar names its day under it, its
/// amount over it when there is room, and its orders in a tooltip.
class _DayChart extends StatelessWidget {
  const _DayChart({required this.days});

  final List<DayTotal> days;

  static const int _mostDays = 31;
  static const double _barArea = 140;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Text(
          'No sales in this period.',
          textAlign: TextAlign.center,
          style: t.bodyMedium!.copyWith(color: c.textSecondary),
        ),
      );
    }
    final shown = days.length > _mostDays ? days.sublist(days.length - _mostDays) : days;
    final highest = shown.reduce((a, b) => b.revenue > a.revenue ? b : a);
    final summary =
        'Sales by day: ${shown.length} ${shown.length == 1 ? 'day' : 'days'} with orders, '
        'the highest ${money(highest.revenue)} on ${_dayAndMonth(highest.date)}.';

    return Semantics(
      container: true,
      label: summary,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final slot = (box.maxWidth / shown.length).clamp(48.0, 96.0);
              final bars = Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in shown)
                    _Bar(day: d, width: slot, height: math.max(2, _barArea * d.revenue / math.max(highest.revenue, 0.01)), showAmount: slot >= 64),
                ],
              );
              // More days than fit: scroll sideways, starting at the newest.
              return slot * shown.length > box.maxWidth ? SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: true, child: bars) : bars;
            },
          ),
          if (days.length > _mostDays) ...[const SizedBox(height: Space.sm), Text('The last $_mostDays days with orders.', style: t.bodySmall)],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.day, required this.width, required this.height, required this.showAmount});

  final DayTotal day;
  final double width;
  final double height;
  final bool showAmount;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    return Tooltip(
      message: '${formatDay(day.date)}: ${money(day.revenue)}, ${day.orders} ${day.orders == 1 ? 'order' : 'orders'}',
      waitDuration: Motion.fast,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAmount) ...[
              Text(money(day.revenue), maxLines: 1, style: t.labelSmall!.copyWith(color: c.textSecondary)),
              const SizedBox(height: Space.xs),
            ],
            Container(
              width: math.min(28, width * 0.5),
              height: height,
              decoration: BoxDecoration(
                color: c.ink,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            Container(height: 1, color: c.hairline),
            const SizedBox(height: Space.sm),
            Text('${day.date.day} ${_shortMonths[day.date.month - 1]}', maxLines: 1, style: t.labelSmall!.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// The numbered best sellers: rank, title, author, bought, rented, copies, revenue.
class _BestSellers extends StatelessWidget {
  const _BestSellers({required this.books});

  final List<BestSeller> books;

  static const double _rank = 32;
  static const double _count = 72;
  static const double _money = 104;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    Widget number(String text, double width, TextStyle style) => SizedBox(
      width: width,
      child: Text(text, textAlign: TextAlign.right, maxLines: 1, style: style),
    );
    final head = t.labelSmall!;
    final cell = t.bodyMedium!.copyWith(color: c.textSecondary);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.md),
          child: Row(
            children: [
              SizedBox(
                width: _rank,
                child: Text('#', style: head),
              ),
              Expanded(flex: 5, child: Text('TITLE', style: head)),
              Expanded(flex: 4, child: Text('AUTHOR', style: head)),
              number('BOUGHT', _count, head),
              number('RENTED', _count, head),
              number('COPIES', _count, head),
              number('REVENUE', _money, head),
            ],
          ),
        ),
        Container(height: 1, color: c.hairline),
        for (final (i, b) in books.indexed) ...[
          if (i > 0)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: Space.lg),
              color: c.hairline,
            ),
          Semantics(
            container: true,
            label: '${i + 1}. ${b.title} by ${b.author}: ${b.copies} copies, ${b.bought} bought, ${b.rented} rented, ${money(b.revenue)}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.md),
              child: Row(
                children: [
                  SizedBox(
                    width: _rank,
                    child: Text('${i + 1}', style: t.titleSmall!.copyWith(color: c.textTertiary)),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(b.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: cell),
                  ),
                  number('${b.bought}', _count, cell),
                  number('${b.rented}', _count, cell),
                  number('${b.copies}', _count, t.titleSmall!),
                  number(money(b.revenue), _money, t.titleSmall!),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The orders of the period, one compact row each: order, customer, date, total, payment.
class _Orders extends StatelessWidget {
  const _Orders({required this.orders});

  final List<Order> orders;

  static const double _payment = 130;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    Widget head(String text, {int flex = 1, TextAlign align = TextAlign.left}) => Expanded(
      flex: flex,
      child: Text(text, textAlign: align, style: t.labelSmall),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.md),
          child: Row(
            children: [
              head('ORDER', flex: 2),
              head('CUSTOMER', flex: 3),
              head('DATE', flex: 4),
              head('TOTAL', flex: 2, align: TextAlign.right),
              const SizedBox(width: Space.xl),
              SizedBox(
                width: _payment,
                child: Text('PAYMENT', style: t.labelSmall),
              ),
            ],
          ),
        ),
        Container(height: 1, color: c.hairline),
        for (final (i, o) in orders.indexed) ...[
          if (i > 0)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: Space.lg),
              color: c.hairline,
            ),
          Semantics(
            container: true,
            label: 'Order ${o.id}, ${o.username}, ${formatMoment(o.createdAt)}, ${money(o.total)}, ${o.isPaid ? 'paid' : 'payment pending'}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.sm),
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
                  SizedBox(
                    width: _payment,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StatusChip(
                        label: o.isPaid ? 'Paid' : 'Pending',
                        icon: o.isPaid ? Icons.check_rounded : Icons.schedule_rounded,
                        filled: o.isPaid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
