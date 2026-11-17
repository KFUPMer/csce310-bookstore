import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'app_button.dart';
import 'glass.dart';
import 'tokens.dart';

/// Hosts the toast: a short glass message at the bottom of the window that
/// confirms what just happened, with Undo when it can be undone (Nielsen 1, 3).
///
/// Put one around the app's navigator; any screen calls
/// `ToastHost.of(context).show('Added to order', undo: ...)`.
class ToastHost extends StatefulWidget {
  const ToastHost({super.key, required this.child});

  final Widget child;

  static ToastHostState of(BuildContext context) => context.findAncestorStateOfType<ToastHostState>()!;

  @override
  State<ToastHost> createState() => ToastHostState();
}

class ToastHostState extends State<ToastHost> {
  String? _message;
  VoidCallback? _undo;
  IconData _icon = Icons.check_circle_outline_rounded;
  Timer? _timer;

  /// Shows [message] for a few seconds. [undo] adds an Undo button.
  void show(String message, {VoidCallback? undo, IconData icon = Icons.check_circle_outline_rounded}) {
    _timer?.cancel();
    setState(() {
      _message = message;
      _undo = undo;
      _icon = icon;
    });
    _timer = Timer(Duration(seconds: undo == null ? 4 : 6), hide);
  }

  void hide() {
    _timer?.cancel();
    if (mounted) setState(() => _message = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final visible = _message != null;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0,
          right: 0,
          bottom: Space.xl,
          child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedSlide(
              duration: Motion.base,
              curve: Motion.curve,
              offset: visible ? Offset.zero : const Offset(0, 0.6),
              child: AnimatedOpacity(
                duration: Motion.base,
                opacity: visible ? 1 : 0,
                child: Center(
                  child: Semantics(
                    liveRegion: true,
                    child: Glass(
                      radius: Radii.pill,
                      padding: const EdgeInsets.fromLTRB(Space.lg, Space.xs, Space.xs, Space.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_icon, size: 17, color: c.text),
                          const SizedBox(width: Space.sm),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Text(_message ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          const SizedBox(width: Space.sm),
                          if (_undo != null)
                            AppButton(
                              label: 'Undo',
                              style: AppButtonStyle.quiet,
                              onPressed: () {
                                _undo?.call();
                                hide();
                              },
                            )
                          else
                            const SizedBox(width: Space.md, height: 42),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A page change that fades and rises slightly into place, instead of the
/// platform's default. Used for every screen change in both apps.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: Motion.slow,
  reverseTransitionDuration: Motion.base,
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (_, animation, _, child) {
    final curved = CurvedAnimation(parent: animation, curve: Motion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  },
);
