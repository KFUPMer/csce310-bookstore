import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// A rating shown as stars, in the text color: the stars are filled, half, or
/// outlined, so the rating is told by shape and by the number, never by color.
///
/// With a [count], the average and the number of reviews follow the stars
/// ("4.3 · 12 reviews"). [compact], for the narrow book cards, is one star with
/// "4.3 (12)". Read out as one sentence: "Rated 4.3 out of 5 from 12 reviews".
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.count, this.compact = false, this.size = 16});

  /// 0 to 5; may have a decimal (an average).
  final double rating;

  /// How many reviews the rating comes from; null for one customer's own stars.
  final int? count;
  final bool compact;
  final double size;

  String get _average => rating.toStringAsFixed(1);

  String get _semanticLabel {
    if (count == null) return 'Rated ${rating == rating.roundToDouble() ? rating.round() : _average} out of 5 stars';
    return 'Rated $_average out of 5 from $count ${count == 1 ? 'review' : 'reviews'}';
  }

  /// Filled from three quarters of a star up, half from a quarter, else outlined.
  static IconData iconFor(double rating, int star) {
    if (rating >= star - 0.25) return Icons.star_rounded;
    if (rating >= star - 0.75) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final Widget content;
    if (compact) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: c.text),
          const SizedBox(width: 3),
          Flexible(
            child: Text('$_average${count == null ? '' : ' ($count)'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
          ),
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var star = 1; star <= 5; star++) Icon(iconFor(rating, star), size: size, color: c.text),
          if (count != null) ...[
            const SizedBox(width: Space.sm - 2),
            Flexible(
              child: Text(
                '$_average · $count ${count == 1 ? 'review' : 'reviews'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall,
              ),
            ),
          ],
        ],
      );
    }
    return Semantics(label: _semanticLabel, excludeSemantics: true, child: content);
  }
}

/// Five stars to choose a rating with. Each star is a button with a tooltip
/// ("4 stars"); Tab moves between them and Enter or Space chooses. The chosen
/// stars are filled and the rest outlined, and the choice is also written in
/// words beside them.
class StarPicker extends StatefulWidget {
  const StarPicker({super.key, required this.value, required this.onChanged, this.size = 30});

  /// The chosen number of stars; null before one is chosen.
  final int? value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  State<StarPicker> createState() => _StarPickerState();
}

class _StarPickerState extends State<StarPicker> {
  /// The star under the pointer: the stars up to it are filled as a preview.
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    final shown = _hovered ?? widget.value ?? 0;
    final value = widget.value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          _PickStar(
            star: star,
            filled: star <= shown,
            selected: star == value,
            size: widget.size,
            onHover: (on) => setState(() => _hovered = on ? star : (_hovered == star ? null : _hovered)),
            onTap: () => widget.onChanged(star),
          ),
        const SizedBox(width: Space.md),
        Flexible(child: Text(value == null ? 'No stars chosen' : '$value of 5 stars', style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class _PickStar extends StatefulWidget {
  const _PickStar({required this.star, required this.filled, required this.selected, required this.size, required this.onHover, required this.onTap});

  final int star;
  final bool filled;
  final bool selected;
  final double size;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  @override
  State<_PickStar> createState() => _PickStarState();
}

class _PickStarState extends State<_PickStar> {
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final name = widget.star == 1 ? '1 star' : '${widget.star} stars';
    return Tooltip(
      message: name,
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: name,
        excludeSemantics: true,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowHoverHighlight: widget.onHover,
          onShowFocusHighlight: (v) => setState(() => _focus = v),
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.curve,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.control),
                border: Border.all(color: _focus ? c.accent : Colors.transparent, width: 2),
              ),
              child: Icon(widget.filled ? Icons.star_rounded : Icons.star_outline_rounded, size: widget.size, color: c.text),
            ),
          ),
        ),
      ),
    );
  }
}
