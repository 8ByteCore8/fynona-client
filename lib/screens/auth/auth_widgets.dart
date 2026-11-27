import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';

/// The text of a failed auth call. Branches on the problem `code` (API-30);
/// a wrong email and a wrong password read the same (SEC-3).
String authErrorText(AppLocalizations l, Object error) => switch (error) {
  ApiProblemException(code: 'auth.invalid_credentials') =>
    l.authInvalidCredentials,
  ApiProblemException(code: 'auth.email_unverified') => l.authEmailUnverified,
  ApiProblemException(code: 'auth.account_blocked') => l.authAccountBlocked,
  ApiProblemException(code: 'auth.link_invalid') => l.authLinkInvalid,
  ApiProblemException(code: 'auth.mfa_invalid') => l.authMfaInvalid,
  ApiProblemException(code: 'auth.passkey_invalid') => l.authPasskeyFailed,
  ApiProblemException(code: 'rate_limited') => l.authRateLimited,
  ApiNetworkException() || CircuitOpenException() => l.authNetworkError,
  _ => l.authUnknownError,
};

/// A form field validator: a plausible email address.
String? validateEmail(AppLocalizations l, String? value) {
  final text = value?.trim() ?? '';
  return RegExp(r'^[^@\s]+@[^@\s]+$').hasMatch(text)
      ? null
      : l.authEmailInvalid;
}

/// Layout of every auth screen: a titled, centred, scrollable column no
/// wider than a phone.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.fynonaColors;
    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(FynonaTokens.space24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: FynonaTypography.title.copyWith(
                          color: colors.contentPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: FynonaTokens.space24),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A message under a form: an error in the error colour, announced to
/// screen readers as it appears.
class AuthMessage extends StatelessWidget {
  const AuthMessage(this.text, {super.key, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = context.fynonaColors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: FynonaTokens.space16),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: FynonaTypography.body.copyWith(
            color: error
                ? Theme.of(context).colorScheme.error
                : colors.contentSecondary,
          ),
        ),
      ),
    );
  }
}

/// The main button of a form; shows progress while [busy].
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: FynonaTokens.space16),
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? Semantics(
              label: label,
              child: const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Text(label),
    ),
  );
}

/// The busy flag, error and run helper shared by the auth forms.
mixin AuthFormState<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  bool busy = false;
  Object? error;

  /// Validates the form and runs [action], keeping [busy] and [error].
  Future<void> submit(Future<void> Function() action) async {
    if (busy || !(formKey.currentState?.validate() ?? true)) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } on Object catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
