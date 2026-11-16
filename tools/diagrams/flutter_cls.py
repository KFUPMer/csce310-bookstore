"""Class diagrams of the two Flutter desktop apps."""
import io, sys
from xml.sax.saxutils import escape

out = sys.argv[1]
W = 270
COL = [40, 390, 740, 1090, 1440]
R = [40, 320, 540, 760, 990]
BLUE = ('#dae8fc', '#6c8ebf'); GREEN = ('#d5e8d4', '#82b366')
YELLOW = ('#fff2cc', '#d6b656'); GREY = ('#f5f5f5', '#666666')

def esc(lines): return '&#10;'.join(escape(l, {'"': '&quot;'}) for l in lines)

def cls(id, name, x, y, fields, methods, color, stereo=None):
    fill, stroke = color
    start = 40 if stereo else 26
    title = esc(['<<%s>>' % stereo, name]) if stereo else escape(name)
    body = 'text;strokeColor=none;fillColor=none;align=left;verticalAlign=top;spacingLeft=6;spacingRight=4;spacingTop=2;overflow=hidden;rotatable=0;fontSize=12;'
    fh = max(len(fields), 1) * 16 + 10
    parts = [f'<mxCell id="{id}_f" value="{esc(fields)}" style="{body}" vertex="1" parent="{id}"><mxGeometry y="{start}" width="{W}" height="{fh}" as="geometry" /></mxCell>']
    total = start + fh
    if methods is not None:
        mh = max(len(methods), 1) * 16 + 10
        parts.append(f'<mxCell id="{id}_l" value="" style="line;strokeWidth=1;fillColor=none;align=left;verticalAlign=middle;spacingTop=-1;spacingLeft=3;spacingRight=3;rotatable=0;labelPosition=right;points=[];portConstraint=eastwest;strokeColor=inherit;" vertex="1" parent="{id}"><mxGeometry y="{total}" width="{W}" height="8" as="geometry" /></mxCell>')
        parts.append(f'<mxCell id="{id}_m" value="{esc(methods)}" style="{body}" vertex="1" parent="{id}"><mxGeometry y="{total + 8}" width="{W}" height="{mh}" as="geometry" /></mxCell>')
        total += 8 + mh
    return f'<mxCell id="{id}" value="{title}" style="swimlane;fontStyle=1;align=center;verticalAlign=top;childLayout=stackLayout;horizontal=1;startSize={start};horizontalStack=0;resizeParent=1;resizeParentMax=0;collapsible=0;marginBottom=0;fillColor={fill};strokeColor={stroke};fontSize=13;" vertex="1" parent="1"><mxGeometry x="{x}" y="{y}" width="{W}" height="{total}" as="geometry" /></mxCell>' + ''.join(parts)

STY = {
 'uses': 'endArrow=open;endSize=10;dashed=1;html=1;rounded=0;fontSize=11;',
 'opens': 'endArrow=open;endSize=10;html=1;rounded=0;fontSize=11;',
 'extends': 'endArrow=block;endFill=0;endSize=12;html=1;rounded=0;edgeStyle=orthogonalEdgeStyle;exitX=0.5;exitY=1;entryX=0.5;entryY=0;fontSize=11;',
 'has': 'startArrow=diamond;startFill=1;startSize=14;endArrow=none;html=1;rounded=0;fontSize=11;',
}
_n = [0]
def edge(kind, a, b, label=''):
    _n[0] += 1
    return f'<mxCell id="e{_n[0]}" value="{escape(label)}" style="{STY[kind]}" edge="1" parent="1" source="{a}" target="{b}"><mxGeometry relative="1" as="geometry" /></mxCell>'
def note(x, y, h, text):
    _n[0] += 1
    return f'<mxCell id="n{_n[0]}" value="{esc(text)}" style="shape=note;size=14;whiteSpace=wrap;align=left;verticalAlign=top;spacingLeft=8;spacingTop=6;fillColor=#ffffff;strokeColor=#999999;fontSize=12;" vertex="1" parent="1"><mxGeometry x="{x}" y="{y}" width="{W}" height="{h}" as="geometry" /></mxCell>'
def write(name, title, cells):
    xml = f'''<mxfile host="app.diagrams.net">
  <diagram id="{name}" name="{title}">
    <mxGraphModel dx="1400" dy="900" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" pageWidth="1600" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        {(chr(10) + '        ').join(cells)}
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
'''
    io.open(f'{out}/{name}.drawio', 'w', encoding='utf-8', newline='\n').write(xml)

API_CLIENT = (['- baseUrl : String', '- session : Session'],
              ['+ get(path) : Future<dynamic>', '+ post(path, body) : Future<dynamic>', '+ put(path, body) : Future<dynamic>', '+ patch(path, body) : Future<dynamic>'])
SESSION = (['+ token : String?', '+ username : String?', '+ role : String?'], ['+ isLoggedIn : bool', '+ clear() : void'])
COLORS = ['Colors', 'Blue: screens (Flutter widgets)', 'Green: calls to the web services', 'Yellow: data', 'Grey: application, session, order draft']
ASYNC = ['Every Api method is async and returns a', 'Future. Screens await it and show a loading', 'state, so the window never freezes (N2).']
BUILD = '+ build(context) : Widget'

# ------------------------------------------------------------- customer app
c = [
 cls('login', 'LoginScreen', COL[0], R[0], ['- usernameController', '- passwordController', '- loading : bool', '- error : String?'], [BUILD, '- onLogin() : Future<void>', '- openRegister() : void'], BLUE),
 cls('reg', 'RegisterScreen', COL[1], R[0], ['- usernameController', '- emailController', '- passwordController', '- confirmController', '- loading : bool', '- error : String?'], [BUILD, '- validate() : String?', '- onRegister() : Future<void>'], BLUE),
 cls('search', 'SearchScreen', COL[2], R[0], ['- keywordController', '- results : List<Book>', '- loading : bool'], [BUILD, '- onSearch() : Future<void>', '- addToOrder(book, type) : void', '- onLogout() : Future<void>'], BLUE),
 cls('orderc', 'OrderScreen', COL[3], R[0], ['- draft : OrderDraft', '- placing : bool', '- error : String?'], [BUILD, '- setType(item, type) : void', '- remove(item) : void', '- onPlaceOrder() : Future<void>'], BLUE),
 cls('billc', 'BillScreen', COL[4], R[0], ['- order : Order'], [BUILD, '- onNewSearch() : void'], BLUE),
 cls('uapi', 'UserApi', COL[0], R[1], ['(user-service, port 8081)'], ['+ login(username, password) : Future<Session>', '+ logout() : Future<void>', '+ register(username, email, password)'], GREEN),
 cls('bapi', 'BookApi', COL[2], R[1], ['(book-service, port 8082)'], ['+ search(keyword) : Future<List<Book>>'], GREEN),
 cls('oapi', 'OrderApi', COL[3], R[1], ['(order-service, port 8083)'], ['+ createOrder(items) : Future<Order>', '+ getBill(orderId) : Future<String>'], GREEN),
 cls('sess', 'Session', COL[0], R[2], *SESSION, GREY),
 cls('api', 'ApiClient', COL[2], R[2], *API_CLIENT, GREEN),
 cls('draft', 'OrderDraft', COL[3], R[2], ['- items : List<OrderItem>'], ['+ add(book, type) : void', '+ remove(item) : void', '+ total : double', '+ clear() : void'], GREY),
 cls('app', 'CustomerApp', COL[0], R[3], ['- session : Session', '- draft : OrderDraft', 'home: LoginScreen'], ['+ main() : void', BUILD], GREY),
 cls('book', 'Book', COL[1], R[3], ['+ id : String', '+ title : String', '+ author : String', '+ price : double', '+ copiesAvailable : int'], ['+ Book.fromJson(json)', '+ rentPrice : double'], YELLOW),
 cls('item', 'OrderItem', COL[2], R[3], ['+ book : Book', '+ type : ItemType', '+ quantity : int'], ['+ charge : double', '+ rentDueDate : DateTime?', '+ toJson() : Map'], YELLOW),
 cls('order', 'Order', COL[3], R[3], ['+ id : int', '+ items : List<OrderItem>', '+ total : double', '+ paymentStatus : String', '+ billHtml : String'], ['+ Order.fromJson(json)'], YELLOW),
 cls('type', 'ItemType', COL[2], R[4], ['buy', 'rent'], None, YELLOW, 'enumeration'),
 edge('opens', 'login', 'reg', 'opens'), edge('opens', 'reg', 'search', ''), edge('opens', 'search', 'orderc', 'opens'), edge('opens', 'orderc', 'billc', 'opens'),
 edge('uses', 'login', 'uapi', 'uses'), edge('uses', 'reg', 'uapi', 'uses'), edge('uses', 'search', 'bapi', 'uses'), edge('uses', 'orderc', 'oapi', 'uses'),
 edge('extends', 'uapi', 'api'), edge('extends', 'bapi', 'api'), edge('extends', 'oapi', 'api'),
 edge('uses', 'api', 'sess', 'sends token'),
 edge('has', 'draft', 'item', ''), edge('has', 'order', 'item', '1..*'), edge('opens', 'item', 'book', '1'), edge('opens', 'item', 'type'),
 note(COL[4], R[1], 130, ASYNC + ['', 'Rent charge = 10% of the price.', 'Rent due date = order date + 7 days.']),
 note(COL[4], R[3], 110, COLORS),
]
write('class-customer-app', 'Customer app classes', c)

# ------------------------------------------------------------- manager app
_n[0] = 0
m = [
 cls('app', 'ManagerApp', COL[0], R[0], ['- session : Session', 'home: LoginScreen'], ['+ main() : void', BUILD], GREY),
 cls('login', 'LoginScreen', COL[1], R[0], ['- usernameController', '- passwordController', '- loading : bool', '- error : String?'], [BUILD, '- onLogin() : Future<void>', '- isManager(session) : bool'], BLUE),
 cls('ordersc', 'OrdersScreen', COL[2], R[0], ['- orders : List<Order>', '- selected : Order?', '- loading : bool'], [BUILD, '- onRefresh() : Future<void>', '- onMarkPaid() : Future<void>', '- onViewBill() : Future<void>', '- onLogout() : Future<void>'], BLUE),
 cls('booksc', 'BooksScreen', COL[3], R[0], ['- keywordController', '- books : List<Book>', '- selected : Book?', '- loading : bool'], [BUILD, '- onSearch() : Future<void>', '- openAddDialog() : void', '- openEditDialog() : void'], BLUE),
 cls('form', 'BookFormDialog', COL[4], R[0], ['- book : Book?  (null = add)', '- titleController', '- authorController', '- priceController', '- copiesController'], [BUILD, '- validate() : String?', '- onSave() : Future<void>'], BLUE),
 cls('uapi', 'UserApi', COL[1], R[1], ['(user-service, port 8081)'], ['+ login(username, password) : Future<Session>', '+ logout() : Future<void>'], GREEN),
 cls('oapi', 'OrderApi', COL[2], R[1], ['(order-service, port 8083)'], ['+ listOrders() : Future<List<Order>>', '+ updatePaymentStatus(id, status)', '+ getBill(orderId) : Future<String>'], GREEN),
 cls('bapi', 'BookApi', COL[3], R[1], ['(book-service, port 8082)'], ['+ search(keyword) : Future<List<Book>>', '+ addBook(book) : Future<Book>', '+ updateBook(book) : Future<Book>'], GREEN),
 cls('sess', 'Session', COL[0], R[2], *SESSION, GREY),
 cls('api', 'ApiClient', COL[2], R[2], *API_CLIENT, GREEN),
 cls('order', 'Order', COL[2], R[3], ['+ id : int', '+ username : String', '+ createdAt : DateTime', '+ total : double', '+ paymentStatus : PaymentStatus'], ['+ Order.fromJson(json)', '+ isPaid : bool'], YELLOW),
 cls('book', 'Book', COL[3], R[3], ['+ id : String', '+ title : String', '+ author : String', '+ price : double', '+ copiesAvailable : int'], ['+ Book.fromJson(json)', '+ toJson() : Map'], YELLOW),
 cls('status', 'PaymentStatus', COL[2], R[4], ['pending', 'paid'], None, YELLOW, 'enumeration'),
 edge('opens', 'app', 'login', 'opens'), edge('opens', 'login', 'ordersc', 'opens'), edge('opens', 'ordersc', 'booksc', 'tabs'), edge('opens', 'booksc', 'form', 'opens'),
 edge('uses', 'login', 'uapi', 'uses'), edge('uses', 'ordersc', 'oapi', 'uses'), edge('uses', 'booksc', 'bapi', 'uses'), edge('uses', 'form', 'bapi', 'uses'),
 edge('extends', 'uapi', 'api'), edge('extends', 'oapi', 'api'), edge('extends', 'bapi', 'api'),
 edge('uses', 'api', 'sess', 'sends token'),
 edge('opens', 'order', 'status'),
 note(COL[4], R[2], 110, ['Only a session with the MANAGER role can', 'get past the login screen (FR11, N5).', ''] + ASYNC),
 note(COL[4], R[3], 110, COLORS),
]
write('class-manager-app', 'Manager app classes', m)
print('written')
