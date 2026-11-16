"""Class diagram of order-service: every class and module in services/order-service/order_service."""
import sys
from xml.sax.saxutils import escape

import flutter_cls as F  # shared drawing helpers (also rewrites the two app diagrams, unchanged)

C = [40, 390, 740, 1090, 1440, 1790, 2160]
R = [40, 300, 560, 900, 1150]
RED = ('#f8cecc', '#b85450'); PURPLE = ('#e1d5e7', '#9673a6')
n = [0]
def E(a, b, label='', style=''):
    n[0] += 1
    return f'<mxCell id="x{n[0]}" value="{escape(label)}" style="html=1;rounded=0;fontSize=11;{style}" edge="1" parent="1" source="{a}" target="{b}"><mxGeometry relative="1" as="geometry" /></mxCell>'
USES = 'endArrow=open;endSize=10;dashed=1;'
DOWN = USES + 'exitX=0.5;exitY=1;entryX=0.5;entryY=0;'  # from the bottom of one box to the top of another
IMPL = 'endArrow=block;endFill=0;endSize=12;dashed=1;'
SIDE = 'endArrow=block;endFill=0;endSize=12;edgeStyle=orthogonalEdgeStyle;exitX=1;exitY=0.5;entryX=1;entryY=0.5;'

c = [
 # start-up, settings, and the data told to us by the other services
 F.cls('main', '__main__.py', C[0], R[0], ['listens on 127.0.0.1 and ::1', 'port 8083 (waitress, 8 threads)'], ['main() : None'], F.GREY, 'module'),
 F.cls('app', 'app.py', C[1], R[0], ['MAX_BODY_BYTES = 16 KB'], ['create_app(orders, catalog, sessions,', '    bills, mailer, clock)', 'create_production_app(config)'], F.BLUE, 'module'),
 F.cls('config', 'Config', C[2], R[0], ['+ port : int', '+ mysql_host, mysql_user, mysql_database', '+ mysql_password  (never printed)', '+ user_service_url, book_service_url', '+ service_key  (never printed)', '+ bills_folder : Path', '+ smtp_host, smtp_port, smtp_user, mail_from', '+ smtp_password  (never printed)'], ['+ load() : Config', '+ email_is_configured : bool'], F.GREY, 'dataclass'),
 F.cls('errh', 'errors.py', C[3], R[0], ['one error shape for every failure'], ['register_error_handlers(app)'], RED, 'module'),
 F.cls('cuser', 'CurrentUser', C[4], R[0], ['+ user_id : int', '+ username, email, role : str'], ['+ is_manager : bool', '+ is_customer : bool'], F.GREY, 'dataclass'),
 F.cls('cbook', 'CatalogBook', C[5], R[0], ['+ id : str', '+ title, author : str', '+ price : Decimal'], None, F.GREY, 'dataclass'),
 # http and the shapes of requests
 F.cls('checker', 'SessionChecker', C[0], R[1], ['(abstract)'], ['+ check(token) : CurrentUser'], F.GREEN, 'interface'),
 F.cls('routes', 'routes.py', C[1], R[1], ['create_routes(orders, sessions)'], ['POST /api/orders  (customer)', 'GET /api/orders  (manager)', 'GET /api/orders/<id>/bill  (owner, manager)', 'PATCH /api/orders/<id>/payment-status'], F.BLUE, 'module'),
 F.cls('authf', 'auth.py', C[2], R[1], ['TIMEOUT = (2 s, 3 s)'], ['token_from(header) : str', 'require_customer(user)', 'require_manager(user)'], F.GREEN, 'module'),
 F.cls('input', 'OrderInput', C[3], R[1], ['+ lines : tuple[OrderLine]', 'MAX_ITEMS = 50'], ['+ from_json(body) : OrderInput'], PURPLE, 'dataclass'),
 F.cls('line', 'OrderLine', C[4], R[1], ['+ book_id : str', '+ type : str', '+ quantity : int'], None, PURPLE, 'dataclass'),
 F.cls('status', 'PaymentStatusInput', C[5], R[1], ['+ payment_status : str'], ['+ from_json(body)'], PURPLE, 'dataclass'),
 # the rules
 F.cls('realchecker', 'UserServiceSessionChecker', C[0], R[2], ['- url : str', '- http : requests.Session'], ['+ check(token) : CurrentUser', '(asks user-service; 503 if it is down)'], F.GREEN),
 F.cls('service', 'OrderService', C[1], R[2], ['- orders, catalog, bills, mailer, clock'], ['+ place(user, order_input) : PlacedOrder', '+ list_all() : list[Order]', '+ bill_for(order_id, user) : str', '+ set_payment_status(order_id, status)'], F.GREEN),
 F.cls('pricing', 'pricing.py', C[2], R[2], ['RENT_RATE = 0.10', 'RENT_DAYS = 7'], ['charge_for(price, type) : Decimal'], F.GREEN, 'module'),
 F.cls('placed', 'PlacedOrder', C[3], R[2], ['+ order : Order', '+ bill_html : str', '+ email_queued : bool'], None, F.GREY, 'dataclass'),
 F.cls('order', 'Order', C[4], R[2], ['+ id : int | None', '+ user_id : int', '+ username, email : str', '+ created_at : datetime', '+ payment_status : str', '+ items : tuple[OrderItem]', '+ total : Decimal', '+ bill_file : str | None'], ['+ to_json() : dict', '+ to_summary_json() : dict'], F.GREY, 'dataclass'),
 F.cls('item', 'OrderItem', C[5], R[2], ['+ book_id, title, author : str', '+ type : str', '+ quantity : int', '+ unit_price : Decimal', '+ rent_due_date : date | None'], ['+ line_total : Decimal', '+ to_json() : dict'], F.GREY, 'dataclass'),
 # what the rules use: other services, the database, files, mail
 F.cls('catalog', 'BookCatalog', C[0], R[3], ['(abstract)'], ['+ take(book_id, quantity) : CatalogBook', '+ give_back(book_id, quantity)'], F.GREEN, 'interface'),
 F.cls('repo', 'OrderRepository', C[1], R[3], ['(abstract)'], ['+ save(order) : Order', '+ find(order_id) : Order | None', '+ list_all() : list[Order]', '+ set_payment_status(order_id, status)', '+ set_bill_file(order_id, bill_file)'], F.YELLOW, 'interface'),
 F.cls('billf', 'bill.py', C[2], R[3], ['the approved bill layout'], ['render_bill(order) : str', 'bill_file_name(order_id) : str', 'money(amount) : str'], F.GREEN, 'module'),
 F.cls('bills', 'BillStore', C[3], R[3], ['- folder : Path'], ['+ write(order_id, bill_html) : str', '+ read(order_id) : str | None'], F.YELLOW),
 F.cls('mailer', 'Mailer', C[4], R[3], ['(abstract)'], ['+ send_bill(order, bill_html) : bool'], F.GREEN, 'interface'),
 F.cls('mailf', 'mailer.py', C[5], R[3], ['TIMEOUT = 15 s'], ['build_message(order, bill_html,', '    mail_from) : EmailMessage'], F.GREEN, 'module'),
 F.cls('realcatalog', 'BookServiceCatalog', C[0], R[4], ['- url : str', '- http : requests.Session'], ['(PATCH /api/books/<id>/copies', ' with the shared service key;', ' 503 if book-service is down)'], F.GREEN),
 F.cls('mysql', 'MySqlOrderRepository', C[1], R[4], ['- pool : MySQLConnectionPool', 'POOL_SIZE = 8'], ['(tables orders, order_items, users)', '- transaction()', '- find(connection, order_id)', 'create_pool(config)'], F.YELLOW),
 F.cls('mem', 'InMemoryOrderRepository', C[2], R[4], ['- orders : dict[int, Order]', '- next_id : int'], ['(tests only)'], F.YELLOW),
 F.cls('smtp', 'SmtpMailer', C[4], R[4], ['- host, port, user, password, mail_from', '- worker : one background thread'], ['+ send_bill(order, bill_html) : bool', '+ close()', '(STARTTLS; a failure is logged)'], F.GREEN),
 F.cls('nomail', 'NoMailer', C[3], R[4], ['(email is not configured)'], ['+ send_bill(...) : False'], F.GREEN),
 # errors
 F.cls('apierr', 'ApiError', C[6], R[0], ['+ status : int', '+ message : str'], None, RED),
 F.cls('e400', 'ValidationError', C[6], R[0] + 150, ['status 400'], None, RED),
 F.cls('e401', 'UnauthorizedError', C[6], R[0] + 260, ['status 401'], None, RED),
 F.cls('e403', 'ForbiddenError', C[6], R[0] + 370, ['status 403'], None, RED),
 F.cls('e404', 'NotFoundError', C[6], R[0] + 480, ['status 404'], None, RED),
 F.cls('e409', 'ConflictError', C[6], R[0] + 590, ['status 409'], None, RED),
 F.cls('e503', 'ServiceUnavailableError', C[6], R[0] + 700, ['status 503'], None, RED),

 E('main', 'app', 'builds', USES), E('app', 'config', 'reads', USES), E('app', 'routes', 'registers', USES),
 E('routes', 'checker', 'who is asking', USES), E('routes', 'authf', 'checks', USES), E('routes', 'service', 'calls', USES),
 E('realchecker', 'checker', '', IMPL), E('service', 'pricing', 'charges', USES),
 E('service', 'catalog', '', DOWN), E('service', 'repo', '', DOWN), E('service', 'billf', '', DOWN), E('service', 'bills', '', DOWN), E('service', 'mailer', '', DOWN),
 E('realcatalog', 'catalog', '', IMPL), E('mysql', 'repo', '', IMPL), E('mem', 'repo', '', IMPL),
 E('smtp', 'mailer', '', IMPL), E('nomail', 'mailer', '', IMPL), E('smtp', 'mailf', '', USES),
] + [E(x, 'apierr', '', SIDE) for x in ('e400', 'e401', 'e403', 'e404', 'e409', 'e503')]
c.append(f'<mxCell id="note1" value="{F.esc(["Colors = layers (a layer only calls the one below it)", "Blue: HTTP. Routes, and app.py, which puts the parts together", "Purple: the shapes of requests, with their validation", "Green: the rules, and what they ask of others: user-service (who is asking),", "    book-service (take copies), the bill layout, the mail server", "Yellow: storage (orders in MySQL or in memory, bill files on disk)", "Grey: start-up, settings, plain data", "Red: errors", "", "Python modules that hold functions rather than a class are drawn as <<module>>.", "Not drawn: every layer may raise the red errors; errors.py answers them in one place.", "Not drawn: bill.py and SmtpMailer read Order; bill.py reads RENT_RATE and RENT_DAYS."])}" style="shape=note;size=14;whiteSpace=wrap;align=left;verticalAlign=top;spacingLeft=8;spacingTop=6;fillColor=#ffffff;strokeColor=#999999;fontSize=12;" vertex="1" parent="1"><mxGeometry x="{C[2]}" y="{R[4] + 190}" width="640" height="220" as="geometry" /></mxCell>')
F.write('class-order-service', 'order-service classes', c)
print('order-service diagram written')
