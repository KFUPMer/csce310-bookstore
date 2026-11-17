"""Class diagram of the shared bookstore_ui package."""
import sys
import flutter_cls as F  # also regenerates the two app diagrams (unchanged)

COL, R = F.COL, [40, 330, 600, 830, 1080]
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
 # Added in M4, used by both apps.
 F.cls('format', 'format.dart', COL[0], R[2], ['the way the HTML bill writes them'], ['money(amount) : String   ($1,234.50)', 'toCents(amount) : int', 'formatDay(date) : String', 'formatMoment(dateTime) : String'], F.GREY, 'module'),
 F.cls('field', 'AppTextField', COL[0], R[3], ['+ label : String', '+ controller', '+ error : String?', '+ hint : String?', '+ password : bool  (show/hide button)', '+ onChanged, onSubmitted'], [B], F.BLUE, 'widget'),
 F.cls('error', 'ErrorMessage', COL[1], R[3], ['+ message : String', '+ small : bool'], [B, '(icon + sentence, read out', ' by screen readers)'], F.BLUE, 'widget'),
 F.cls('toast', 'ToastHost', COL[2], R[3], ['- message : String?', '- undo : VoidCallback?'], [B, '+ of(context) (static)', '+ show(message, undo, icon)', '+ hide()'], F.BLUE, 'widget'),
 F.cls('bill', 'BillView', COL[3], R[3], ['+ orderId : int', '+ createdAt : DateTime', '+ username, email : String', '+ lines : List<BillLine>', '+ total : double', '+ paid : bool'], [B], F.BLUE, 'widget'),
 F.cls('line', 'BillLine', COL[4], R[3], ['+ title, author : String', '+ rented : bool', '+ quantity : int', '+ unitPrice : double', '+ dueBack : DateTime?'], None, F.YELLOW),
 F.cls('auth', 'AuthLayout', COL[0], R[4], ['+ tagline, note : String', '+ coverTitles : List<String>', '+ child : Widget  (the form)', '+ actions : List<Widget>'], [B, '(form card, and a fan of', ' three BookCovers)'], F.BLUE, 'widget'),
 F.cls('route', 'fadeRoute', COL[2], R[4], ['(page : Widget)'], ['returns a Route that fades and', 'rises into place (Motion.slow)'], F.GREY, 'function'),
 F.edge('uses', 'theme', 'colors', 'builds from'),
 F.edge('opens', 'button', 'bstyle'),
 F.edge('uses', 'field', 'error', 'shows'),
 F.edge('has', 'bill', 'line', '1..*'),
 F.note(COL[4], R[2], 150, ['Purple: design tokens (tokens.dart)', 'Blue: reusable widgets', 'Grey: functions (theme, formatting, page change)', 'Yellow: plain data', '', 'Every widget reads its colors from', 'BookstoreColors.of(context), so it follows', 'light and dark mode automatically.']),
]
F.write('class-bookstore-ui', 'Shared UI package classes', c)
print('ui written')
