import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../api/api_client.dart';
import '../main.dart';
import '../models/account_rules.dart';

/// Create a customer account (FR3, extra credit).
///
/// Each field's problem is shown under it before anything is sent. On
/// success it closes and hands the username back to the login screen.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _loading = false;
  String? _error;
  Map<String, String> _problems = {};

  /// After the first attempt, problems are re-checked as the customer types, so they disappear once fixed.
  bool _tried = false;

  @override
  void dispose() {
    for (final c in [_username, _email, _password, _confirm]) {
      c.dispose();
    }
    for (final f in [_emailFocus, _passwordFocus, _confirmFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  Map<String, String> _validate() =>
      checkRegistration(username: _username.text, email: _email.text, password: _password.text, confirm: _confirm.text);

  void _recheck(String _) {
    if (_tried) setState(() => _problems = _validate());
  }

  Future<void> _onRegister() async {
    setState(() {
      _tried = true;
      _problems = _validate();
      _error = null;
    });
    if (_problems.isNotEmpty) return;

    setState(() => _loading = true);
    try {
      await AppScope.of(context).services.users.register(_username.text, _email.text, _password.text);
      if (mounted) Navigator.of(context).pop(_username.text.trim());
    } on ApiException catch (e) {
      // 409: the username or email is already used. The message from user-service says which.
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BookstoreColors.of(context);
    final t = Theme.of(context).textTheme;

    return AuthLayout(
      tagline: 'Make an account in a minute.',
      note: 'You need one to place orders. Your password is stored only as a secure hash.',
      coverTitles: const ['Introduction to Algorithms', 'The Pragmatic Programmer', 'Design Patterns'],
      actions: [AppIconButton(icon: Icons.close_rounded, tooltip: 'Back to log in (Esc)', onPressed: () => Navigator.of(context).pop())],
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop()},
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create an account', style: t.headlineSmall),
              const SizedBox(height: Space.xs),
              Text('For customers. Managers are added by the store.', style: t.bodyMedium!.copyWith(color: c.textSecondary)),
              const SizedBox(height: Space.xl),
              AppTextField(
                label: 'Username',
                controller: _username,
                autofocus: true,
                hint: 'Letters, digits, . - _',
                error: _problems['username'],
                autofillHints: const [AutofillHints.newUsername],
                onChanged: _recheck,
                onSubmitted: (_) => _emailFocus.requestFocus(),
              ),
              const SizedBox(height: Space.lg),
              AppTextField(
                label: 'Email',
                controller: _email,
                focusNode: _emailFocus,
                hint: 'Your bills are sent here',
                keyboardType: TextInputType.emailAddress,
                error: _problems['email'],
                autofillHints: const [AutofillHints.email],
                onChanged: _recheck,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: Space.lg),
              AppTextField(
                label: 'Password',
                controller: _password,
                focusNode: _passwordFocus,
                password: true,
                hint: 'At least 8 characters',
                error: _problems['password'],
                autofillHints: const [AutofillHints.newPassword],
                onChanged: _recheck,
                onSubmitted: (_) => _confirmFocus.requestFocus(),
              ),
              const SizedBox(height: Space.lg),
              AppTextField(
                label: 'Confirm password',
                controller: _confirm,
                focusNode: _confirmFocus,
                password: true,
                error: _problems['confirm'],
                textInputAction: TextInputAction.done,
                onChanged: _recheck,
                onSubmitted: (_) => _onRegister(),
              ),
              if (_error != null) ...[const SizedBox(height: Space.lg), ErrorMessage(_error!)],
              const SizedBox(height: Space.xl),
              AppButton(label: _loading ? 'Creating account…' : 'Create account', expand: true, loading: _loading, onPressed: _onRegister),
              const SizedBox(height: Space.sm),
              AppButton(
                label: 'Back to log in',
                style: AppButtonStyle.quiet,
                expand: true,
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
