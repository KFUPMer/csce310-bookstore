import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// A translucent panel: whatever is behind it shows through, blurred.
///
/// Used for surfaces that float above content (the top bar, the detail
/// panel, toasts), so book covers scrolling underneath tint the glass.
class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.radius = Radii.panel, this.padding = EdgeInsets.zero, this.blur = 28, this.elevated = true});

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blur;

  /// Whether to draw a soft shadow under the panel.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: c.shadow.withValues(alpha: c.shadow.a * 0.6),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                  spreadRadius: -12,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: shape,
              border: Border.all(color: c.glassBorder),
            ),
            // A faint light edge along the top, like light catching glass.
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: shape,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: const Alignment(0, -0.2),
                  colors: [c.glassHighlight, c.glassHighlight.withValues(alpha: 0)],
                ),
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
