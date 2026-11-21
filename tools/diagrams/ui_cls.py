"""Class diagram of the shared bookstore_ui package."""
import sys
import flutter_cls as F  # also regenerates the two app diagrams (unchanged)

COL, R = F.COL, [40, 330, 600, 830, 1080, 1340, 1580, 1840]
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
 F.cls('cover', 'BookCover', COL[2], R[1], ['+ title : String', '+ author : String', '+ imageUrl : String?', '+ width : double', '+ dimmed : bool', '+ imageFor (static: where photos', '    come from; tests change it)'], [B, '+ hueFor(title) : double (static)', '- generated(top, bottom, scale)'], F.BLUE, 'widget'),
 F.cls('button', 'AppButton', COL[3], R[1], ['+ label : String', '+ onPressed : VoidCallback?', '+ style : AppButtonStyle', '+ icon : IconData?', '+ loading : bool', '+ expand : bool', '+ trailing : String?'], [B], F.BLUE, 'widget'),
 F.cls('icon', 'AppIconButton', COL[4], R[1], ['+ icon : IconData', '+ tooltip : String', '+ onPressed : VoidCallback?', '+ selected : bool'], [B], F.BLUE, 'widget'),
 F.cls('scroll', 'SmoothScroll', COL[1], R[2], ['+ controller : ScrollController', '+ child : Widget', '+ physics (static)'], [B, '- onSignal(event) : void', '- onPan(event) : void'], F.BLUE, 'widget'),
 F.cls('sign', 'MooneysSign', COL[4], R[3], ['+ height : double', '+ line : String?  (small line under it)', '+ name = "Mooney’s" (static)', '+ green, gold... : Color (static)'], [B, '(the store sign: gold capitals', ' on deep green; same in both modes)'], F.BLUE, 'widget'),
 F.cls('chip', 'StatusChip', COL[2], R[2], ['+ label : String', '+ icon : IconData', '+ filled : bool'], [B], F.BLUE, 'widget'),
 F.cls('bstyle', 'AppButtonStyle', COL[3], R[2] + 30, ['primary', 'secondary', 'quiet'], None, F.YELLOW, 'enumeration'),
 # Added in M4, used by both apps.
 F.cls('format', 'format.dart', COL[0], R[2], ['the way the HTML bill writes them'], ['money(amount) : String   ($1,234.50)', 'toCents(amount) : int', 'formatDay(date) : String', 'formatMoment(dateTime) : String'], F.GREY, 'module'),
 F.cls('field', 'AppTextField', COL[0], R[3], ['+ label : String', '+ controller', '+ error : String?', '+ hint : String?', '+ password : bool  (show/hide button)', '+ onChanged, onSubmitted'], [B], F.BLUE, 'widget'),
 F.cls('error', 'ErrorMessage', COL[1], R[3], ['+ message : String', '+ small : bool'], [B, '(icon + sentence, read out', ' by screen readers)'], F.BLUE, 'widget'),
 F.cls('toast', 'ToastHost', COL[2], R[3], ['- message : String?', '- undo : VoidCallback?'], [B, '+ of(context) (static)', '+ show(message, undo, icon)', '+ hide()'], F.BLUE, 'widget'),
 F.cls('bill', 'BillView', COL[3], R[3], ['+ order : Order', '+ email : String?  (if the order has none)'], [B, '(the same parts as the HTML bill,', ' with the current payment status)'], F.BLUE, 'widget'),
 F.cls('auth', 'AuthLayout', COL[0], R[4], ['+ tagline, note : String', '+ coverTitles, coverUrls', '    : List<String>', '+ child : Widget  (the form)', '+ actions : List<Widget>'], [B, '(form card, and a fan of', ' three BookCovers)'], F.BLUE, 'widget'),
 F.cls('login', 'LoginForm', COL[1], R[4], ['+ users : UserApi', '+ role : String  (CUSTOMER / MANAGER)', '+ wrongRoleMessage : String', '+ onLoggedIn : VoidCallback', '+ note, initialUsername : String?', '+ footer : Widget?'], [B, '- onLogin() : Future<void>'], F.BLUE, 'widget'),
 F.cls('route', 'fadeRoute', COL[2], R[4], ['(page : Widget)'], ['returns a Route that fades and', 'rises into place (Motion.slow)'], F.GREY, 'function'),
 F.cls('search', 'SearchField', COL[3], R[4], ['+ controller, focusNode', '+ searching : bool  (spinner)', '+ onChanged, onClear'], [B], F.BLUE, 'widget'),
 F.cls('info', 'InfoNote', COL[4], R[4], ['+ text : String'], [B, '(a neutral message with an icon)'], F.BLUE, 'widget'),
 # Talking to the services, shared by both apps (moved here from the customer app in M4).
 F.cls('uapi', 'UserApi', COL[0], R[5], ['(user-service, port 8081)'], ['+ login(username, password)', '+ logout({reason})', '+ register(username, email, password)'], F.GREEN),
 F.cls('bapi', 'BookApi', COL[1], R[5], ['(book-service, port 8082)'], ['+ search(keyword, {category})', '+ reviews(bookId), deleteMyReview(bookId)', '+ saveMyReview(bookId, rating, text)', '+ add(book) : Future<Book>', '+ update(book, {copiesBefore}) : Future<Book>'], F.GREEN),
 F.cls('exc', 'ApiException', COL[0], R[6], ['+ message : String', '+ status : int  (0 = not answering)'], None, F.GREEN),
 F.cls('api', 'ApiClient', COL[1], R[6], ['+ baseUrl : String', '+ session : Session', '+ serviceName : String', '+ timeout : Duration  (8 s)'], ['+ get(path) : Future<dynamic>', '+ post(path, body)', '+ put(path, body)', '+ patch(path, body)'], F.GREEN),
 F.cls('sess', 'Session', COL[2], R[6], ['- token : String?', '+ userId, username, email, role', '+ endedMessage : String?'], ['+ isLoggedIn : bool', '+ start(...), clear({message})'], F.GREY, 'ChangeNotifier'),
 F.cls('book', 'Book', COL[3], R[6], ['+ id, title, author : String', '+ price : double', '+ copiesAvailable : int', '+ coverUrl : String?', '+ category : String?', '+ ratingAverage : double?', '+ ratingCount : int', '(categories: the 5 shelves)'], ['+ fromJson, toJson', '+ rentPrice : double  (in cents)'], F.YELLOW),
 F.cls('order', 'Order', COL[4], R[6], ['+ id : int', '+ username, email : String', '+ createdAt : DateTime', '+ paymentStatus : PENDING / PAID', '+ items : List<PlacedItem>', '+ total : double', '+ emailQueued : bool'], ['+ fromJson(json)', '+ copyWith(paymentStatus)'], F.YELLOW),
 F.cls('stars', 'RatingStars', COL[2], R[5], ['+ average : double?', '+ count : int', '+ compact : bool  (for cards)'], [B, '(filled / half / outlined stars in', ' the text color; read out as a sentence)'], F.BLUE, 'widget'),
 F.cls('picker', 'StarPicker', COL[3], R[5], ['+ value : int?', '+ onChanged : ValueChanged<int>'], [B, '(five buttons: Tab, Enter or Space;', ' each says 1 star ... 5 stars)'], F.BLUE, 'widget'),
 F.cls('review', 'Review', COL[2], R[7], ['+ id, bookId, username : String', '+ rating : int', '+ text : String', '+ createdAt, updatedAt'], ['+ fromJson(json)'], F.YELLOW),
 F.cls('type', 'ItemType', COL[3], R[7], ['buy (BUY)', 'rent (RENT)'], None, F.YELLOW, 'enumeration'),
 F.cls('placed', 'PlacedItem', COL[4], R[7], ['+ title, author : String', '+ type : ItemType', '+ quantity : int', '+ unitPrice : double', '+ dueBack : DateTime?'], ['+ fromJson(json)'], F.YELLOW),
 F.edge('uses', 'theme', 'colors', 'builds from'),
 F.edge('opens', 'button', 'bstyle'),
 F.edge('uses', 'field', 'error', 'shows'),
 F.edge('uses', 'login', 'uapi', 'uses'),
 F.edge('extends', 'uapi', 'api'), F.edge('extends', 'bapi', 'api'),
 F.edge('uses', 'api', 'sess', 'sends token'), F.edge('uses', 'api', 'exc', 'throws'),
 F.edge('has', 'order', 'placed', '1..*'),
 F.note(COL[4], R[2], 170, ['Purple: design tokens (tokens.dart)', 'Blue: reusable widgets', 'Green: talking to the services', 'Grey: functions, the session', 'Yellow: plain data', '', 'Every widget reads its colors from', 'BookstoreColors.of(context), so it follows', 'light and dark mode automatically.', 'BillView draws an Order.']),
]
F.write('class-bookstore-ui', 'Shared UI package classes', c)
print('ui written')
