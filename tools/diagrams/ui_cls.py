"""Class diagram of the shared bookstore_ui package."""
import sys
import flutter_cls as F  # also regenerates the two app diagrams (unchanged)

COL, R = F.COL, [40, 330, 600]
PURPLE = ('#e1d5e7', '#9673a6')
B = '+ build(context) : Widget'
c = [
 F.cls('colors', 'BookstoreColors', COL[0], R[0], ['+ background, surface : Color', '+ glass, glassBorder, glassHighlight', '+ text, textSecondary, textTertiary', '+ hairline, hover, shadow', '+ accent, ink, onInk, danger', '+ light : BookstoreColors (static)', '+ dark : BookstoreColors (static)'],
       ['+ of(context) : BookstoreColors', '+ lerp(other, t) : BookstoreColors'], PURPLE, 'ThemeExtension'),
 F.cls('space', 'Space', COL[1], R[0], ['xs = 4, sm = 8, md = 12', 'lg = 16, xl = 24', 'xxl = 32, xxxl = 48'], None, PURPLE, 'constants'),
 F.cls('radii', 'Radii', COL[2], R[0], ['cover = 6, control = 10', 'card = 16, panel = 22', 'pill = 999'], None, PURPLE, 'constants'),
 F.cls('motion', 'Motion', COL[3], R[0], ['fast = 140 ms', 'base = 240 ms', 'slow = 380 ms', 'curve = easeOutCubic'], None, PURPLE, 'constants'),
 F.cls('fonts', 'Fonts', COL[4], R[0], ['ui = Inter', 'uiFallback = Segoe UI', 'display = Source Serif 4'], None, PURPLE, 'constants'),
 F.cls('theme', 'buildBookstoreTheme', COL[0], R[1], ['(brightness : Brightness)'], ['returns ThemeData:', 'text styles, color scheme,', 'tooltips, scrollbars, no ripples'], F.GREY, 'function'),
 F.cls('glass', 'Glass', COL[1], R[1], ['+ child : Widget', '+ radius : double', '+ padding : EdgeInsets', '+ blur : double', '+ elevated : bool'], [B], F.BLUE, 'widget'),
 F.cls('cover', 'BookCover', COL[2], R[1], ['+ title : String', '+ author : String', '+ imageUrl : String?', '+ width : double', '+ dimmed : bool'], [B, '+ hueFor(title) : double (static)', '- generated(top, bottom, scale)'], F.BLUE, 'widget'),
 F.cls('button', 'AppButton', COL[3], R[1], ['+ label : String', '+ onPressed : VoidCallback?', '+ style : AppButtonStyle', '+ icon : IconData?', '+ loading : bool', '+ expand : bool', '+ trailing : String?'], [B], F.BLUE, 'widget'),
 F.cls('icon', 'AppIconButton', COL[4], R[1], ['+ icon : IconData', '+ tooltip : String', '+ onPressed : VoidCallback?', '+ selected : bool'], [B], F.BLUE, 'widget'),
 F.cls('scroll', 'SmoothScroll', COL[1], R[2], ['+ controller : ScrollController', '+ child : Widget', '+ physics (static)'], [B, '- onSignal(event) : void', '- onPan(event) : void'], F.BLUE, 'widget'),
 F.cls('chip', 'StatusChip', COL[2], R[2], ['+ label : String', '+ icon : IconData', '+ filled : bool'], [B], F.BLUE, 'widget'),
 F.cls('bstyle', 'AppButtonStyle', COL[3], R[2] + 30, ['primary', 'secondary', 'quiet'], None, F.YELLOW, 'enumeration'),
 F.edge('uses', 'theme', 'colors', 'builds from'),
 F.edge('opens', 'button', 'bstyle'),
 F.note(COL[4], R[2], 150, ['Purple: design tokens (tokens.dart)', 'Blue: reusable widgets', 'Grey: the theme (theme.dart)', '', 'Every widget reads its colors from', 'BookstoreColors.of(context), so it follows', 'light and dark mode automatically.']),
]
F.write('class-bookstore-ui', 'Shared UI package classes', c)
print('ui written')
