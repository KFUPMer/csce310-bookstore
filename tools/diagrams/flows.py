"""Sequence and activity diagrams (black and white), plus wireframes."""
import io, sys
from xml.sax.saxutils import escape

out = sys.argv[1]
def A(s): return escape(s, {'"': '&quot;', '\n': '&#10;'})
W = 'fillColor=#ffffff;strokeColor=#333333;'
NOTE = 'shape=note;size=14;whiteSpace=wrap;html=1;align=left;verticalAlign=top;spacingLeft=8;spacingTop=6;fillColor=#ffffff;strokeColor=#999999;fontSize=12;'

class D:
    def __init__(s): s.c = []; s.n = 0
    def nid(s): s.n += 1; return f'c{s.n}'
    def box(s, label, x, y, w, h, style):
        id = s.nid()
        s.c.append(f'<mxCell id="{id}" value="{A(label)}" style="{style}" vertex="1" parent="1"><mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry" /></mxCell>')
        return id
    def edge(s, a, b, label='', style='', pts=None):
        p = ''
        if pts: p = '<Array as="points">' + ''.join(f'<mxPoint x="{x}" y="{y}" />' for x, y in pts) + '</Array>'
        s.c.append(f'<mxCell id="{s.nid()}" value="{A(label)}" style="{style}" edge="1" parent="1" source="{a}" target="{b}"><mxGeometry relative="1" as="geometry">{p}</mxGeometry></mxCell>')
    def line(s, x1, y1, x2, y2, label='', style='endArrow=none;html=1;'):
        s.c.append(f'<mxCell id="{s.nid()}" value="{A(label)}" style="{style}" edge="1" parent="1"><mxGeometry relative="1" as="geometry"><mxPoint x="{x1}" y="{y1}" as="sourcePoint" /><mxPoint x="{x2}" y="{y2}" as="targetPoint" /></mxGeometry></mxCell>')
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

# ------------------------------------------------------------------ sequence
CALL = 'endArrow=block;endFill=1;html=1;rounded=0;fontSize=11;verticalAlign=bottom;'
RET = 'endArrow=open;endSize=8;dashed=1;html=1;rounded=0;fontSize=11;verticalAlign=bottom;'

def seq(name, title, parts, steps, note=None, gap=210):
    """parts: list of labels. steps: ('>', a, b, text) call, ('<', a, b, text) return (a -> b), ('self', a, text), ('alt', text)."""
    d = D()
    X = {p.split('\n')[0]: 100 + i * gap for i, p in enumerate(parts)}
    height = 140
    for st in steps: height += {'self': 70, 'alt': 60}.get(st[0], 50)
    for p in parts:
        x = X[p.split('\n')[0]]
        d.box(p.replace('\n', '<br>'), x - 75, 40, 150, 50, 'rounded=0;whiteSpace=wrap;html=1;fontStyle=1;fontSize=12;' + W)
        d.line(x, 90, x, height, '', 'endArrow=none;dashed=1;html=1;strokeColor=#888888;')
    y = 140; n = 0
    right = max(X.values()) + 75
    for st in steps:
        if st[0] == 'alt':
            d.line(30, y - 10, right, y - 10, '', 'endArrow=none;html=1;strokeColor=#333333;dashed=1;dashPattern=8 4;')
            d.box('<b>' + st[1] + '</b>', 30, y - 6, 420, 22, 'text;html=1;align=left;verticalAlign=middle;fontSize=11;')
            y += 60; continue
        n += 1
        if st[0] == 'self':
            d.box(f'{n}. ' + st[2], X[st[1]] + 12, y - 30, 185, 56, 'rounded=0;whiteSpace=wrap;html=1;fontSize=11;align=left;spacingLeft=6;' + W)
            y += 70; continue
        d.line(X[st[1]], y, X[st[2]], y, f'{n}. ' + st[3], CALL if st[0] == '>' else RET)
        y += 50
    if note: d.box(note, 30, height + 20, 520, 56, NOTE)
    d.save(name, title)

seq('sequence-login', 'Sequence: log in',
    ['User\n(customer or manager)', 'Desktop app\n(Flutter)', 'user-service\n(HttpServer)', 'MySQL'],
    [('>', 'User', 'Desktop app', 'enter username and password, click "Log in"'),
     ('>', 'Desktop app', 'user-service', 'POST /api/auth/login — asynchronous'),
     ('>', 'user-service', 'MySQL', 'find user by username'),
     ('<', 'MySQL', 'user-service', 'user row (password hash, role)'),
     ('self', 'user-service', 'compare the password with the bcrypt hash'),
     ('alt', '[password correct]'),
     ('>', 'user-service', 'MySQL', 'INSERT session (new random token)'),
     ('<', 'user-service', 'Desktop app', '200 OK: token, username, role'),
     ('self', 'Desktop app', 'keep the token in Session;<br>manager app: refuse if role is not MANAGER'),
     ('<', 'Desktop app', 'User', 'open the main screen'),
     ('alt', '[user not found or password wrong]'),
     ('<', 'user-service', 'Desktop app', '401 Unauthorized'),
     ('<', 'Desktop app', 'User', 'show "Wrong username or password"')],
    'Covers FR1, FR2, FR11, N2, N3. The same flow is used by both apps; only the screen opened at the end differs.', gap=260)

seq('sequence-register', 'Sequence: register',
    ['Customer', 'Customer app\n(Flutter)', 'user-service\n(HttpServer)', 'MySQL'],
    [('>', 'Customer', 'Customer app', 'fill in username, email, password; click "Create account"'),
     ('self', 'Customer app', 'check the fields are filled in<br>and the email looks valid'),
     ('>', 'Customer app', 'user-service', 'POST /api/users/register — asynchronous'),
     ('>', 'user-service', 'MySQL', 'is the username or email already used?'),
     ('<', 'MySQL', 'user-service', 'result'),
     ('alt', '[username and email are free]'),
     ('self', 'user-service', 'hash the password with bcrypt'),
     ('>', 'user-service', 'MySQL', 'INSERT user (role CUSTOMER)'),
     ('<', 'user-service', 'Customer app', '201 Created'),
     ('<', 'Customer app', 'Customer', 'show "Account created", go to log in'),
     ('alt', '[username or email already used]'),
     ('<', 'user-service', 'Customer app', '409 Conflict'),
     ('<', 'Customer app', 'Customer', 'show "Username or email already in use"')],
    'Covers FR3 and N3 (extra credit). New accounts are always customers; managers are created by the seed script.', gap=260)

seq('sequence-place-order', 'Sequence: place an order',
    ['Customer', 'Customer app\n(Flutter)', 'order-service\n(Flask)', 'user-service\n(HttpServer)', 'book-service\n(Flask)', 'MySQL', 'bills/ folder', 'Mail server'],
    [('>', 'Customer', 'Customer app', 'click "Place order"'),
     ('>', 'Customer app', 'order-service', 'POST /api/orders (token, items) — asynchronous'),
     ('>', 'order-service', 'user-service', 'GET /api/auth/session (token)'),
     ('<', 'user-service', 'order-service', 'valid, role = CUSTOMER, email'),
     ('>', 'order-service', 'book-service', 'PATCH /api/books/{id}/copies (take the copies, for each book)'),
     ('<', 'book-service', 'order-service', 'title, author, price'),
     ('self', 'order-service', 'calculate charges: buy = price,<br>rent = 10% of price, due in 7 days'),
     ('>', 'order-service', 'MySQL', 'INSERT order + items (payment status PENDING)'),
     ('<', 'MySQL', 'order-service', 'order id'),
     ('>', 'order-service', 'bills/ folder', 'write bill-&lt;orderId&gt;.html'),
     ('<', 'order-service', 'Customer app', '201 Created: order + bill'),
     ('<', 'Customer app', 'Customer', 'show the bill'),
     ('>', 'order-service', 'Mail server', 'afterwards, in the background: send the bill to the customer email')],
    'Covers FR6–FR10. If a book does not exist or has no copies left (step 6: 404 or 409), or the order cannot be saved, the copies already taken are given back and nothing is saved.', gap=200)

seq('sequence-update-payment', 'Sequence: manager updates payment status',
    ['Manager', 'Manager app\n(Flutter)', 'order-service\n(Flask)', 'user-service\n(HttpServer)', 'MySQL'],
    [('>', 'Manager', 'Manager app', 'open the Orders tab'),
     ('>', 'Manager app', 'order-service', 'GET /api/orders — asynchronous'),
     ('>', 'order-service', 'user-service', 'GET /api/auth/session (token)'),
     ('<', 'user-service', 'order-service', 'valid, role = MANAGER'),
     ('>', 'order-service', 'MySQL', 'SELECT all orders'),
     ('<', 'order-service', 'Manager app', '200 OK: list of orders'),
     ('>', 'Manager', 'Manager app', 'select an order, click "Mark as paid"'),
     ('>', 'Manager app', 'order-service', 'PATCH /api/orders/{id}/payment-status {PAID}'),
     ('>', 'order-service', 'MySQL', 'UPDATE order SET payment_status = PAID'),
     ('<', 'order-service', 'Manager app', '200 OK: updated order'),
     ('<', 'Manager app', 'Manager', 'the row now shows "Paid"')],
    'Covers FR12, FR13, N5. A customer token gets 403 Forbidden at step 4. The session check is repeated for the PATCH (not drawn twice).', gap=240)

# ------------------------------------------------------------------ activity
ACT = 'rounded=1;arcSize=40;whiteSpace=wrap;html=1;fontSize=12;' + W
DEC = 'rhombus;whiteSpace=wrap;html=1;fontSize=12;' + W
FLOW = 'endArrow=block;endFill=1;html=1;rounded=0;edgeStyle=orthogonalEdgeStyle;fontSize=11;'
START = 'ellipse;html=1;fillColor=#000000;strokeColor=#000000;'
END = 'ellipse;html=1;shape=endState;fillColor=#000000;strokeColor=#000000;'
R2L = FLOW + 'exitX=1;exitY=0.5;entryX=0;entryY=0.5;'
BACK = FLOW + 'exitX=0.5;exitY=0;entryX=1;entryY=0.5;'

d = D()
s = d.box('', 385, 20, 30, 30, START)
a0 = d.box('Open the app (login screen)', 300, 80, 200, 44, ACT)
d0 = d.box('Has an account?', 300, 160, 200, 70, DEC)
r1 = d.box('Fill in username, email and password', 20, 173, 200, 44, ACT)
r2 = d.box('Details valid?', 20, 270, 200, 70, DEC)
r3 = d.box('Create account (password hashed)', 20, 390, 200, 44, ACT)
a1 = d.box('Enter username and password', 300, 480, 200, 44, ACT)
d1 = d.box('Login correct?', 300, 560, 200, 70, DEC)
e1 = d.box('Show "Wrong username or password"', 640, 573, 200, 44, ACT)
d2 = d.box('Role allowed in this app?', 300, 670, 200, 70, DEC)
e2 = d.box('Show "Access denied"', 640, 683, 200, 44, ACT)
a2 = d.box('Create session, keep the token', 300, 780, 200, 44, ACT)
a3 = d.box('Open the main screen', 300, 860, 200, 44, ACT)
e = d.box('', 385, 940, 30, 30, END)
d.edge(s, a0, '', FLOW); d.edge(a0, d0, '', FLOW)
d.edge(d0, r1, 'no', FLOW + 'exitX=0;exitY=0.5;entryX=1;entryY=0.5;')
d.edge(r1, r2, '', FLOW)
d.edge(r2, r1, 'no: show error', FLOW + 'exitX=0;exitY=0.5;entryX=0;entryY=0.5;', [(-20, 305), (-20, 195)])
d.edge(r2, r3, 'yes', FLOW)
d.edge(r3, a1, '', FLOW + 'exitX=1;exitY=0.5;entryX=0;entryY=0.5;')
d.edge(d0, a1, 'yes', FLOW)
d.edge(a1, d1, '', FLOW)
d.edge(d1, e1, 'no', R2L); d.edge(e1, a1, '', BACK)
d.edge(d1, d2, 'yes', FLOW)
d.edge(d2, e2, 'no', R2L); d.edge(e2, a1, '', FLOW + 'exitX=1;exitY=0.5;entryX=1;entryY=0.25;', [(880, 705), (880, 491)])
d.edge(d2, a2, 'yes', FLOW); d.edge(a2, a3, '', FLOW); d.edge(a3, e, '', FLOW)
d.box('Registering exists only in the customer app (FR3).<br>The manager app accepts only the MANAGER role (FR11, N5).', 580, 80, 330, 60, NOTE)
d.save('activity-login', 'Activity: log in and register')

d = D()
s = d.box('', 385, 20, 30, 30, START)
m1 = d.box('Log in to the manager app', 300, 80, 200, 44, ACT)
m2 = d.box('View the list of all orders', 300, 160, 200, 44, ACT)
m3 = d.box('Select an order', 300, 240, 200, 44, ACT)
m4 = d.box('View its bill (optional step)', 300, 320, 200, 44, ACT)
d1 = d.box('Payment received?', 300, 400, 200, 70, DEC)
m5 = d.box('Click "Mark as paid"', 300, 510, 200, 44, ACT)
m6 = d.box('Payment status changes from Pending to Paid', 300, 590, 200, 44, ACT)
d2 = d.box('More orders to handle?', 300, 670, 200, 70, DEC)
m7 = d.box('Log out', 300, 780, 200, 44, ACT)
e = d.box('', 385, 860, 30, 30, END)
n1 = d.box('Leave the order as Pending', 640, 413, 200, 44, ACT)
for a, b, l in ((s, m1, ''), (m1, m2, ''), (m2, m3, ''), (m3, m4, ''), (m4, d1, ''), (d1, m5, 'yes'), (m5, m6, ''), (m6, d2, ''), (d2, m7, 'no'), (m7, e, '')):
    d.edge(a, b, l, FLOW)
d.edge(d1, n1, 'no', R2L)
d.edge(n1, d2, '', FLOW + 'exitX=0.5;exitY=1;entryX=1;entryY=0.5;')
d.edge(d2, m3, 'yes', FLOW + 'exitX=0;exitY=0.5;entryX=0;entryY=0.5;', [(230, 705), (230, 262)])
d.save('activity-manager-payment', 'Activity: manager updates payment status')

# ------------------------------------------------------------------ wireframes
TXT = 'text;html=1;align=left;verticalAlign=middle;fontSize=12;'
class Win:
    def __init__(s, d, x, y, w, h, title, caption):
        s.d, s.x, s.y, s.w = d, x, y, w
        d.box('<b>' + caption + '</b>', x, y - 30, w, 24, 'text;html=1;align=left;verticalAlign=middle;fontSize=13;')
        d.box('', x, y, w, h, 'rounded=0;html=1;fillColor=#ffffff;strokeColor=#333333;')
        d.box('  ' + title, x, y, w, 26, 'rounded=0;html=1;align=left;fontSize=11;fillColor=#e6e6e6;strokeColor=#333333;')
        d.box('—  ☐  ✕', x + w - 70, y, 66, 26, 'text;html=1;align=right;verticalAlign=middle;fontSize=11;')
    def text(s, t, dx, dy, w=300, style=''):
        s.d.box(t, s.x + dx, s.y + dy, w, 22, TXT + style)
    def field(s, label, dx, dy, w=220, value=''):
        s.d.box(label, s.x + dx, s.y + dy, 130, 26, TXT + 'align=right;spacingRight=8;')
        s.d.box(value, s.x + dx + 135, s.y + dy, w, 26, 'rounded=0;html=1;align=left;spacingLeft=6;fontSize=12;fontColor=#555555;fillColor=#ffffff;strokeColor=#666666;')
    def button(s, label, dx, dy, w=110, primary=False):
        s.d.box(label, s.x + dx, s.y + dy, w, 28, 'rounded=1;html=1;fontSize=12;strokeColor=#333333;' + ('fillColor=#d9d9d9;fontStyle=1;' if primary else 'fillColor=#ffffff;'))
    def table(s, dx, dy, cols, rows, sel=None):
        x = s.x + dx
        for name, w in cols:
            s.d.box(name, x, s.y + dy, w, 24, 'rounded=0;html=1;align=left;spacingLeft=6;fontSize=11;fontStyle=1;fillColor=#e6e6e6;strokeColor=#666666;')
            x += w
        for r, row in enumerate(rows):
            x = s.x + dx
            for (name, w), cell in zip(cols, row):
                s.d.box(cell, x, s.y + dy + 24 * (r + 1), w, 24, 'rounded=0;html=1;align=left;spacingLeft=6;fontSize=11;strokeColor=#999999;' + ('fillColor=#eeeeee;' if r == sel else 'fillColor=#ffffff;'))
                x += w

BOOKS = [('Clean Code', 'Robert C. Martin', '$40.00', '4'), ('Database System Concepts', 'Abraham Silberschatz', '$55.00', '2'), ('Java Concurrency in Practice', 'Brian Goetz', '$80.00', '6')]
BC = [('Title', 210), ('Author', 160), ('Price', 70), ('Copies', 60)]

d = D()
w = Win(d, 40, 60, 460, 330, 'Bookstore', '1. Log in')
w.text('<b>Log in</b>', 40, 50, style='fontSize=16;')
w.field('Username', 20, 100); w.field('Password', 20, 140, value='••••••••')
w.button('Log in', 155, 190, primary=True)
w.text('<u>Create an account</u>', 155, 235)
w.text('<i>Error message appears here</i>', 155, 270, style='fontColor=#888888;')

w = Win(d, 560, 60, 460, 330, 'Bookstore', '2. Register (extra credit, FR3)')
w.text('<b>Create an account</b>', 40, 45, style='fontSize=16;')
w.field('Username', 20, 85); w.field('Email', 20, 120); w.field('Password', 20, 155, value='••••••••'); w.field('Confirm password', 20, 190, value='••••••••')
w.button('Create account', 155, 235, 130, primary=True); w.button('Back to log in', 295, 235, 110)
w.text('<i>Error message appears here</i>', 155, 280, style='fontColor=#888888;')

w = Win(d, 1080, 60, 560, 330, 'Bookstore', '3. Search books')
w.text('Logged in as <b>alice</b>', 20, 36, 200); w.button('Log out', 450, 34, 90)
w.field('Keyword', -45, 72, 230, 'java'); w.button('Search', 330, 71, 90, primary=True)
w.text('<i>Searching…</i>', 430, 74, 110, 'fontColor=#888888;')
w.table(20, 112, BC, BOOKS, sel=2)
w.text('Selected: Java Concurrency in Practice', 20, 220, 300)
w.button('Add to order: Buy', 20, 250, 150); w.button('Add to order: Rent', 180, 250, 150)
w.button('View order (3)', 410, 250, 130, primary=True)
w.text('Rent = 10% of the price, for 7 days', 20, 290, 300, 'fontColor=#888888;')

w = Win(d, 40, 480, 640, 330, 'Bookstore', '4. Your order')
w.text('<b>Your order</b>', 20, 36, style='fontSize=16;')
w.table(20, 72, [('Title', 230), ('Type', 90), ('Book price', 90), ('Charge', 80), ('Due back', 110)],
        [('Clean Code', 'Buy ▾', '$40.00', '$40.00', '—'), ('Database System Concepts', 'Buy ▾', '$55.00', '$55.00', '—'), ('Java Concurrency in Practice', 'Rent ▾', '$80.00', '$8.00', '2026-11-20')], sel=2)
w.button('Remove selected', 20, 180, 140)
w.text('<b>Total: $103.00</b>', 470, 182, 150, 'fontSize=14;align=right;')
w.button('Back to search', 340, 270, 130); w.button('Place order', 480, 270, 140, primary=True)

w = Win(d, 740, 480, 560, 330, 'Bookstore', '5. Bill')
w.text('<b>Order #1042 placed</b>', 20, 36, style='fontSize=16;')
d.box('<b>Bill — Order #1042</b><br>Clean Code — Buy — $40.00<br>Database System Concepts — Buy — $55.00<br>Java Concurrency in Practice — Rent — $8.00<br><b>Total due: $103.00</b> &nbsp; Payment: Pending', 760, 550, 520, 120, 'rounded=0;whiteSpace=wrap;html=1;align=left;verticalAlign=top;spacingLeft=10;spacingTop=6;fontSize=12;fillColor=#fafafa;strokeColor=#666666;')
w.text('The bill (HTML) is shown here. A copy was emailed to alice@example.com.', 20, 200, 520, 'fontColor=#888888;')
w.button('New search', 300, 270, 110, primary=True); w.button('Log out', 420, 270, 110)
d.save('wireframes-customer-app', 'Wireframes: customer app')

d = D()
w = Win(d, 40, 60, 460, 330, 'Bookstore — Management', '1. Manager log in')
w.text('<b>Manager log in</b>', 40, 50, style='fontSize=16;')
w.field('Username', 20, 100); w.field('Password', 20, 140, value='••••••••')
w.button('Log in', 155, 190, primary=True)
w.text('<i>"Access denied" if the account is not a manager</i>', 60, 250, 380, 'fontColor=#888888;')

TABS = 'rounded=0;html=1;fontSize=12;strokeColor=#333333;'
def tabs(w, active):
    for i, t in enumerate(('Orders', 'Books')):
        d.box(t, w.x + 20 + i * 100, w.y + 40, 100, 28, TABS + ('fillColor=#ffffff;fontStyle=1;' if t == active else 'fillColor=#e6e6e6;'))
    w.text('Logged in as <b>manager1</b>', w.w - 300, 42, 170, 'align=right;'); w.button('Log out', w.w - 110, 40, 90)

w = Win(d, 560, 60, 700, 330, 'Bookstore — Management', '2. Orders tab')
tabs(w, 'Orders')
w.table(20, 86, [('Order ID', 80), ('Customer', 120), ('Date', 150), ('Total', 100), ('Payment status', 150)],
        [('1042', 'alice', '2026-11-13 10:05', '$103.00', 'Pending'), ('1041', 'omar', '2026-11-12 18:40', '$55.00', 'Paid'), ('1040', 'alice', '2026-11-12 09:15', '$4.00', 'Paid')], sel=0)
w.button('Refresh', 20, 280, 100); w.button('View bill', 430, 280, 110); w.button('Mark as paid', 550, 280, 130, primary=True)
w.text('Selected: order 1042', 20, 200, 300)

w = Win(d, 40, 480, 700, 330, 'Bookstore — Management', '3. Books tab')
tabs(w, 'Books')
w.field('Keyword', -45, 84, 230); w.button('Search', 330, 83, 90, primary=True)
w.table(20, 124, BC, BOOKS, sel=0)
w.button('Add book', 430, 280, 110); w.button('Edit selected', 550, 280, 130, primary=True)

w = Win(d, 800, 480, 460, 330, 'Book', '4. Add / edit book dialog')
w.text('<b>Edit book</b>', 40, 45, style='fontSize=16;')
w.field('Title', 20, 85, value='Clean Code'); w.field('Author', 20, 120, value='Robert C. Martin'); w.field('Price', 20, 155, 100, '40.00'); w.field('Copies available', 20, 190, 100, '4')
w.button('Save', 155, 245, 100, primary=True); w.button('Cancel', 265, 245, 100)
d.save('wireframes-manager-app', 'Wireframes: manager app')
print('written')
