import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// A book cover with a 2:3 shape.
///
/// Shows [imageUrl] when the book has one. Otherwise it draws a cover from
/// the title: a muted color picked from the title itself (so a book always
/// gets the same one), the title set in a serif, and a soft sheen.
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.title, required this.author, this.imageUrl, this.width = 150, this.dimmed = false});

  final String title;
  final String author;
  final String? imageUrl;
  final double width;

  /// Faded, for a book that cannot be ordered.
  final bool dimmed;

  /// Where a cover photo is loaded from: the internet. The screenshot tests point it at
  /// photos downloaded beforehand, because tests have no internet.
  static ImageProvider Function(String url) imageFor = NetworkImage.new;

  /// A hue between 0 and 360 that depends only on the title.
  static double hueFor(String title) {
    var hash = 7;
    for (final unit in title.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return (hash % 360).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final height = width * 1.5;
    final hue = hueFor(title);
    final top = HSLColor.fromAHSL(1, hue, 0.30, 0.43).toColor();
    final bottom = HSLColor.fromAHSL(1, (hue + 22) % 360, 0.36, 0.27).toColor();
    final scale = width / 150;

    Widget face;
    if (imageUrl != null) {
      // The drawn cover shows until the photo has arrived, then the photo fades in over it:
      // never an empty slot. Without internet, or for a broken address, the drawn cover stays.
      face = Image(
        image: imageFor(imageUrl!),
        fit: BoxFit.cover,
        width: width,
        height: height,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => wasSynchronouslyLoaded
            ? child
            : Stack(
                fit: StackFit.expand,
                children: [
                  _generated(top, bottom, scale),
                  AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: Motion.base, curve: Motion.curve, child: child),
                ],
              ),
        errorBuilder: (_, _, _) => _generated(top, bottom, scale),
      );
    } else {
      face = _generated(top, bottom, scale);
    }

    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.cover),
          boxShadow: [BoxShadow(color: c.shadow, blurRadius: 18 * scale, offset: Offset(0, 10 * scale), spreadRadius: -6 * scale)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.cover),
          child: Stack(
            fit: StackFit.expand,
            children: [
              face,
              // Spine shadow on the left edge.
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: width * 0.07,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0x4D000000), Color(0x0D000000), Color(0x1AFFFFFF)], stops: [0, 0.75, 1]),
                  ),
                ),
              ),
              // Gloss: light falling across the cover from the top left.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x38FFFFFF), Color(0x00FFFFFF), Color(0x1F000000)],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _generated(Color top, Color bottom, double scale) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(17 * scale, 20 * scale, 9 * scale, 14 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 22 * scale, height: 2 * scale, color: const Color(0xB3FFFFFF)),
            SizedBox(height: 12 * scale),
            Expanded(
              child: Text(
                title,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: Fonts.display,
                  fontSize: 14.5 * scale,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
            Text(
              author.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: Fonts.ui,
                fontFamilyFallback: Fonts.uiFallback,
                fontSize: 8.5 * scale,
                height: 1.3,
                letterSpacing: 0.9 * scale,
                fontWeight: FontWeight.w600,
                color: const Color(0xD9FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
