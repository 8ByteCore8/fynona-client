import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;
import 'package:fynona_ui/fynona_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/api.dart';
import '../../auth/auth.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shell/router.dart';
import 'auth_widgets.dart';

const signUpEmailKey = ValueKey('sign-up-email');
const signUpPasswordKey = ValueKey('sign-up-password');
const signUpSubmitKey = ValueKey('sign-up-submit');
const signUpAgainKey = ValueKey('verify-sign-up-again');

/// Create an account (SEC-3). The server answers the same whether or not
/// the email is registered, so the next screen is always «check your email».
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with AuthFormState {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signUp() => submit(() async {
    final email = _email.text.trim();
    await ref
        .read(apiTransportProvider)
        .call(
          (api) => api.auth.registerAccount(
            body: RegisterRequest(
              email: Email(email),
              password: NewPassword(_password.text),
            ),
          ),
        );
    ref.read(pendingRegistrationProvider.notifier).set(email);
    if (mounted) context.go(verifyPendingPath);
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final error = this.error;
    return AuthScaffold(
      title: l.authSignUpTitle,
      children: [
        Form(
          key: formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: signUpEmailKey,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l.authEmail),
                  validator: (v) => validateEmail(l, v),
                ),
                const SizedBox(height: FynonaTokens.space12),
                TextFormField(
                  key: signUpPasswordKey,
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _signUp(),
                  decoration: InputDecoration(labelText: l.authNewPassword),
                  validator: (v) =>
                      (v ?? '').length < 8 ? l.authPasswordTooShort : null,
                ),
              ],
            ),
          ),
        ),
        if (error != null) AuthMessage(authErrorText(l, error), error: true),
        AuthSubmitButton(
          key: signUpSubmitKey,
          label: l.authSignUpAction,
          busy: busy,
          onPressed: _signUp,
        ),
        const SizedBox(height: FynonaTokens.space16),
        TextButton(
          onPressed: () => context.go(signInPath),
          child: Text(l.authToSignIn),
        ),
      ],
    );
  }
}

/// «Check your email» after a sign-up. The contract has no route to send the
/// email again, so the screen says where to look and offers a new sign-up.
class VerifyPendingScreen extends ConsumerWidget {
  const VerifyPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final email = ref.watch(pendingRegistrationProvider);
    void leave(String path) {
      ref.read(pendingRegistrationProvider.notifier).set(null);
      context.go(path);
    }

    return AuthScaffold(
      title: l.authVerifyPendingTitle,
      children: [
        if (email != null) AuthMessage(l.authVerifyPendingMessage(email)),
        AuthMessage(l.authVerifyPendingHint),
        const SizedBox(height: FynonaTokens.space16),
        FilledButton(
          key: signUpAgainKey,
          onPressed: () => leave(signUpPath),
          child: Text(l.authSignUpAgain),
        ),
        TextButton(
          onPressed: () => leave(signInPath),
          child: Text(l.authBackToSignIn),
        ),
      ],
    );
  }
}

/// Opens from the emailed link `/verify-email?token=…` and confirms the
/// address right away (SEC-3).
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late final Future<void> _verified = _verify();

  Future<void> _verify() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      throw const ApiHttpException(400);
    }
    await ref
        .read(apiTransportProvider)
        .call(
          (api) => api.auth.verifyEmail(body: LinkTokenRequest(token: token)),
        );
    ref.read(pendingRegistrationProvider.notifier).set(null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final signedIn = ref.watch(authStateProvider) == AuthState.signedIn;
    return AuthScaffold(
      title: l.authVerifyTitle,
      children: [
        FutureBuilder<void>(
          future: _verified,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: Semantics(
                  label: l.authVerifyTitle,
                  child: const CircularProgressIndicator(),
                ),
              );
            }
            final error = snapshot.error;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error == null)
                  AuthMessage(l.authVerifyDone)
                else
                  AuthMessage(
                    error is ApiHttpException && error.status == 400
                        ? l.authLinkInvalid
                        : authErrorText(l, error),
                    error: true,
                  ),
                const SizedBox(height: FynonaTokens.space16),
                FilledButton(
                  onPressed: () =>
                      context.go(signedIn ? overviewPath : signInPath),
                  child: Text(signedIn ? l.navOverview : l.authSignInAction),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
