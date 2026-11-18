import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';

/// The most a review may say, as book-service allows. Counted in Unicode characters (code points), as Python's len() does,
/// not in Dart's UTF-16 units or in what the eye sees as one character: an emoji family is one picture but five code points.
const reviewMaxLength = 1000;

/// How long [text] is to book-service.
int reviewLength(String text) => text.runes.length;

/// Cuts what is typed or pasted to [reviewMaxLength] code points, so the service never refuses it for length.
class _ReviewLengthLimit extends TextInputFormatter {
  const _ReviewLengthLimit();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (reviewLength(newValue.text) <= reviewMaxLength) return newValue;
    final cut = String.fromCharCodes(newValue.text.runes.take(reviewMaxLength));
    return TextEditingValue(
      text: cut,
      selection: TextSelection.collapsed(offset: cut.length),
    );
  }
}

/// Writes the customer's review of [book], or edits [mine] when they already wrote one.
/// Extra credit, beyond the PRD.
///
/// Returns the saved review, or null if the customer cancelled.
Future<Review?> showReviewDialog(BuildContext context, Book book, {Review? mine}) => showDialog<Review>(
  context: context,
  barrierColor: Colors.black38,
  builder: (_) => _ReviewDialog(book: book, mine: mine),
);

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.book, required this.mine});

  final Book book;
  final Review? mine;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late int? _stars = widget.mine?.rating;
  late final _text = TextEditingController(text: widget.mine?.text ?? '');
  bool _saving = false;

  /// "Choose a rating" once the customer tried to save without stars.
  String? _starsProblem;

  /// What book-service answered, when it refused.
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final stars = _stars;
    if (stars == null) {
      setState(() => _starsProblem = 'Choose a rating from 1 to 5 stars');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await AppScope.of(context).services.books.saveMyReview(widget.book.id, stars, _text.text);
      if (!mounted) return;
      ToastHost.of(context).show('Your review of ${widget.book.title} is saved. Thank you!');
      Navigator.of(context).pop(saved);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    void cancel() => Navigator.of(context).pop();

    // While saving, Esc and a click outside wait: closing early would lose the saved review, and the panel would not show it.
    return PopScope(
      canPop: !_saving,
      child: Dialog(
        backgroundColor: c.background,
        insetPadding: const EdgeInsets.all(Space.xxl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.panel)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          // Scrolls when the window is too short to show everything.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(widget.mine == null ? 'Write a review' : 'Edit your review', style: t.headlineSmall)),
                    AppIconButton(icon: Icons.close_rounded, tooltip: 'Close (Esc)', onPressed: _saving ? null : cancel),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Text('${widget.book.title} by ${widget.book.author}', style: t.bodyMedium!.copyWith(color: c.textSecondary)),
                const SizedBox(height: Space.xl),
                Text('Your rating', style: t.labelMedium),
                const SizedBox(height: Space.xs),
                StarPicker(
                  value: _stars,
                  onChanged: (v) => setState(() {
                    _stars = v;
                    _starsProblem = null;
                  }),
                ),
                if (_starsProblem != null) ...[const SizedBox(height: Space.xs), ErrorMessage(_starsProblem!, small: true)],
                const SizedBox(height: Space.xl),
                AppTextField(
                  label: 'What did you think? (optional)',
                  controller: _text,
                  lines: 5,
                  inputFormatters: const [_ReviewLengthLimit()],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: Space.xs),
                Text('${reviewLength(_text.text)} / $reviewMaxLength', textAlign: TextAlign.right, style: t.bodySmall),
                if (_error != null) ...[const SizedBox(height: Space.md), ErrorMessage(_error!)],
                const SizedBox(height: Space.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(label: 'Cancel', style: AppButtonStyle.secondary, onPressed: _saving ? null : cancel),
                    const SizedBox(width: Space.sm),
                    AppButton(label: 'Save', icon: Icons.check_rounded, loading: _saving, onPressed: _save),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
