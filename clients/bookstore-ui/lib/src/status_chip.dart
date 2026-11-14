import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// A small label with an icon, for states such as "Paid" or "Unavailable".
///
/// The state is told by the icon and the word, never by color alone, so it
/// reads the same for color-blind users and in a black and white print.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.icon, this.filled = false});

  final String label;
  final IconData icon;

  /// Solid for a completed state (e.g. Paid), outlined for a waiting one.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final fg = filled ? c.onInk : c.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? c.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: filled ? c.ink : c.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: fg)),
        ],
      ),
    );
  }
}
