import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app_button.dart';
import 'tokens.dart';

/// A labelled text field. Its problem, if any, is written under it with an
/// icon, so an error is never told by the red border alone.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.error,
    this.hint,
    this.password = false,
    this.autofocus = false,
    this.enabled = true,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;

  /// The problem with the value, shown under the field. Null when there is none.
  final String? error;
  final String? hint;

  /// Hides the text, with a button to show it.
  final bool password;
  final bool autofocus;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_changed);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    final focused = _focus.hasFocus;
    final hasError = widget.error != null;
    final borderColor = focused ? c.accent : (hasError ? c.danger : c.hairline);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: t.labelMedium),
        const SizedBox(height: Space.sm - 2),
        AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.curve,
          height: 44,
          padding: EdgeInsets.only(left: Space.md, right: widget.password ? Space.xs : Space.md),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: widget.enabled ? 1 : 0.5),
            borderRadius: BorderRadius.circular(Radii.control),
            border: Border.all(color: borderColor, width: focused || hasError ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  enabled: widget.enabled,
                  obscureText: widget.password && _hidden,
                  autofillHints: widget.autofillHints,
                  textInputAction: widget.textInputAction,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: t.bodyLarge,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: t.bodyLarge!.copyWith(color: c.textTertiary),
                  ),
                ),
              ),
              if (widget.password)
                ExcludeFocus(
                  child: AppIconButton(
                    icon: _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _hidden = !_hidden),
                  ),
                ),
            ],
          ),
        ),
        AnimatedSize(
          duration: Motion.fast,
          curve: Motion.curve,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: Space.xs + 2),
                  child: ErrorMessage(widget.error!, small: true),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// A problem, said in a sentence with an icon (never by color alone).
/// Read out by screen readers when it appears.
class ErrorMessage extends StatelessWidget {
  const ErrorMessage(this.message, {super.key, this.small = false});

  final String message;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final style = (small ? Theme.of(context).textTheme.bodySmall : Theme.of(context).textTheme.bodyMedium)!.copyWith(color: c.danger);
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline_rounded, size: small ? 15 : 17, color: c.danger),
          ),
          const SizedBox(width: Space.sm - 2),
          Expanded(child: Text(message, style: style)),
        ],
      ),
    );
  }
}
