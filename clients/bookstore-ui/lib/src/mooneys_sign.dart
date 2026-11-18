import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// The store's sign: MOONEY’S in gold capitals on deep green, like a painted shopfront.
///
/// Inspired by the fictional Mooney's bookshop in the TV series "You" (credited in
/// REFERENCES.md); the lettering and the small line are this project's own. It is the
/// one place besides the book covers that has color (style guide), and it looks the
/// same in light and dark mode, as a painted sign would.
class MooneysSign extends StatelessWidget {
  const MooneysSign({super.key, this.height = 40, this.line});

  /// The sign's height; everything inside scales with it.
  final double height;

  /// A small line under the name, e.g. "BOOKSELLERS · EST. 2026". None in a top bar.
  final String? line;

  /// How the name is written in sentences and window titles.
  static const name = 'Mooney’s';

  static const green = Color(0xFF1D3B31);
  static const greenLight = Color(0xFF2A5141);
  static const gold = Color(0xFFD9B871);
  static const goldLight = Color(0xFFF2DDA2);
  static const goldDeep = Color(0xFFAE8840);

  static const _spacing = 5.5;

  @override
  Widget build(BuildContext context) {
    final words = ShaderMask(
      // Gold leaf: lighter at the top edge of the letters, deeper at the foot.
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [goldLight, gold, goldDeep],
        stops: [0, 0.55, 1],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Padding(
        // Letter spacing also follows the last letter; the same space in front keeps the word centered.
        padding: const EdgeInsets.only(left: _spacing),
        child: Text(
          'MOONEY’S',
          style: const TextStyle(
            fontFamily: Fonts.display,
            fontWeight: FontWeight.w600,
            fontSize: 26,
            letterSpacing: _spacing,
            height: 1.1,
            color: Colors.white,
          ),
        ),
      ),
    );

    return Semantics(
      label: line == null ? name : '$name, ${line!.toLowerCase()}',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: FittedBox(
          child: Container(
            padding: EdgeInsets.fromLTRB(20, line == null ? 9 : 13, 20, line == null ? 8 : 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [greenLight, green]),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: goldDeep.withValues(alpha: 0.55), width: 1.2),
              boxShadow: const [BoxShadow(color: Color(0x47000000), blurRadius: 12, offset: Offset(0, 4), spreadRadius: -3)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                words,
                if (line != null) ...[
                  const SizedBox(height: 6),
                  Container(width: 132, height: 0.8, color: gold.withValues(alpha: 0.55)),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.only(left: 2.4),
                    child: Text(
                      line!,
                      style: TextStyle(
                        fontFamily: Fonts.ui,
                        fontWeight: FontWeight.w600,
                        fontSize: 7.5,
                        letterSpacing: 2.4,
                        color: gold.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
