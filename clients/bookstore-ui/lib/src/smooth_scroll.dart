import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Makes mouse-wheel scrolling glide instead of jumping a step at a time.
///
/// Flutter on desktop moves the page instantly for each wheel notch. This
/// widget takes over the wheel and animates to the new position instead.
/// The scroll view inside must use [controller] and [physics].
class SmoothScroll extends StatefulWidget {
  const SmoothScroll({super.key, required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  /// Give this to the scroll view so that it leaves the wheel to us.
  static const ScrollPhysics physics = NeverScrollableScrollPhysics();

  @override
  State<SmoothScroll> createState() => _SmoothScrollState();
}

class _SmoothScrollState extends State<SmoothScroll> {
  double? _target;

  void _onSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !widget.controller.hasClients) return;
    final position = widget.controller.position;
    final from = _target ?? position.pixels;
    final to = (from + event.scrollDelta.dy).clamp(position.minScrollExtent, position.maxScrollExtent).toDouble();
    if (to == position.pixels) return;
    _target = to;
    // A precise device (small deltas) already scrolls smoothly: follow it directly.
    if (event.scrollDelta.dy.abs() < 20) {
      position.jumpTo(to);
      _target = null;
      return;
    }
    position.animateTo(to, duration: Motion.base, curve: Motion.curve).whenComplete(() {
      if (_target == to) _target = null;
    });
  }

  void _onPan(PointerPanZoomUpdateEvent event) {
    if (!widget.controller.hasClients) return;
    final position = widget.controller.position;
    final to = (position.pixels - event.panDelta.dy).clamp(position.minScrollExtent, position.maxScrollExtent).toDouble();
    position.jumpTo(to);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(onPointerSignal: _onSignal, onPointerPanZoomUpdate: _onPan, child: widget.child);
  }
}
