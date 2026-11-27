import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;
import 'package:fynona_ui/fynona_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/api.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shell/router.dart';
import 'auth_widgets.dart';

const forgotEmailKey = ValueKey('forgot-email');
const forgotSubmitKey = ValueKey('forgot-submit');
const resetPasswordKey = ValueKey('reset-password');
const resetSubmitKey = ValueKey('reset-submit');

/// Ask for a password reset link (SEC-3). The answer reads the same whether
/// or not the email has an account.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with AuthFormState {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() => submit(() async {
    await ref
        .read(apiTransportProvider)
        .call(
          (api) => api.auth.requestPasswordReset(
            body: PasswordResetRequest(email: Email(_email.text.trim())),
          ),
        );
    if (mounted) setState(() => _sent = true);
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final error = this.error;
    return AuthScaffold(
      title: l.authForgotTitle,
      children: [
        if (_sent)
          AuthMessage(l.authForgotSent)
        else ...[
          Form(
            key: formKey,
            child: TextFormField(
              key: forgotEmailKey,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _send(),
              decoration: InputDecoration(labelText: l.authEmail),
              validator: (v) => validateEmail(l, v),
            ),
          ),
          if (error != null) AuthMessage(authErrorText(l, error), error: true),
          AuthSubmitButton(
            key: forgotSubmitKey,
            label: l.authForgotSend,
            busy: busy,
            onPressed: _send,
          ),
        ],
        const SizedBox(height: FynonaTokens.space16),
        TextButton(
          onPressed: () => context.go(signInPath),
          child: Text(l.authBackToSignIn),
        ),
      ],
    );
  }
}

/// Opens from the emailed link `/reset-password?token=…` and sets a new
/// password (SEC-3). The reset also confirms the email and ends every
/// session of the account.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with AuthFormState {
  final _password = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _reset(String token) => submit(() async {
    await ref
        .read(apiTransportProvider)
        .call(
          (api) => api.auth.confirmPasswordReset(
            body: PasswordResetConfirm(
              token: token,
              password: NewPassword(_password.text),
            ),
          ),
        );
    if (mounted) setState(() => _done = true);
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final token = widget.token;
    final error = this.error;
    final linkDead =
        token == null ||
        token.isEmpty ||
        (error is ApiProblemException && error.code == 'auth.link_invalid');
    return AuthScaffold(
      title: l.authResetTitle,
      children: [
        if (_done)
          AuthMessage(l.authResetDone)
        else if (linkDead)
          AuthMessage(l.authLinkInvalid, error: true)
        else ...[
          Form(
            key: formKey,
            child: TextFormField(
              key: resetPasswordKey,
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _reset(token),
              decoration: InputDecoration(labelText: l.authNewPassword),
              validator: (v) =>
                  (v ?? '').length < 8 ? l.authPasswordTooShort : null,
            ),
          ),
          if (error != null) AuthMessage(authErrorText(l, error), error: true),
          AuthSubmitButton(
            key: resetSubmitKey,
            label: l.authResetAction,
            busy: busy,
            onPressed: () => _reset(token),
          ),
        ],
        const SizedBox(height: FynonaTokens.space16),
        TextButton(
          onPressed: () => context.go(signInPath),
          child: Text(l.authBackToSignIn),
        ),
        if (linkDead && !_done)
          TextButton(
            onPressed: () => context.go(forgotPasswordPath),
            child: Text(l.authForgotPassword),
          ),
      ],
    );
  }
}
