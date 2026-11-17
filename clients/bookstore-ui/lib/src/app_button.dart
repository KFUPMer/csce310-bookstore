import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

enum AppButtonStyle {
  /// The one main action of a screen: solid.
  primary,

  /// Other actions: outlined.
  secondary,

  /// Low-emphasis actions: text only.
  quiet,
}

/// The button used everywhere in both apps.
///
/// Reacts to hover, press, and keyboard focus. While [loading] it shows a
/// spinner and ignores clicks, so an action cannot be sent twice.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.trailing,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final IconData? icon;
  final bool loading;
  final bool expand;

  /// Right-aligned text inside the button, e.g. a price.
  final String? trailing;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hover = false;
  bool _down = false;
  bool _focus = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final primary = widget.style == AppButtonStyle.primary;

    final Color fill;
    final Color fg;
    switch (widget.style) {
      case AppButtonStyle.primary:
        fill = _hover && _enabled ? Color.lerp(c.ink, c.background, 0.14)! : c.ink;
        fg = c.onInk;
      case AppButtonStyle.secondary:
      case AppButtonStyle.quiet:
        fill = _hover && _enabled ? c.hover : Colors.transparent;
        fg = c.text;
    }

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: widget.trailing != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
      children: [
        // Flexible: in a narrow space the label is shortened with "…" rather than overflowing.
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.loading)
                Padding(
                  padding: const EdgeInsets.only(right: Space.sm),
                  child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: fg)),
                )
              else if (widget.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: Space.sm),
                  child: Icon(widget.icon, size: 17, color: fg),
                ),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: Space.sm),
          Text(
            widget.trailing!,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(color: fg.withValues(alpha: 0.85), fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.trailing == null ? widget.label : '${widget.label}, ${widget.trailing}',
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed?.call())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: _enabled ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _down ? 0.975 : 1,
            duration: Motion.fast,
            curve: Motion.curve,
            child: AnimatedOpacity(
              opacity: widget.onPressed == null ? 0.4 : 1,
              duration: Motion.fast,
              child: AnimatedContainer(
                duration: Motion.fast,
                curve: Motion.curve,
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(Radii.control),
                  border: Border.all(
                    color: _focus ? c.accent : (widget.style == AppButtonStyle.secondary ? c.hairline : Colors.transparent),
                    width: _focus ? 2 : 1,
                  ),
                  boxShadow: primary && _enabled
                      ? [
                          BoxShadow(
                            color: c.shadow.withValues(alpha: c.shadow.a * 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                            spreadRadius: -4,
                          ),
                        ]
                      : null,
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round icon-only button with a tooltip, for toolbars.
class AppIconButton extends StatefulWidget {
  const AppIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.selected = false});

  final IconData icon;

  /// Also read by screen readers, since the button has no visible text.
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        selected: widget.selected,
        excludeSemantics: true,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowHoverHighlight: (v) => setState(() => _hover = v),
          onShowFocusHighlight: (v) => setState(() => _focus = v),
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed?.call())},
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: Motion.fast,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.selected ? c.ink : (_hover ? c.hover : Colors.transparent),
                borderRadius: BorderRadius.circular(Radii.control),
                border: Border.all(color: _focus ? c.accent : Colors.transparent, width: 2),
              ),
              child: Icon(widget.icon, size: 19, color: widget.selected ? c.onInk : c.text),
            ),
          ),
        ),
      ),
    );
  }
}
