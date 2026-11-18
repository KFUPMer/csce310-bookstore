import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';
import 'books_view.dart';
import 'orders_view.dart';
import 'reports_view.dart';

/// The manager's main screen: the Orders, Books, and Reports tabs under one glass bar.
///
/// Every tab stays alive when switching, so a search or a scroll position is
/// not lost.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double barHeight = 64;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final scope = ManagerScope.of(context);
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final username = scope.services.session.username ?? '';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            top: barHeight + Space.md,
            child: IndexedStack(
              index: _tab,
              children: [
                const OrdersView(),
                const BooksView(),
                ReportsView(visible: _tab == 2),
              ],
            ),
          ),
          Positioned(
            top: Space.md,
            left: Space.lg,
            right: Space.lg,
            height: barHeight,
            child: Glass(
              radius: Radii.panel,
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: Row(
                children: [
                  const MooneysSign(height: 38),
                  const SizedBox(width: Space.sm),
                  Text('MANAGER', style: t.labelSmall!.copyWith(letterSpacing: 1.6)),
                  const SizedBox(width: Space.lg),
                  Tabs(
                    labels: const ['Orders', 'Books', 'Reports'],
                    icons: const [Icons.receipt_long_outlined, Icons.menu_book_outlined, Icons.insights_outlined],
                    selected: _tab,
                    onSelected: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(width: Space.sm),
                  // The name takes whatever room is left and is cut short with "..." when a long
                  // username (up to 50 characters) would not fit; the tooltip has it in full.
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppIconButton(
                          icon: scope.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          tooltip: scope.isDark ? 'Switch to light mode' : 'Switch to dark mode',
                          onPressed: scope.toggleTheme,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: Space.sm),
                          color: c.hairline,
                        ),
                        Flexible(
                          child: Tooltip(
                            message: 'Logged in as $username',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.badge_outlined, size: 17, color: c.textSecondary),
                                const SizedBox(width: Space.xs),
                                Flexible(
                                  child: Text(
                                    username,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodyMedium!.copyWith(color: c.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.xs),
                        AppIconButton(icon: Icons.logout_rounded, tooltip: 'Log out', onPressed: scope.services.users.logout),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two or more tabs side by side, the chosen one filled. Keyboard: Tab to reach, Enter to choose.
class Tabs extends StatelessWidget {
  const Tabs({super.key, required this.labels, required this.selected, required this.onSelected, this.icons, this.counts});

  final List<String> labels;
  final List<IconData>? icons;

  /// Shown after each label, e.g. how many orders a filter shows.
  final List<int>? counts;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.hover, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            _Tab(label: labels[i], icon: icons?[i], count: counts?[i], selected: i == selected, onTap: () => onSelected(i)),
        ],
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({required this.label, required this.icon, required this.count, required this.selected, required this.onTap});

  final String label;
  final IconData? icon;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
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
      label: widget.count == null ? widget.label : '${widget.label}, ${widget.count}',
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Motion.base,
            curve: Motion.curve,
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 7),
            decoration: BoxDecoration(
              color: widget.selected ? c.ink : (_hover ? c.hover : Colors.transparent),
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: _focus ? c.accent : Colors.transparent, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[Icon(widget.icon, size: 15, color: fg), const SizedBox(width: Space.xs + 2)],
                Text(widget.label, style: t.labelLarge!.copyWith(color: fg, fontSize: 13)),
                if (widget.count != null) ...[
                  const SizedBox(width: Space.sm - 2),
                  Text('${widget.count}', style: t.labelMedium!.copyWith(color: fg.withValues(alpha: 0.75))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
