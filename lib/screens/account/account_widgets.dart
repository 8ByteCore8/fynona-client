import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../account/account.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_widgets.dart';

const recoveryCodesCopyKey = ValueKey('recovery-codes-copy');
const recoveryCodesSaveKey = ValueKey('recovery-codes-save');
const confirmDialogOkKey = ValueKey('confirm-dialog-ok');

/// A date and time in the app's language, e.g. «27 лист. 2026 р., 14:05».
String formatDateTime(BuildContext context, DateTime value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).add_Hm().format(value.toLocal());
}

/// A screen under «Ще» with a back button and a scrollable body.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.fynonaColors;
    return Scaffold(
      backgroundColor: colors.backgroundBase,
      appBar: AppBar(
        backgroundColor: colors.backgroundBase,
        title: Semantics(header: true, child: Text(title)),
      ),
      body: ListView(
        padding: EdgeInsetsDirectional.only(
          bottom: MediaQuery.paddingOf(context).bottom + FynonaTokens.space24,
        ),
        children: children,
      ),
    );
  }
}

/// A section title inside a [SettingsPage].
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      start: FynonaTokens.spaceContentInset,
      end: FynonaTokens.spaceContentInset,
      top: FynonaTokens.space24,
      bottom: FynonaTokens.space8,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: FynonaTypography.sectionTitle.copyWith(
          color: context.fynonaColors.contentPrimary,
        ),
      ),
    ),
  );
}

/// Padding of free content inside a [SettingsPage].
class SectionBody extends StatelessWidget {
  const SectionBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: FynonaTokens.spaceContentInset,
    ),
    child: child,
  );
}

/// Shows [value]'s data with [data], a spinner while loading and the error
/// with a retry button that reloads [provider].
class AsyncSection<T> extends ConsumerWidget {
  const AsyncSection({super.key, required this.provider, required this.data});

  final FutureProvider<T> provider;
  final Widget Function(T value) data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final value = ref.watch(provider);
    return switch (value) {
      AsyncData(:final value) => data(value),
      AsyncError(:final error) => SectionBody(
        child: Row(
          children: [
            Expanded(child: AuthMessage(authErrorText(l, error), error: true)),
            TextButton(
              onPressed: () => ref.invalidate(provider),
              child: Text(l.commonRetry),
            ),
          ],
        ),
      ),
      _ => const Padding(
        padding: EdgeInsetsDirectional.all(FynonaTokens.space16),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

/// Asks to confirm [message]; true when the user does.
Future<bool> confirmAction(
  BuildContext context, {
  required String message,
  required String action,
}) async {
  final l = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          key: confirmDialogOkKey,
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Tells the user in a snack bar.
void showNotice(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

/// Recovery codes shown once (SEC-2), with copy and save; they live only in
/// the widget that shows them.
class RecoveryCodesView extends ConsumerWidget {
  const RecoveryCodesView({super.key, required this.codes});

  final List<String> codes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final colors = context.fynonaColors;
    final text = codes.join('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.recoveryCodesHint,
          style: FynonaTypography.body.copyWith(color: colors.contentSecondary),
        ),
        const SizedBox(height: FynonaTokens.space16),
        SelectableText(
          text,
          textAlign: TextAlign.center,
          style: FynonaTypography.body.copyWith(
            color: colors.contentPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: FynonaTokens.space16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: FynonaTokens.space8,
          children: [
            OutlinedButton.icon(
              key: recoveryCodesCopyKey,
              icon: const Icon(Icons.copy_rounded),
              label: Text(l.commonCopy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) showNotice(context, l.commonCopied);
              },
            ),
            OutlinedButton.icon(
              key: recoveryCodesSaveKey,
              icon: const Icon(Icons.save_alt_rounded),
              label: Text(l.commonSave),
              onPressed: () async {
                try {
                  final where = await ref.read(fileSaverProvider)(
                    'fynona-recovery-codes.txt',
                    utf8.encode('$text\n'),
                    'text/plain',
                  );
                  if (context.mounted) {
                    showNotice(context, l.commonSavedTo(where));
                  }
                } on Object {
                  if (context.mounted) showNotice(context, l.commonSaveFailed);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Shows freshly issued recovery codes in a dialog that closes only on «done».
Future<void> showRecoveryCodes(BuildContext context, List<String> codes) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l.recoveryCodesTitle),
          content: SingleChildScrollView(
            child: RecoveryCodesView(codes: codes),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.commonDone),
            ),
          ],
        );
      },
    );

const formDialogSubmitKey = ValueKey('form-dialog-submit');

/// One text field of [showFormDialog].
class DialogField {
  const DialogField({
    required this.key,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.validator,
  });

  final Key key;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;

  /// An error text for the value, or null when it is fine.
  final String? Function(String value)? validator;
}

/// A dialog with [fields] that runs [run] with their values (trimmed, except
/// secrets) and closes
/// with its result; a failure stays in the dialog as text. [canSubmit] keeps
/// the action disabled until it holds (e.g. a typed confirmation).
Future<R?> showFormDialog<R>(
  BuildContext context, {
  required String title,
  String? message,
  required List<DialogField> fields,
  required String action,
  bool destructive = false,
  bool Function(List<String> values)? canSubmit,
  required Future<R> Function(List<String> values) run,
}) => showDialog<R>(
  context: context,
  builder: (context) => _FormDialog<R>(
    title: title,
    message: message,
    fields: fields,
    action: action,
    destructive: destructive,
    canSubmit: canSubmit,
    run: run,
  ),
);

class _FormDialog<R> extends StatefulWidget {
  const _FormDialog({
    required this.title,
    required this.message,
    required this.fields,
    required this.action,
    required this.destructive,
    required this.canSubmit,
    required this.run,
  });

  final String title;
  final String? message;
  final List<DialogField> fields;
  final String action;
  final bool destructive;
  final bool Function(List<String> values)? canSubmit;
  final Future<R> Function(List<String> values) run;

  @override
  State<_FormDialog<R>> createState() => _FormDialogState<R>();
}

class _FormDialogState<R> extends State<_FormDialog<R>> with AuthFormState {
  late final _controllers = [
    for (final _ in widget.fields) TextEditingController(),
  ];

  /// A secret ([DialogField.obscure]) goes as typed, like at sign-in; the
  /// rest is trimmed.
  List<String> get _values => [
    for (final (i, c) in _controllers.indexed)
      widget.fields[i].obscure ? c.text : c.text.trim(),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() => submit(() async {
    final result = await widget.run(_values);
    if (mounted) Navigator.pop(context, result);
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final error = this.error;
    final message = widget.message;
    final allowed = widget.canSubmit?.call(_values) ?? true;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message != null) Text(message),
              for (final (i, field) in widget.fields.indexed)
                TextFormField(
                  key: field.key,
                  controller: _controllers[i],
                  obscureText: field.obscure,
                  keyboardType: field.keyboardType,
                  autofillHints: field.autofillHints,
                  decoration: InputDecoration(labelText: field.label),
                  onChanged: (_) => setState(() {}),
                  validator: field.validator == null
                      ? null
                      : (v) => field.validator!(
                          field.obscure ? v ?? '' : v?.trim() ?? '',
                        ),
                ),
              if (error != null)
                AuthMessage(authErrorText(l, error), error: true),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          key: formDialogSubmitKey,
          style: widget.destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: busy || !allowed ? null : _submit,
          child: Text(widget.action),
        ),
      ],
    );
  }
}

/// A TOTP code: six digits.
String? validateTotpCode(AppLocalizations l, String value) =>
    RegExp(r'^\d{6}$').hasMatch(value) ? null : l.securityTotpCodeInvalid;
