"""Class diagram of user-service: every class in services/user-service/src/main."""
import sys
from xml.sax.saxutils import escape
import flutter_cls as F

C = [40, 390, 740, 1090, 1440, 1810]
R = [40, 250, 520, 800, 1010, 1240]
RED = ('#f8cecc', '#b85450'); PURPLE = ('#e1d5e7', '#9673a6')
n = [0]
def E(a, b, label='', style=''):
    n[0] += 1
    return f'<mxCell id="x{n[0]}" value="{escape(label)}" style="html=1;rounded=0;fontSize=11;{style}" edge="1" parent="1" source="{a}" target="{b}"><mxGeometry relative="1" as="geometry" /></mxCell>'
USES = 'endArrow=open;endSize=10;dashed=1;'
EXT = 'endArrow=block;endFill=0;endSize=12;'
IMPL = 'endArrow=block;endFill=0;endSize=12;dashed=1;'
SIDE = EXT + 'edgeStyle=orthogonalEdgeStyle;exitX=1;exitY=0.5;entryX=1;entryY=0.5;'

c = [
 # start-up and settings
 F.cls('server', 'UserServer', C[0], R[0], ['- listeners : List<HttpServer>'], ['+ UserServer(port, auth)', '+ start() : void', '+ stop() : void', '+ port() : int', '+ main(args) : void', '- warmUp(hasher, auth) : void', '- warmUpOverHttp(port) : void'], F.GREY),
 F.cls('config', 'Config', C[1], R[0], ['+ port : int', '+ storage : String', '+ mysqlUrl, mysqlUser, mysqlPassword'], ['+ load() : Config', '+ usesMemory() : boolean', '- readDotEnv() : Map'], F.GREY, 'record'),
 # http
 F.cls('base', 'BaseHandler', C[0], R[1], ['(abstract) implements HttpHandler'], ['+ handle(exchange) : void', '# route(exchange) : void', '# requireMethod(exchange, method)', '# readJson(exchange, type) : T', '# bearerToken(exchange) : String', '# sendJson(exchange, status, body)', '- sendError(exchange, status, message)'], F.BLUE),
 F.cls('authh', 'AuthHandler', C[1], R[1], ['- auth : AuthService', 'PATH = /api/auth'], ['# route(exchange) : void', '- login(exchange) : void', '- logout(exchange) : void', '- session(exchange) : void'], F.BLUE),
 F.cls('userh', 'UserHandler', C[2], R[1], ['- auth : AuthService', 'PATH = /api/users'], ['# route(exchange) : void', '- register(exchange) : void'], F.BLUE),
 F.cls('json', 'Json', C[3], R[1], ['- GSON : Gson'], ['+ write(value) : String', '+ read(text, type) : T'], F.BLUE),
 # dto
 F.cls('loginreq', 'LoginRequest', C[4], R[0], ['+ username : String', '+ password : String'], ['+ validate() : void'], PURPLE, 'record'),
 F.cls('regreq', 'RegisterRequest', C[4], R[1], ['+ username : String', '+ email : String', '+ password : String'], ['+ validate() : void'], PURPLE, 'record'),
 F.cls('userres', 'UserResponse', C[4], R[2], ['+ token : String (login only)', '+ userId : int', '+ username, email, role : String'], ['+ of(user) : UserResponse', '+ withToken(user, token)'], PURPLE, 'record'),
 # service
 F.cls('tokens', 'TokenGenerator', C[0], R[2], ['- random : SecureRandom'], ['+ newToken() : String'], F.GREEN),
 F.cls('auth', 'AuthService', C[1], R[2], ['- users : UserRepository', '- sessions : SessionRepository', '- hasher : PasswordHasher', '- tokens : TokenGenerator', '- dummyHash : String'], ['+ login(username, password) : Login', '+ logout(token) : void', '+ checkSession(token) : User', '+ register(username, email, password) : User'], F.GREEN),
 F.cls('hasher', 'PasswordHasher', C[2], R[2], ['COST = 10 (bcrypt)'], ['+ hash(password) : String', '+ matches(password, hash) : boolean', '+ warmUp() : void'], F.GREEN),
 F.cls('loginres', 'AuthService.Login', C[3], R[2], ['+ session : Session', '+ user : User'], None, F.GREEN, 'record'),
 # repository
 F.cls('urepo', 'UserRepository', C[0] + 175, R[3], [], ['+ findByUsername(username) : Optional<User>', '+ findById(id) : Optional<User>', '+ existsByUsernameOrEmail(u, e)', '+ save(username, email, hash, role) : User'], F.YELLOW, 'interface'),
 F.cls('srepo', 'SessionRepository', C[2] + 175, R[3], [], ['+ create(token, userId) : Session', '+ find(token) : Optional<Session>', '+ delete(token) : boolean'], F.YELLOW, 'interface'),
 F.cls('jdbcu', 'JdbcUserRepository', C[0], R[4], ['- database : Database'], ['(MySQL table USERS)', '- findOne(sql, parameter)'], F.YELLOW),
 F.cls('memu', 'InMemoryUserRepository', C[1], R[4], ['- users : Map<Integer, User>', '- nextId : AtomicInteger'], ['(tests and memory mode)'], F.YELLOW),
 F.cls('jdbcs', 'JdbcSessionRepository', C[2], R[4], ['- database : Database'], ['(MySQL table SESSIONS)'], F.YELLOW),
 F.cls('mems', 'InMemorySessionRepository', C[3], R[4], ['- sessions : Map<String, Session>'], ['(tests and memory mode)'], F.YELLOW),
 F.cls('db', 'Database', C[1], R[5], ['- pool : HikariDataSource', 'POOL_SIZE = 8'], ['+ Database(config)', '+ open() : Connection', '+ close() : void'], F.YELLOW),
 # model
 F.cls('user', 'User', C[2], R[5], ['+ id : int', '+ username, email : String', '+ passwordHash : String', '+ role : Role', '+ createdAt : LocalDateTime'], None, F.GREY, 'record'),
 F.cls('session', 'Session', C[4], R[5], ['+ token : String', '+ userId : int', '+ createdAt : LocalDateTime'], None, F.GREY, 'record'),
 F.cls('role', 'Role', C[3], R[5], ['CUSTOMER', 'MANAGER'], None, F.GREY, 'enumeration'),
 # errors
 F.cls('apiex', 'ApiException', C[5], R[0], ['- status : int'], ['+ status() : int', '+ notFound(message)', '+ methodNotAllowed(allowed)'], RED),
 F.cls('valex', 'ValidationException', C[5], R[1], ['status 400'], None, RED),
 F.cls('unex', 'UnauthorizedException', C[5], R[1] + 120, ['status 401'], None, RED),
 F.cls('conex', 'ConflictException', C[5], R[1] + 240, ['status 409'], None, RED),
 F.cls('dataex', 'DataAccessException', C[5], R[3], ['(not an ApiException:', 'answered as a plain 500)'], None, RED),

 E('server', 'config', 'reads', USES), E('server', 'authh', 'creates', USES), E('server', 'base', '', 'endArrow=none;strokeColor=none;'),
 E('authh', 'base', '', EXT), E('userh', 'base', '', EXT + 'edgeStyle=orthogonalEdgeStyle;exitX=0.5;exitY=0;entryX=0.75;entryY=0;'),
 E('authh', 'auth', 'calls', USES), E('userh', 'auth', 'calls', USES),
 E('auth', 'tokens', '', USES), E('auth', 'hasher', '', USES),
 E('auth', 'urepo', '', USES), E('auth', 'srepo', '', USES),
 E('jdbcu', 'urepo', '', IMPL), E('memu', 'urepo', '', IMPL), E('jdbcs', 'srepo', '', IMPL), E('mems', 'srepo', '', IMPL),
 E('jdbcu', 'db', '', USES), E('jdbcs', 'db', '', USES),
 E('user', 'role', '', 'endArrow=open;endSize=10;'),
 E('valex', 'apiex', '', SIDE), E('unex', 'apiex', '', SIDE), E('conex', 'apiex', '', SIDE),
]
n[0] += 1
c.append(f'<mxCell id="note1" value="{F.esc(["Colors = layers (a layer only calls the one below it)", "Blue: HTTP. Receives requests, sends JSON, turns errors into responses", "Purple: the shapes of requests and responses, with their validation", "Green: the rules (login, sessions, registration)", "Yellow: database access (interface, MySQL version, in-memory version)", "Grey: start-up, settings, plain data", "Red: errors", "", "Not drawn, to keep it readable: every layer may throw the red errors, and", "handlers use the purple records. BaseHandler catches all errors in one place."])}" style="shape=note;size=14;whiteSpace=wrap;align=left;verticalAlign=top;spacingLeft=8;spacingTop=6;fillColor=#ffffff;strokeColor=#999999;fontSize=12;" vertex="1" parent="1"><mxGeometry x="{C[4]}" y="{R[3] + 150}" width="640" height="190" as="geometry" /></mxCell>')
F.write('class-user-service', 'user-service classes', c)
print('user-service diagram written')
