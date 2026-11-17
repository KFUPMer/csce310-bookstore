import 'package:material_ui/material_ui.dart';

import 'app_button.dart';
import 'tokens.dart';

/// The round search field of both apps: search by title or author (FR4).
///
/// Shows a small spinner while a search runs, a clear button once something is
/// typed, and the Ctrl F shortcut otherwise.
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller, required this.focusNode, required this.searching, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final FocusNode focusNode;

  /// A search is running: a small spinner replaces the search icon.
  final bool searching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) => AnimatedContainer(
        duration: Motion.fast,
        height: 40,
        padding: const EdgeInsets.only(left: Space.md, right: Space.xs),
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: focusNode.hasFocus ? 1 : 0.6),
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: focusNode.hasFocus ? c.accent : c.hairline, width: focusNode.hasFocus ? 2 : 1),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: searching
                  ? Padding(
                      padding: const EdgeInsets.all(2),
                      child: CircularProgressIndicator(strokeWidth: 1.6, color: c.textSecondary, semanticsLabel: 'Searching'),
                    )
                  : Icon(Icons.search_rounded, size: 18, color: c.textSecondary),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search by title or author',
                  hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c.textTertiary),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              AppIconButton(icon: Icons.close_rounded, tooltip: 'Clear search (Esc)', onPressed: onClear)
            else
              Padding(
                padding: const EdgeInsets.only(right: Space.sm),
                child: Text('Ctrl F', style: Theme.of(context).textTheme.labelSmall),
              ),
          ],
        ),
      ),
    );
  }
}
