import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;
import 'package:fynona_ui/fynona_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../auth/auth.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shell/router.dart';
import 'auth_widgets.dart';

const signInEmailKey = ValueKey('sign-in-email');
const signInPasswordKey = ValueKey('sign-in-password');
const signInSubmitKey = ValueKey('sign-in-submit');
const passkeyButtonKey = ValueKey('sign-in-passkey');
const mfaCodeKey = ValueKey('mfa-code');
const mfaToggleKey = ValueKey('mfa-toggle');
const mfaSubmitKey = ValueKey('mfa-submit');

/// Sign in with email and password, or with a passkey on web (SEC-1, SEC-3).
/// The router leaves this screen once the session is open.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with AuthFormState {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() => submit(() async {
    final outcome = await ref
        .read(authSessionProvider)
        .login(email: _email.text.trim(), password: _password.text);
    if (outcome case MfaRequired(:final challenge)) {
      ref.read(mfaChallengeProvider.notifier).set(challenge);
      if (mounted) context.go(mfaPath);
    }
  });

  Future<void> _passkey(PasskeyAuthenticator authenticate) async {
    final session = ref.read(authSessionProvider);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final ceremony = await session.transport.call(
        (api) => api.auth.beginPasskeyLogin(),
      );
      final credential = await authenticate(ceremony.options);
      await session.loginWithPasskey(
        ceremonyId: ceremony.ceremonyId,
        credential: credential,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e);
    } on Object {
      // Cancelled in the browser or not allowed there.
      if (mounted) {
        setState(() => error = const _PasskeyCancelled());
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final authenticate = ref.watch(passkeyAuthenticatorProvider);
    final error = this.error;
    return AuthScaffold(
      title: l.authSignInTitle,
      children: [
        Form(
          key: formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: signInEmailKey,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l.authEmail),
                  validator: (v) => validateEmail(l, v),
                ),
                const SizedBox(height: FynonaTokens.space12),
                TextFormField(
                  key: signInPasswordKey,
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(labelText: l.authPassword),
                  validator: (v) =>
                      (v ?? '').isEmpty ? l.authPasswordRequired : null,
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          AuthMessage(
            error is _PasskeyCancelled
                ? l.authPasskeyFailed
                : authErrorText(l, error),
            error: true,
          ),
        AuthSubmitButton(
          key: signInSubmitKey,
          label: l.authSignInAction,
          busy: busy,
          onPressed: _signIn,
        ),
        if (authenticate != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: FynonaTokens.space12,
            ),
            child: OutlinedButton.icon(
              key: passkeyButtonKey,
              onPressed: busy ? null : () => _passkey(authenticate),
              icon: const Icon(Icons.key_rounded),
              label: Text(l.authPasskeySignIn),
            ),
          ),
        const SizedBox(height: FynonaTokens.space16),
        TextButton(
          onPressed: () => context.go(forgotPasswordPath),
          child: Text(l.authForgotPassword),
        ),
        TextButton(
          onPressed: () => context.go(signUpPath),
          child: Text(l.authToSignUp),
        ),
      ],
    );
  }
}

/// The browser ceremony ended without an assertion.
final class _PasskeyCancelled {
  const _PasskeyCancelled();
}

/// The second step of a sign-in with TOTP on (SEC-2): a code from the
/// authenticator app or a recovery code completes `POST /v1/auth/login/mfa`.
class MfaScreen extends ConsumerStatefulWidget {
  const MfaScreen({super.key});

  @override
  ConsumerState<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends ConsumerState<MfaScreen> with AuthFormState {
  final _code = TextEditingController();
  bool _recovery = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm(MfaChallenge challenge) => submit(() async {
    final code = _code.text.trim();
    await ref
        .read(authSessionProvider)
        .completeMfa(
          challenge,
          code: _recovery ? null : code,
          recoveryCode: _recovery ? code : null,
        );
    ref.read(mfaChallengeProvider.notifier).set(null);
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final challenge = ref.watch(mfaChallengeProvider);
    final error = this.error;
    // A dead challenge (five wrong codes or five minutes) cannot be retried.
    final expired =
        challenge == null ||
        (error is ApiProblemException && error.status == 401);
    if (expired) {
      return AuthScaffold(
        title: l.authMfaTitle,
        children: [
          AuthMessage(l.authMfaExpired, error: true),
          const SizedBox(height: FynonaTokens.space16),
          FilledButton(
            onPressed: () => context.go(signInPath),
            child: Text(l.authBackToSignIn),
          ),
        ],
      );
    }
    final recoveryAllowed = challenge.methods.contains(
      MfaChallengeMethodsItem.recoveryCode,
    );
    return AuthScaffold(
      title: l.authMfaTitle,
      children: [
        Form(
          key: formKey,
          child: TextFormField(
            key: mfaCodeKey,
            controller: _code,
            autofocus: true,
            keyboardType: _recovery
                ? TextInputType.visiblePassword
                : TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            onFieldSubmitted: (_) => _confirm(challenge),
            decoration: InputDecoration(
              labelText: _recovery ? l.authMfaRecoveryCode : l.authMfaCode,
            ),
            validator: (v) {
              final text = v?.trim() ?? '';
              if (_recovery) return text.isEmpty ? l.authMfaInvalid : null;
              return RegExp(r'^[0-9]{6}$').hasMatch(text)
                  ? null
                  : l.authMfaCodeInvalid;
            },
          ),
        ),
        if (error != null) AuthMessage(authErrorText(l, error), error: true),
        AuthSubmitButton(
          key: mfaSubmitKey,
          label: l.authMfaAction,
          busy: busy,
          onPressed: () => _confirm(challenge),
        ),
        if (recoveryAllowed) ...[
          const SizedBox(height: FynonaTokens.space16),
          TextButton(
            key: mfaToggleKey,
            onPressed: () => setState(() {
              _recovery = !_recovery;
              _code.clear();
              this.error = null;
            }),
            child: Text(_recovery ? l.authMfaUseCode : l.authMfaUseRecovery),
          ),
        ],
        TextButton(
          onPressed: () => context.go(signInPath),
          child: Text(l.authBackToSignIn),
        ),
      ],
    );
  }
}
