"""Class diagram of book-service: every class and module in services/book-service/book_service."""
import sys
from xml.sax.saxutils import escape

import flutter_cls as F  # shared drawing helpers (also rewrites the two app diagrams, unchanged)

C = [40, 390, 740, 1090, 1440, 1810]
R = [40, 270, 540, 820, 1080, 1340]
RED = ('#f8cecc', '#b85450'); PURPLE = ('#e1d5e7', '#9673a6')
n = [0]
def E(a, b, label='', style=''):
    n[0] += 1
    return f'<mxCell id="x{n[0]}" value="{escape(label)}" style="html=1;rounded=0;fontSize=11;{style}" edge="1" parent="1" source="{a}" target="{b}"><mxGeometry relative="1" as="geometry" /></mxCell>'
USES = 'endArrow=open;endSize=10;dashed=1;'
IMPL = 'endArrow=block;endFill=0;endSize=12;dashed=1;'
SIDE = 'endArrow=block;endFill=0;endSize=12;edgeStyle=orthogonalEdgeStyle;exitX=1;exitY=0.5;entryX=1;entryY=0.5;'

c = [
 # start-up and settings
 F.cls('main', '__main__.py', C[0], R[0], ['listens on 127.0.0.1 and ::1', 'port 8082 (waitress)'], ['main() : None'], F.GREY, 'module'),
 F.cls('app', 'app.py', C[1], R[0], ['MAX_BODY_BYTES = 16 KB'], ['create_app(books, reviews, sessions,', '    service_key, clock)', 'create_production_app(config)'], F.BLUE, 'module'),
 F.cls('config', 'Config', C[2], R[0], ['+ port : int', '+ mongo_url, mongo_database : str', '+ user_service_url : str', '+ service_key : str'], ['+ load() : Config'], F.GREY, 'dataclass'),
 F.cls('errh', 'errors.py', C[3], R[0], ['one error shape for every failure'], ['register_error_handlers(app)'], RED, 'module'),
 F.cls('change', 'CopiesChange', C[4], R[0], ['+ change : int'], ['+ from_json(body) : CopiesChange'], PURPLE, 'dataclass'),
 # http and the shapes of requests
 F.cls('checker', 'SessionChecker', C[0], R[1], ['(abstract)'], ['+ check(token) : CurrentUser'], F.GREEN, 'interface'),
 F.cls('routes', 'routes.py', C[1], R[1], ['create_routes(books, reviews, sessions, key)'], ['GET /api/books?keyword=&category=', 'GET /api/books/<id>', 'POST /api/books  (manager)', 'PUT /api/books/<id>  (manager)', 'PATCH /api/books/<id>/copies  (services)', 'GET /api/books/<id>/reviews', 'PUT /api/books/<id>/reviews/mine  (customer)', 'DELETE .../reviews/mine  (customer)'], F.BLUE, 'module'),
 F.cls('authf', 'auth.py', C[2], R[1], ['TIMEOUT = (2 s, 3 s)'], ['token_from(header) : str', 'require_manager(user)', 'require_customer(user)', 'require_service_key(given, expected)'], F.GREEN, 'module'),
 F.cls('input', 'BookInput', C[3], R[1], ['+ title, author : str', '+ price : float', '+ copies_available : int', '+ cover_url : str | None', '+ category : str  (one of 5)', '+ copies_before : int | None  (PUT)'], ['+ from_json(body) : BookInput', 'category_filter(value)  (module)'], PURPLE, 'dataclass'),
 F.cls('rinput', 'ReviewInput', C[4], R[1], ['+ rating : int  (1 to 5)', '+ text : str  (trimmed, at most 1000)'], ['+ from_json(body) : ReviewInput'], PURPLE, 'dataclass'),
 # the rules
 F.cls('realchecker', 'UserServiceSessionChecker', C[0], R[2], ['- url : str', '- http : requests.Session'], ['+ check(token) : CurrentUser', '(asks user-service; 503 if it is down)'], F.GREEN),
 F.cls('service', 'BookService', C[1], R[2], ['- books : BookRepository', '- reviews : ReviewRepository'], ['+ search(keyword, category) : list[Book]', '+ get(book_id) : Book', '+ add(book) : Book', '+ update(book_id, book) : Book', '+ change_copies(book_id, change) : Book', "(fills in each book's rating)"], F.GREEN),
 F.cls('rservice', 'ReviewService', C[2], R[2], ['- books, reviews, clock'], ['+ list_for_book(book_id)', '+ save_mine(book_id, user, review)', '+ delete_mine(book_id, user)', 'average_rating(totals)  (module)'], F.GREEN),
 F.cls('book', 'Book', C[3], R[2], ['+ id : str', '+ title, author : str', '+ price : float', '+ copies_available : int', '+ cover_url : str | None', '+ category : str | None', '+ rating_average : float | None', '+ rating_count : int', '(CATEGORIES: the 5 shelves)'], ['+ to_json() : dict'], F.GREY, 'dataclass'),
 F.cls('review', 'Review', C[4], R[2], ['+ id, book_id : str', '+ user_id : int', '+ username : str', '+ rating : int', '+ text : str', '+ created_at, updated_at'], ['+ to_json() : dict  (no user id)'], F.GREY, 'dataclass'),
 # storage, and plain data the rules use
 F.cls('repo', 'BookRepository', C[1], R[3], ['(abstract)'], ['+ search(keyword, category) : list[Book]', '+ find(book_id) : Book | None', '+ insert(book) : Book', '+ replace(book_id, book) : Book | None', '+ change_copies(book_id, change)'], F.YELLOW, 'interface'),
 F.cls('rrepo', 'ReviewRepository', C[2], R[3], ['(abstract)'], ['+ list_for_book(book_id)', '+ save(...)  (create or replace)', '+ delete(book_id, user_id) : bool', '+ rating_totals(book_ids)'], F.YELLOW, 'interface'),
 F.cls('totals', 'RatingTotals', C[3], R[3] + 40, ['+ stars : int', '+ count : int'], None, F.GREY, 'dataclass'),
 F.cls('cuser', 'CurrentUser', C[4], R[3] + 40, ['+ user_id : int', '+ username, email, role : str'], ['+ is_manager : bool'], F.GREY, 'dataclass'),
 F.cls('mongo', 'MongoBookRepository', C[0], R[4], ['- books : Collection'], ['(MongoDB collection books)', '- object_id(book_id)', '- to_document(book)', '- to_book(doc)'], F.YELLOW),
 F.cls('mem', 'InMemoryBookRepository', C[1], R[4] + 60, ['- books : dict[str, Book]', '- next_id : int'], ['(tests only)'], F.YELLOW),
 F.cls('rmongo', 'MongoReviewRepository', C[2], R[4] + 60, ['- reviews : Collection'], ['(MongoDB collection reviews; unique', ' index on bookId + userId)', '+ ensure_indexes()', '(ratings: one aggregation)'], F.YELLOW),
 F.cls('rmem', 'InMemoryReviewRepository', C[3], R[4] + 60, ['- reviews : dict'], ['(tests only)'], F.YELLOW),
 # errors
 F.cls('apierr', 'ApiError', C[5], R[0], ['+ status : int', '+ message : str'], None, RED),
 F.cls('e400', 'ValidationError', C[5], R[0] + 150, ['status 400'], None, RED),
 F.cls('e401', 'UnauthorizedError', C[5], R[0] + 260, ['status 401'], None, RED),
 F.cls('e403', 'ForbiddenError', C[5], R[0] + 370, ['status 403'], None, RED),
 F.cls('e404', 'NotFoundError', C[5], R[0] + 480, ['status 404'], None, RED),
 F.cls('e409', 'ConflictError', C[5], R[0] + 590, ['status 409'], None, RED),
 F.cls('e503', 'ServiceUnavailableError', C[5], R[0] + 700, ['status 503'], None, RED),

 E('main', 'app', 'builds', USES), E('app', 'config', 'reads', USES), E('app', 'routes', 'registers', USES),
 E('routes', 'checker', 'who is asking', USES), E('routes', 'authf', 'checks', USES), E('routes', 'service', 'calls', USES),
 E('realchecker', 'checker', '', IMPL), E('service', 'repo', '', USES), E('rservice', 'rrepo', '', USES),
 E('mongo', 'repo', '', IMPL), E('mem', 'repo', '', IMPL), E('rmongo', 'rrepo', '', IMPL), E('rmem', 'rrepo', '', IMPL),
] + [E(x, 'apierr', '', SIDE) for x in ('e400', 'e401', 'e403', 'e404', 'e409', 'e503')]
c.append(f'<mxCell id="note1" value="{F.esc(["Colors = layers (a layer only calls the one below it)", "Blue: HTTP. Routes, and app.py, which puts the parts together", "Purple: the shapes of requests, with their validation", "Green: the rules, and the login check against user-service", "Yellow: database access (interfaces, MongoDB and in-memory versions)", "Grey: start-up, settings, plain data", "Red: errors", "", "Python modules that hold functions rather than a class are drawn as <<module>>.", "Not drawn: every layer may raise the red errors; errors.py answers them in one place.", "Not drawn, to keep lines from crossing: routes.py also calls ReviewService;", "BookService reads RatingTotals from ReviewRepository; ReviewService asks", "BookRepository whether the book exists."])}" style="shape=note;size=14;whiteSpace=wrap;align=left;verticalAlign=top;spacingLeft=8;spacingTop=6;fillColor=#ffffff;strokeColor=#999999;fontSize=12;" vertex="1" parent="1"><mxGeometry x="{C[0]}" y="{R[5] + 40}" width="660" height="230" as="geometry" /></mxCell>')
F.write('class-book-service', 'book-service classes', c)
print('book-service diagram written')
