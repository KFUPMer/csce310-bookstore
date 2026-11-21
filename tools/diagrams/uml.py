import io, sys
from xml.sax.saxutils import escape

out = sys.argv[1]
BLUE = ('#dae8fc', '#6c8ebf'); GREEN = ('#d5e8d4', '#82b366')
YELLOW = ('#fff2cc', '#d6b656'); GREY = ('#f5f5f5', '#666666'); RED = ('#f8cecc', '#b85450')
WHITE = ('#ffffff', '#666666')

def A(s): return escape(s, {'"': '&quot;', '\n': '&#10;'})
def fill(c): return f'fillColor={c[0]};strokeColor={c[1]};'

DASH = 'endArrow=open;endSize=10;dashed=1;html=1;rounded=0;fontSize=11;'
SOLID = 'endArrow=open;endSize=10;html=1;rounded=0;fontSize=11;'
LINE = 'endArrow=none;html=1;rounded=0;fontSize=11;'
FLOW = 'endArrow=block;endFill=1;html=1;rounded=0;edgeStyle=orthogonalEdgeStyle;fontSize=11;'
TEXT = 'text;html=1;align=left;verticalAlign=middle;fontSize=12;'
TITLE = 'text;html=1;align=left;verticalAlign=middle;fontSize=14;fontStyle=1;'
NOTE = 'shape=note;size=14;whiteSpace=wrap;html=1;align=left;verticalAlign=top;spacingLeft=8;spacingTop=6;fillColor=#ffffff;strokeColor=#999999;fontSize=12;'

class D:
    def __init__(s): s.c = []; s.n = 0
    def nid(s): s.n += 1; return f'c{s.n}'
    def box(s, label, x, y, w, h, style, id=None):
        id = id or s.nid()
        s.c.append(f'<mxCell id="{id}" value="{A(label)}" style="{style}" vertex="1" parent="1"><mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry" /></mxCell>')
        return id
    def edge(s, a, b, label='', style=SOLID, pts=None):
        p = ''
        if pts: p = '<Array as="points">' + ''.join(f'<mxPoint x="{x}" y="{y}" />' for x, y in pts) + '</Array>'
        s.c.append(f'<mxCell id="{s.nid()}" value="{A(label)}" style="{style}" edge="1" parent="1" source="{a}" target="{b}"><mxGeometry relative="1" as="geometry">{p}</mxGeometry></mxCell>')
    def line(s, x1, y1, x2, y2, label='', style=LINE):
        s.c.append(f'<mxCell id="{s.nid()}" value="{A(label)}" style="{style}" edge="1" parent="1"><mxGeometry relative="1" as="geometry"><mxPoint x="{x1}" y="{y1}" as="sourcePoint" /><mxPoint x="{x2}" y="{y2}" as="targetPoint" /></mxGeometry></mxCell>')
    def cls(s, id, name, x, y, fields, methods, color, w=260, stereo=None):
        start = 40 if stereo else 26
        title = ('<<%s>>\n%s' % (stereo, name)) if stereo else name
        body = 'text;strokeColor=none;fillColor=none;align=left;verticalAlign=top;spacingLeft=6;spacingRight=4;spacingTop=2;overflow=hidden;rotatable=0;fontSize=12;'
        fh = max(len(fields), 1) * 16 + 10
        parts = [f'<mxCell id="{id}_f" value="{A(chr(10).join(fields))}" style="{body}" vertex="1" parent="{id}"><mxGeometry y="{start}" width="{w}" height="{fh}" as="geometry" /></mxCell>']
        total = start + fh
        if methods is not None:
            mh = max(len(methods), 1) * 16 + 10
            parts.append(f'<mxCell id="{id}_l" value="" style="line;strokeWidth=1;fillColor=none;align=left;verticalAlign=middle;spacingTop=-1;spacingLeft=3;spacingRight=3;rotatable=0;labelPosition=right;points=[];portConstraint=eastwest;strokeColor=inherit;" vertex="1" parent="{id}"><mxGeometry y="{total}" width="{w}" height="8" as="geometry" /></mxCell>')
            parts.append(f'<mxCell id="{id}_m" value="{A(chr(10).join(methods))}" style="{body}" vertex="1" parent="{id}"><mxGeometry y="{total + 8}" width="{w}" height="{mh}" as="geometry" /></mxCell>')
            total += 8 + mh
        s.c.append(f'<mxCell id="{id}" value="{A(title)}" style="swimlane;fontStyle=1;align=center;verticalAlign=top;childLayout=stackLayout;horizontal=1;startSize={start};horizontalStack=0;resizeParent=1;resizeParentMax=0;collapsible=0;marginBottom=0;{fill(color)}fontSize=13;" vertex="1" parent="1"><mxGeometry x="{x}" y="{y}" width="{w}" height="{total}" as="geometry" /></mxCell>' + ''.join(parts))
        return id
    def save(s, name, title):
        xml = f'''<mxfile host="app.diagrams.net">
  <diagram id="{name}" name="{A(title)}">
    <mxGraphModel dx="1400" dy="900" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" pageWidth="1600" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        {(chr(10) + '        ').join(s.c)}
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
'''
        io.open(f'{out}/{name}.drawio', 'w', encoding='utf-8', newline='\n').write(xml)

# =============================================================== use case
d = D()
d.box('Online Bookstore', 200, 30, 720, 660, 'rounded=0;whiteSpace=wrap;html=1;verticalAlign=top;fontStyle=1;fontSize=14;fillColor=none;strokeColor=#666666;')
ACTOR = 'shape=umlActor;verticalLabelPosition=top;verticalAlign=bottom;html=1;fontSize=13;fontStyle=1;'
cust = d.box('Customer', 60, 280, 30, 60, ACTOR)
mgr = d.box('Manager', 1030, 280, 30, 60, ACTOR)
UC = 'ellipse;whiteSpace=wrap;html=1;fontSize=12;'
def uc(label, col, y, color=BLUE):
    return d.box(label, {0: 240, 1: 470, 2: 700}[col], y, 180, 50, UC + fill(color))
login = uc('Log in', 1, 70, GREY); logout = uc('Log out', 1, 150, GREY); search = uc('Search books by keyword', 1, 230, GREY)
savebill = uc('Save bill as HTML file', 1, 330, WHITE); gen = uc('Generate bill', 1, 420, WHITE); email = uc('Email bill to customer', 1, 510, WHITE)
mail = d.box('Mail server (Gmail)', 545, 730, 30, 60, ACTOR.replace('verticalLabelPosition=top;verticalAlign=bottom;', 'verticalLabelPosition=bottom;verticalAlign=top;'))
d.edge(mail, email, '', LINE)
select = uc('Select books', 0, 330); place = uc('Place order (buy and/or rent)', 0, 420); view = uc('View bill', 0, 510); reg = uc('Register', 0, 600)
orders = uc('View all orders', 2, 330, GREEN); pay = uc('Update payment status', 2, 420, GREEN); add = uc('Add book', 2, 510, GREEN); upd = uc('Update book information', 2, 600, GREEN)
for u in (login, logout, search): d.edge(cust, u, '', LINE)
for u in (select, place, view, reg): d.edge(cust, u, '', LINE + 'entryX=0;entryY=0.5;')
for u in (login, logout, search): d.edge(mgr, u, '', LINE)
for u in (orders, pay, add, upd): d.edge(mgr, u, '', LINE + 'entryX=1;entryY=0.5;')
d.edge(place, gen, '«include»', DASH)
d.edge(gen, savebill, '«include»', DASH)
d.edge(gen, email, '«include»', DASH)
d.save('use-case', 'Use case')

# =============================================================== activity
d = D()
ACT = 'rounded=1;arcSize=40;whiteSpace=wrap;html=1;fontSize=12;' + fill(BLUE)
DEC = 'rhombus;whiteSpace=wrap;html=1;fontSize=12;' + fill(YELLOW)
start = d.box('', 385, 20, 30, 30, 'ellipse;html=1;fillColor=#000000;strokeColor=#000000;')
a_login = d.box('Log in with username and password', 300, 80, 200, 44, ACT)
d1 = d.box('Login valid?', 300, 160, 200, 70, DEC)
a_err = d.box('Show error message', 640, 173, 200, 44, ACT)
a_search = d.box('Search books by keyword', 300, 270, 200, 44, ACT)
a_select = d.box('Select a book and choose buy or rent', 300, 350, 200, 44, ACT)
d2 = d.box('Add more books?', 300, 430, 200, 70, DEC)
a_place = d.box('Place order', 300, 540, 200, 44, ACT)
d3 = d.box('Copies available?', 300, 620, 200, 70, DEC)
a_na = d.box('Show "not available" message', 640, 633, 200, 44, ACT)
a_save = d.box('Save order with status Pending', 300, 730, 200, 44, ACT.replace(fill(BLUE), fill(GREEN)))
a_gen = d.box('Generate bill (order ID, items, prices, total)', 300, 810, 200, 44, ACT.replace(fill(BLUE), fill(GREEN)))
a_html = d.box('Save bill as HTML file', 300, 890, 200, 44, ACT.replace(fill(BLUE), fill(GREEN)))
a_show = d.box('Show bill to the customer', 300, 970, 200, 44, ACT)
end = d.box('', 385, 1050, 30, 30, 'ellipse;html=1;shape=endState;fillColor=#000000;strokeColor=#000000;')
d.edge(start, a_login, '', FLOW); d.edge(a_login, d1, '', FLOW)
d.edge(d1, a_err, 'no', FLOW + 'exitX=1;exitY=0.5;entryX=0;entryY=0.5;')
d.edge(a_err, a_login, '', FLOW + 'exitX=0.5;exitY=0;entryX=1;entryY=0.5;')
d.edge(d1, a_search, 'yes', FLOW); d.edge(a_search, a_select, '', FLOW); d.edge(a_select, d2, '', FLOW)
d.edge(d2, a_search, 'yes', FLOW + 'exitX=0;exitY=0.5;entryX=0;entryY=0.5;', [(230, 465), (230, 292)])
d.edge(d2, a_place, 'no', FLOW); d.edge(a_place, d3, '', FLOW)
d.edge(d3, a_na, 'no', FLOW + 'exitX=1;exitY=0.5;entryX=0;entryY=0.5;')
d.edge(a_na, a_select, '', FLOW + 'exitX=0.5;exitY=0;entryX=1;entryY=0.5;')
d.edge(d3, a_save, 'yes', FLOW); d.edge(a_save, a_gen, '', FLOW); d.edge(a_gen, a_html, '', FLOW); d.edge(a_html, a_show, '', FLOW); d.edge(a_show, end, '', FLOW)
d.box('Blue: done in the customer app<br>Green: done by order-service', 640, 760, 220, 50, NOTE)
d.save('activity-place-order', 'Activity: customer places an order')

# =============================================================== state machine
d = D()
ST = 'rounded=1;arcSize=30;whiteSpace=wrap;html=1;fontSize=12;'
INIT = 'ellipse;html=1;fillColor=#000000;strokeColor=#000000;'
FINAL = 'ellipse;html=1;shape=endState;fillColor=#000000;strokeColor=#000000;'
d.box('Order', 40, 20, 200, 30, TITLE)
s0 = d.box('', 40, 95, 30, 30, INIT)
s1 = d.box('<b>Being selected</b><br><i>do: add / remove books,<br>choose buy or rent</i>', 150, 70, 220, 80, ST + fill(BLUE))
s2 = d.box('<b>Pending</b><br><i>bill saved as HTML,<br>waiting for payment</i>', 640, 70, 220, 80, ST + fill(YELLOW))
s3 = d.box('<b>Paid</b>', 1130, 70, 220, 80, ST + fill(GREEN))
s4 = d.box('', 1440, 95, 30, 30, FINAL)
d.edge(s0, s1, '', SOLID)
d.edge(s1, s2, 'customer places order<br>/ save order, generate bill', SOLID)
d.edge(s2, s3, 'manager marks it paid,<br>or the customer pays (demo checkout)', SOLID)
d.edge(s3, s4, '', SOLID)
d.box('User session', 40, 240, 200, 30, TITLE)
t0 = d.box('', 40, 315, 30, 30, INIT)
t1 = d.box('<b>Logged out</b>', 150, 290, 220, 80, ST + fill(GREY))
t2 = d.box('<b>Logged in</b><br><i>do: send session token<br>with every request</i>', 640, 290, 220, 80, ST + fill(GREEN))
d.edge(t0, t1, '', SOLID)
d.edge(t1, t2, 'login [username and password valid]<br>/ create session token', SOLID + 'exitX=1;exitY=0.25;entryX=0;entryY=0.25;')
d.edge(t2, t1, 'logout / delete session', SOLID + 'exitX=0;exitY=0.75;entryX=1;entryY=0.75;')
d.box('login [not valid] / show error: the user stays Logged out.', 150, 400, 340, 40, NOTE)
d.save('state-machine', 'State machines')

# =============================================================== component
d = D()
COMP = 'shape=component;align=center;whiteSpace=wrap;html=1;spacingLeft=20;fontSize=12;'
capp = d.box('«component»<br><b>customer-app</b><br>Flutter', 40, 140, 200, 80, COMP + fill(BLUE))
mapp = d.box('«component»<br><b>management-app</b><br>Flutter', 40, 380, 200, 80, COMP + fill(BLUE))
svc = {}; ifc = {}
for name, tech, yy, api in (('user-service', 'Java HttpServer', 70, 'User API :8081'), ('order-service', 'Python Flask', 260, 'Order API :8083'), ('book-service', 'Python Flask', 450, 'Book API :8082')):
    svc[name] = d.box(f'«component»<br><b>{name}</b><br>{tech}', 480, yy, 220, 80, COMP + fill(GREEN))
    ifc[name] = d.box(api, 390, yy + 30, 20, 20, 'ellipse;html=1;fillColor=#ffffff;strokeColor=#000000;verticalLabelPosition=top;verticalAlign=bottom;fontSize=11;')
    d.edge(ifc[name], svc[name], '', LINE)
    d.edge(capp, ifc[name], '', DASH); d.edge(mapp, ifc[name], '', DASH)
DB = 'shape=cylinder3;whiteSpace=wrap;html=1;boundedLbl=1;size=12;fontSize=12;' + fill(YELLOW)
mysql = d.box('«database»<br><b>MySQL</b>', 900, 140, 140, 90, DB)
bills = d.box('«folder»<br><b>bills/</b> (HTML)', 900, 270, 140, 60, 'shape=folder;tabWidth=50;tabHeight=12;tabPosition=left;whiteSpace=wrap;html=1;fontSize=12;' + fill(RED))
mongo = d.box('«database»<br><b>MongoDB</b>', 900, 445, 140, 90, DB)
d.edge(svc['user-service'], mysql, '', SOLID); d.edge(svc['order-service'], mysql, '', SOLID)
d.edge(svc['order-service'], bills, 'saves bill', SOLID); d.edge(svc['book-service'], mongo, '', SOLID)
d.edge(svc['order-service'], svc['user-service'], 'validate session', DASH)
d.edge(svc['order-service'], svc['book-service'], 'price / copies', DASH)
d.edge(svc['book-service'], svc['user-service'], '', DASH + 'edgeStyle=orthogonalEdgeStyle;exitX=1;exitY=0.75;entryX=1;entryY=0.25;', [(780, 510), (780, 90)])
d.box('Circle: REST interface a service provides.<br>Dashed arrow: uses (HTTP / JSON).<br>Solid arrow: reads and writes data.', 40, 520, 300, 66, NOTE)
d.save('component', 'Component')

# =============================================================== object
d = D()
OBJ = 'rounded=0;whiteSpace=wrap;html=1;align=left;verticalAlign=top;spacingLeft=8;spacingTop=2;fontSize=12;'
def obj(title, attrs, x, y, color, w=250):
    h = 34 + 16 * len(attrs) + 8
    return d.box(f"<b><u>{title}</u></b><hr>" + '<br>'.join(attrs), x, y, w, h, OBJ + fill(color))
sess = obj('s1 : Session', ['token = "9f2c…e1"', 'createdAt = 2026-11-13 10:02'], 40, 60, GREY)
user = obj('alice : User', ['username = "alice"', 'email = "alice@example.com"', 'role = CUSTOMER'], 40, 250, GREY)
order = obj('order1042 : Order', ['id = 1042', 'total = 103.00', 'paymentStatus = PENDING', 'billFile = "bills/bill-1042.html"', 'createdAt = 2026-11-13 10:05'], 380, 235, YELLOW)
rows = [('item1 : OrderItem', ['type = BUY', 'quantity = 1', 'unitPrice = 40.00'], 'b1 : Book', ['title = "Clean Code"', 'author = "Robert Martin"', 'price = 40.00', 'copiesAvailable = 4'], 40),
        ('item2 : OrderItem', ['type = BUY', 'quantity = 1', 'unitPrice = 55.00'], 'b2 : Book', ['title = "Database Systems"', 'author = "Ramez Elmasri"', 'price = 55.00', 'copiesAvailable = 2'], 235),
        ('item3 : OrderItem', ['type = RENT', 'quantity = 1', 'unitPrice = 8.00', 'rentDueDate = 2026-11-20'], 'b3 : Book', ['title = "Java Concurrency"', 'author = "Brian Goetz"', 'price = 80.00', 'copiesAvailable = 6'], 430)]
d.edge(user, sess, '', LINE); d.edge(user, order, 'places', LINE)
for it, ia, bk, ba, yy in rows:
    i = obj(it, ia, 720, yy, BLUE); b = obj(bk, ba, 1060, yy, GREEN)
    d.edge(order, i, '', LINE); d.edge(i, b, '', LINE)
d.box('One moment in time: alice has just placed order 1042.<br>She buys two books and rents one.<br>Rent = 10% of 80.00 = 8.00, due back 7 days later.<br>Total = 40.00 + 55.00 + 8.00 = 103.00', 40, 430, 290, 100, NOTE)
d.save('object', 'Object')

# =============================================================== profile
d = D()
PK = 'shape=folder;fontStyle=1;tabWidth=130;tabHeight=22;tabPosition=left;html=1;whiteSpace=wrap;verticalAlign=top;spacingTop=26;fontSize=13;'
d.box('«profile» Bookstore', 20, 20, 1520, 420, PK.replace('tabWidth=130', 'tabWidth=170') + 'fillColor=none;strokeColor=#666666;')
META = 'rounded=0;whiteSpace=wrap;html=1;fontSize=12;' + fill(GREY)
STE = 'rounded=0;whiteSpace=wrap;html=1;align=left;verticalAlign=top;spacingLeft=6;spacingTop=2;fontSize=12;'
EXT = 'endArrow=block;endFill=1;endSize=10;html=1;rounded=0;edgeStyle=orthogonalEdgeStyle;exitX=0.5;exitY=0;entryX=0.5;entryY=1;'
def ster(name, attrs, x, color):
    return d.box(f"«stereotype»<br><b>{name}</b><hr>" + '<br>'.join(attrs), x, 270, 190, 130, STE + fill(color))
m_comp = d.box('«metaclass»<br><b>Component</b>', 50, 90, 190, 60, META)
m_class = d.box('«metaclass»<br><b>Class</b>', 587, 90, 190, 60, META)
m_op = d.box('«metaclass»<br><b>Operation</b>', 1232, 90, 190, 60, META)
d.edge(ster('RestService', ['port : int', 'technology : String', 'database : String'], 50, GREEN), m_comp, '', EXT)
for name, attrs, x, col in (('FlutterScreen', ['route : String'], 265, BLUE), ('ApiCall', ['service : String', 'async : boolean = true'], 480, GREEN),
                            ('MySqlTable', ['tableName : String'], 695, YELLOW), ('MongoCollection', ['collection : String'], 910, YELLOW)):
    d.edge(ster(name, attrs, x, col), m_class, '', EXT)
for name, attrs, x in (('CustomerOnly', ['role = CUSTOMER'], 1125), ('ManagerOnly', ['role = MANAGER'], 1340)):
    d.edge(ster(name, attrs, x, RED), m_op, '', EXT)
d.save('profile', 'Profile')

# =============================================================== class: services
d = D()
FR = 'rounded=0;whiteSpace=wrap;html=1;verticalAlign=top;align=left;spacingLeft=10;spacingTop=4;fontStyle=1;fontSize=13;dashed=1;fillColor=none;strokeColor=#888888;'
d.box('user-service (Java HttpServer)', 20, 10, 600, 830, FR)
d.box('book-service (Python Flask)', 680, 10, 300, 830, FR)
d.box('order-service (Python Flask)', 1040, 10, 900, 830, FR)
R = [60, 230, 420, 640]
d.cls('us', 'UserServer', 40, R[0], ['- port : int = 8081', '- server : HttpServer'], ['+ main(args) : void', '+ start() : void'], GREY)
d.cls('ah', 'AuthHandler', 40, R[1], ['- auth : AuthService'], ['+ handleLogin(exchange)', '+ handleLogout(exchange)', '+ handleSession(exchange)'], BLUE)
d.cls('uh', 'UserHandler', 340, R[1], ['- auth : AuthService'], ['+ handleRegister(exchange)'], BLUE)
d.cls('as', 'AuthService', 40, R[2], ['- users : UserRepository', '- sessions : SessionRepository', '- hasher : PasswordHasher'], ['+ login(username, password) : Session', '+ logout(token) : void', '+ checkSession(token) : Session', '+ register(username, password, email)'], GREEN)
d.cls('ph', 'PasswordHasher', 340, R[2], ['(bcrypt, N3)'], ['+ hash(password) : String', '+ matches(password, hash) : boolean'], GREEN)
d.cls('ur', 'UserRepository', 40, R[3], ['(MySQL table USERS)'], ['+ findByUsername(username) : User', '+ save(user) : User'], YELLOW)
d.cls('sr', 'SessionRepository', 340, R[3], ['(MySQL table SESSIONS)'], ['+ create(userId) : Session', '+ find(token) : Session', '+ delete(token) : void'], YELLOW)
for a, b in (('us', 'ah'), ('us', 'uh'), ('ah', 'as'), ('uh', 'as'), ('as', 'ph'), ('as', 'ur'), ('as', 'sr')): d.edge(a, b, '', DASH)
d.cls('bsc', 'SessionChecker', 700, R[0], ['- user_service_url : str'], ['+ require_login(request)', '+ require_manager(request)'], GREEN)
d.cls('br', 'BookRoutes', 700, R[1], ['(Flask routes)'], ['GET /api/books?keyword=', 'GET /api/books/<id>', 'POST /api/books', 'PUT /api/books/<id>', 'PATCH /api/books/<id>/copies'], BLUE)
d.cls('bs', 'BookService', 700, R[2], ['- repo : BookRepository'], ['+ search(keyword) : list', '+ get(book_id) : dict', '+ add(data) : dict', '+ update(book_id, data) : dict', '+ change_copies(book_id, change)'], GREEN)
d.cls('brp', 'BookRepository', 700, R[3], ['(MongoDB collection books)'], ['+ find_by_keyword(keyword)', '+ find_by_id(book_id)', '+ insert(book)', '+ update(book_id, fields)'], YELLOW)
for a, b in (('br', 'bsc'), ('br', 'bs'), ('bs', 'brp')): d.edge(a, b, '', DASH)
d.cls('osc', 'SessionChecker', 1060, R[1], ['- user_service_url : str'], ['+ require_customer(request)', '+ require_manager(request)'], GREEN)
d.cls('orr', 'OrderRoutes', 1360, R[1], ['(Flask routes)'], ['POST /api/orders', 'GET /api/orders', 'GET /api/orders/<id>/bill', 'PATCH /api/orders/<id>/payment-status'], BLUE)
d.cls('bc', 'BookClient', 1060, R[2], ['- book_service_url : str'], ['+ get_book(book_id, token) : dict', '+ take_copy(book_id) : None'], GREEN)
d.cls('es', 'EmailSender', 1660, R[1], ['- smtp_host, smtp_port, sender'], ['+ send_bill(to_email, order_id, html)'], RED)
d.cls('os', 'OrderService', 1360, R[2], ['- repo, books, pricing, bills, mail'], ['+ create_order(user, items) : dict', '+ list_orders() : list', '+ set_payment_status(order_id, status)', '+ get_bill(order_id, user) : str'], GREEN)
d.cls('pc', 'PriceCalculator', 1660, R[2], ['RENT_RATE = 0.10', 'RENT_DAYS = 7'], ['+ charge(price, type) : Decimal', '+ due_date(order_date) : date'], GREEN)
d.cls('orp', 'OrderRepository', 1360, R[3], ['(MySQL tables ORDERS, ORDER_ITEMS)'], ['+ insert_order(order, items) : int', '+ find_all() : list', '+ find_by_id(order_id) : dict', '+ update_status(order_id, status)'], YELLOW)
d.cls('bg', 'BillGenerator', 1660, R[3], ['- bills_dir : str = "bills/"'], ['+ render_html(order) : str', '+ save(order_id, html) : str'], RED)
for a, b in (('orr', 'osc'), ('orr', 'os'), ('os', 'bc'), ('os', 'pc'), ('os', 'orp'), ('os', 'bg'), ('os', 'es')): d.edge(a, b, '', DASH)
d.box('Blue: receives HTTP requests. Green: logic. Yellow: database access. Red: writes or emails the bill.<br>The two Python services are modules; they are drawn as classes to show what each one is responsible for.', 1060, 60, 560, 70, NOTE)
d.save('class-services', 'Class diagram: backend services')
print('written')
