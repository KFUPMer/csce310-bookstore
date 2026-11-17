import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../api/api_client.dart';
import '../main.dart';
import 'register_screen.dart';
import 'search_screen.dart';

/// Log in (FR1). The first screen, and where the app returns when the session ends.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  String? _error;
  String? _usernameError;
  String? _passwordError;

  /// A neutral note above the form: why the last session ended, or that an account was just created.
  String? _note;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _note ??= AppScope.of(context).services.session.endedMessage;
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

    final services = AppScope.of(context).services;
    setState(() => _loading = true);
    try {
      await services.users.login(_username.text, _password.text);
      if (services.session.role != 'CUSTOMER') {
        // N5: placing orders is for customers. Managers have their own app (FR11).
        // Ending the session reopens this screen, which shows the reason.
        await services.users.logout(reason: 'This app is for customers. Managers log in to the management app.');
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(fadeRoute(const SearchScreen()));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      if (e.status == 401) {
        _password.clear();
        _passwordFocus.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRegister() async {
    final username = await Navigator.of(context).push<String>(fadeRoute(const RegisterScreen()));
    if (username == null || !mounted) return;
    // FR3: the new account is ready; log in with it.
    setState(() {
      _username.text = username;
      _password.clear();
      _error = null;
      _note = 'Account created. Log in with your new password.';
    });
    _passwordFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;

    return AuthLayout(
      tagline: 'Find a book. Buy it, or rent it for a week.',
      note: 'Search the catalog by title or author. Renting costs 10% of the price.',
      coverTitles: const ['Effective Java', 'Clean Code', 'Database System Concepts'],
      actions: [
        AppIconButton(
          icon: scope.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          tooltip: scope.isDark ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: scope.toggleTheme,
        ),
      ],
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log in', style: t.headlineSmall),
            const SizedBox(height: Space.xs),
            Text('Welcome back.', style: t.bodyMedium!.copyWith(color: c.textSecondary)),
            if (_note != null) ...[const SizedBox(height: Space.lg), _Note(_note!)],
            const SizedBox(height: Space.xl),
            AppTextField(
              label: 'Username',
              controller: _username,
              autofocus: true,
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
            AppButton(label: _loading ? 'Logging in…' : 'Log in', expand: true, loading: _loading, onPressed: _onLogin),
            const SizedBox(height: Space.lg),
            // Wraps rather than overflows if the text is larger (e.g. Windows text scaling).
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('New here?', style: t.bodyMedium!.copyWith(color: c.textSecondary)),
                const SizedBox(width: Space.xs),
                AppButton(label: 'Create an account', style: AppButtonStyle.quiet, onPressed: _loading ? null : _openRegister),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A neutral message with an icon: not an error, just something to know.
class _Note extends StatelessWidget {
  const _Note(this.text);

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
