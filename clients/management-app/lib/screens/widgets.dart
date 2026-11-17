import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A message in place of a list: nothing to show, or a failure. Used by both tabs.
class Message extends StatelessWidget {
  const Message({super.key, required this.icon, required this.title, required this.text, this.action});

  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Space.xxxl * 1.5, horizontal: Space.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.panel),
          border: Border.all(color: c.hairline),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: c.textTertiary),
            const SizedBox(height: Space.lg),
            Text(title, style: t.titleLarge),
            const SizedBox(height: Space.sm),
            Text(
              text,
              textAlign: TextAlign.center,
              style: t.bodyMedium!.copyWith(color: c.textSecondary),
            ),
            if (action != null) ...[const SizedBox(height: Space.xl), action!],
          ],
        ),
      ),
    );
  }
}
