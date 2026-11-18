import 'package:material_ui/material_ui.dart';

import 'book_cover.dart';
import 'mooneys_sign.dart';
import 'tokens.dart';

/// The layout of the log-in and create-account screens of both apps.
///
/// A form card on the right; on the left, the store's sign, a fan of book covers,
/// and one sentence about the app. The sign and the covers are the only color on the
/// screen (style guide). In a narrow window the left side is left out.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.tagline,
    required this.note,
    required this.coverTitles,
    required this.child,
    this.actions = const [],
    this.coverUrls = const [],
  });

  /// One sentence about the app, in the serif.
  final String tagline;

  /// A short line under it.
  final String note;

  /// Three titles for the fanned covers.
  final List<String> coverTitles;

  /// Photos for those covers, in the same order. Without internet the covers are drawn instead.
  final List<String> coverUrls;

  /// The form.
  final Widget child;

  /// Small buttons in the top right corner, e.g. light/dark mode.
  final List<Widget> actions;

  static const double _cardWidth = 420;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;

    final card = Container(
      width: _cardWidth,
      padding: const EdgeInsets.all(Space.xxl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.panel),
        border: Border.all(color: c.hairline),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: c.shadow.a * 0.5),
            blurRadius: 48,
            offset: const Offset(0, 20),
            spreadRadius: -18,
          ),
        ],
      ),
      child: child,
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 920;
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.xxxl, vertical: Space.xxl),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (wide) ...[
                            Flexible(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 460),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const MooneysSign(height: 62, line: 'BOOKSELLERS  ·  EST. 2026'),
                                    const SizedBox(height: Space.xxl),
                                    _CoverFan(titles: coverTitles, urls: coverUrls),
                                    const SizedBox(height: Space.xl),
                                    Text(tagline, style: t.displaySmall),
                                    const SizedBox(height: Space.md),
                                    Text(note, style: t.bodyLarge!.copyWith(color: c.textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: Space.xxxl * 2),
                          ],
                          card,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: Space.md,
              right: Space.lg,
              child: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three covers fanned out like books on a table.
class _CoverFan extends StatelessWidget {
  const _CoverFan({required this.titles, required this.urls});

  final List<String> titles;
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    const width = 132.0;
    const angles = [-0.14, 0.0, 0.14];
    const offsets = [0.0, 104.0, 208.0];
    return ExcludeSemantics(
      child: SizedBox(
        width: offsets.last + width + 24,
        height: width * 1.5 + 36,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Drawn left to right: each cover overlaps the right side of the one before it,
            // which is empty, rather than the start of the next one's title.
            for (final i in [0, 1, 2])
              Positioned(
                left: offsets[i],
                top: i == 1 ? 0 : 18,
                child: Transform.rotate(
                  angle: angles[i],
                  alignment: Alignment.bottomCenter,
                  child: BookCover(
                    title: titles[i % titles.length],
                    author: '',
                    imageUrl: i < urls.length ? urls[i] : null,
                    width: i == 1 ? width + 8 : width,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
