import 'package:material_ui/material_ui.dart';

import 'api/api_client.dart';
import 'api/apis.dart';
import 'api/local_services.dart';
import 'app_button.dart';
import 'app_text_field.dart';
import 'tokens.dart';

/// The log-in form of both apps (FR1, FR11).
///
/// Only an account with [role] gets in. Any other account is logged out again
/// with [wrongRoleMessage], which the login screen then shows (N5). On success
/// it calls [onLoggedIn]; the app decides where to go.
class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.users,
    required this.role,
    required this.wrongRoleMessage,
    required this.onLoggedIn,
    this.subtitle = 'Welcome back.',
    this.note,
    this.initialUsername,
    this.footer,
    this.localServices,
  });

  final UserApi users;

  /// CUSTOMER or MANAGER.
  final String role;
  final String wrongRoleMessage;
  final VoidCallback onLoggedIn;
  final String subtitle;

  /// A neutral note above the fields: why the last session ended, or that an account was just created.
  final String? note;

  /// Fills in the username, and puts the cursor in the password field.
  final String? initialUsername;

  /// Under the button, e.g. "Create an account".
  final Widget? footer;

  /// When given, the form first makes sure the services on this computer are running, and starts them if not.
  final LocalServices? localServices;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final _username = TextEditingController(text: widget.initialUsername);
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _starting = false;
  String? _error;
  String? _usernameError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    if (widget.initialUsername != null) WidgetsBinding.instance.addPostFrameCallback((_) => _passwordFocus.requestFocus());
    if (widget.localServices != null) _startServices();
  }

  Future<void> _startServices() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    final problem = await widget.localServices!.ensureRunning();
    if (!mounted) return;
    setState(() {
      _starting = false;
      _error = problem;
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    setState(() {
      _usernameError = _username.text.trim().isEmpty ? 'Enter your username' : null;
      _passwordError = _password.text.isEmpty ? 'Enter your password' : null;
      _error = null;
    });
    if (_usernameError != null || _passwordError != null) return;

    setState(() => _loading = true);
    try {
      await widget.users.login(_username.text, _password.text);
      if (widget.users.session.role != widget.role) {
        // N5: each app is for one role. Ending the session reopens the login screen with the reason.
        await widget.users.logout(reason: widget.wrongRoleMessage);
        return;
      }
      widget.onLoggedIn();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      if (e.status == 401) {
        _password.clear();
        _passwordFocus.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log in', style: t.headlineSmall),
          const SizedBox(height: Space.xs),
          Text(widget.subtitle, style: t.bodyMedium!.copyWith(color: c.textSecondary)),
          if (widget.note != null) ...[const SizedBox(height: Space.lg), InfoNote(widget.note!)],
          if (_starting) ...[
            const SizedBox(height: Space.lg),
            const InfoNote('Starting the bookstore services. The first start takes about 10 seconds.'),
          ],
          const SizedBox(height: Space.xl),
          AppTextField(
            label: 'Username',
            controller: _username,
            autofocus: widget.initialUsername == null,
            error: _usernameError,
            autofillHints: const [AutofillHints.username],
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: Space.lg),
          AppTextField(
            label: 'Password',
            controller: _password,
            focusNode: _passwordFocus,
            password: true,
            error: _passwordError,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onLogin(),
          ),
          if (_error != null) ...[const SizedBox(height: Space.lg), ErrorMessage(_error!)],
          const SizedBox(height: Space.xl),
          AppButton(
            label: _starting ? 'Starting the services…' : (_loading ? 'Logging in…' : 'Log in'),
            expand: true,
            loading: _loading || _starting,
            onPressed: _starting ? null : _onLogin,
          ),
          if (widget.footer != null) ...[const SizedBox(height: Space.lg), widget.footer!],
        ],
      ),
    );
  }
}

/// A neutral message with an icon: not an error, just something to know.
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm + 2),
        decoration: BoxDecoration(color: c.hover, borderRadius: BorderRadius.circular(Radii.control)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 17, color: c.text),
            const SizedBox(width: Space.sm),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
