import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_api/fynona_api.dart' as api show Locale;
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../account/account.dart';
import '../../api/api.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shell/file_name.dart';
import '../auth/auth_widgets.dart';
import 'account_widgets.dart';

const accountNameKey = ValueKey('account-name');
const accountLocaleKey = ValueKey('account-locale');
const accountCurrencyKey = ValueKey('account-currency');
const accountSaveKey = ValueKey('account-save');
const emailPendingKey = ValueKey('account-email-pending');
const emailChangeKey = ValueKey('account-email-change');
const emailNewFieldKey = ValueKey('account-email-new');
const reauthPasswordKey = ValueKey('account-reauth-password');
const reauthCodeKey = ValueKey('account-reauth-code');
const exportStartKey = ValueKey('account-export-start');
const exportProgressKey = ValueKey('account-export-progress');
const exportDownloadKey = ValueKey('account-export-download');
const exportRetryKey = ValueKey('account-export-retry');
const deleteAccountKey = ValueKey('account-delete');
const deleteConfirmFieldKey = ValueKey('account-delete-confirm');

/// Ще → Акаунт: display name, language and display currency (API-23), the
/// email change awaiting its link (SEC-3), the data export and account
/// deletion (SEC-60).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return SettingsPage(
      title: l.moreAccount,
      children: [
        AsyncSection(
          provider: accountProvider,
          data: (account) => _Account(account: account),
        ),
      ],
    );
  }
}

/// Re-authentication fields of `POST /v1/me/email` and `DELETE /v1/me`: the
/// password, plus a TOTP code or recovery code when TOTP is on.
List<DialogField> _reauthFields(AppLocalizations l, {required bool totp}) => [
  DialogField(
    key: reauthPasswordKey,
    label: l.authPassword,
    obscure: true,
    autofillHints: const [AutofillHints.password],
  ),
  if (totp)
    DialogField(
      key: reauthCodeKey,
      label: l.accountReauthCode,
      autofillHints: const [AutofillHints.oneTimeCode],
    ),
];

/// A six-digit value is a TOTP code, anything else a recovery code.
({TotpCode? code, String? recoveryCode}) _secondFactor(String? value) {
  if (value == null || value.isEmpty) return (code: null, recoveryCode: null);
  return RegExp(r'^\d{6}$').hasMatch(value)
      ? (code: TotpCode(value), recoveryCode: null)
      : (code: null, recoveryCode: value);
}

class _Account extends ConsumerStatefulWidget {
  const _Account({required this.account});

  final Versioned<Profile> account;

  @override
  ConsumerState<_Account> createState() => _AccountState();
}

class _AccountState extends ConsumerState<_Account> with AuthFormState {
  late final _name = TextEditingController(text: _profile.displayName);
  late final _currency = TextEditingController(text: _profile.displayCurrency);
  late api.Locale _locale = _profile.locale;

  Profile get _profile => widget.account.value;

  @override
  void didUpdateWidget(_Account old) {
    super.didUpdateWidget(old);
    if (old.account.etag != widget.account.etag) {
      _name.text = _profile.displayName;
      _currency.text = _profile.displayCurrency;
      _locale = _profile.locale;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _currency.dispose();
    super.dispose();
  }

  Future<void> _save() {
    final l = AppLocalizations.of(context);
    return submit(() async {
      final name = _name.text.trim();
      final currency = _currency.text.trim().toUpperCase();
      final update = ProfileUpdate(
        displayName: name == _profile.displayName ? null : name,
        locale: _locale == _profile.locale ? null : _locale,
        displayCurrency: currency == _profile.displayCurrency ? null : currency,
      );
      if (update.toJson().isEmpty) return;
      try {
        await ref
            .read(apiTransportProvider)
            .updateProfile(update, etag: widget.account.etag);
        if (mounted) showNotice(context, l.accountSaved);
      } on ApiProblemException catch (e) {
        if (e.code != 'precondition.failed') rethrow;
        if (mounted) showNotice(context, l.accountConflict);
      } finally {
        ref.invalidate(accountProvider);
      }
    });
  }

  Future<void> _changeEmail(bool totp) async {
    final l = AppLocalizations.of(context);
    final changed = await showFormDialog<bool>(
      context,
      title: l.accountEmailChange,
      message: l.accountReauthHint,
      fields: [
        DialogField(
          key: emailNewFieldKey,
          label: l.accountEmailNew,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          validator: (v) => validateEmail(l, v),
        ),
        ..._reauthFields(l, totp: totp),
      ],
      action: l.accountEmailChange,
      run: (values) async {
        final factor = _secondFactor(values.elementAtOrNull(2));
        await ref
            .read(apiTransportProvider)
            .changeEmail(
              EmailChangeRequest(
                email: Email(values[0]),
                password: values[1],
                code: factor.code,
                recoveryCode: factor.recoveryCode,
              ),
              etag: widget.account.etag,
            );
        return true;
      },
    );
    if (changed ?? false) ref.invalidate(accountProvider);
  }

  Future<void> _delete(bool totp) async {
    final l = AppLocalizations.of(context);
    final email = _profile.email.value;
    await showFormDialog<bool>(
      context,
      title: l.accountDelete,
      message: l.accountDeleteWarning,
      fields: [
        ..._reauthFields(l, totp: totp),
        DialogField(
          key: deleteConfirmFieldKey,
          label: l.accountDeleteType(email),
        ),
      ],
      action: l.accountDelete,
      destructive: true,
      canSubmit: (v) => v.last == email && v.first.isNotEmpty,
      run: (values) async {
        final factor = _secondFactor(totp ? values[1] : null);
        await deleteAccount(
          ref,
          DeleteAccountRequest(
            password: values[0],
            code: factor.code,
            recoveryCode: factor.recoveryCode,
          ),
        );
        return true;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.fynonaColors;
    final error = this.error;
    final pending = _profile.pendingEmail;
    // While the TOTP status is unknown (loading or failed) the second-factor
    // field is offered; left empty it is not sent.
    final totp = ref.watch(totpStatusProvider).value?.enabled ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.accountProfile),
        SectionBody(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: accountNameKey,
                  controller: _name,
                  maxLength: 100,
                  decoration: InputDecoration(labelText: l.accountDisplayName),
                ),
                DropdownButtonFormField<api.Locale>(
                  key: accountLocaleKey,
                  initialValue: _locale,
                  decoration: InputDecoration(labelText: l.accountLocale),
                  items: [
                    for (final (value, label) in [
                      (api.Locale.uk, l.languageUk),
                      (api.Locale.ru, l.languageRu),
                      (api.Locale.en, l.languageEn),
                    ])
                      DropdownMenuItem(value: value, child: Text(label)),
                  ],
                  onChanged: (v) => setState(() => _locale = v ?? _locale),
                ),
                TextFormField(
                  key: accountCurrencyKey,
                  controller: _currency,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: l.accountCurrency),
                  validator: (v) =>
                      RegExp(r'^[A-Z]{3}$')
                          .hasMatch(v?.trim().toUpperCase() ?? '')
                      ? null
                      : l.accountCurrencyInvalid,
                ),
                if (error != null)
                  AuthMessage(authErrorText(l, error), error: true),
                AuthSubmitButton(
                  key: accountSaveKey,
                  label: l.commonSave,
                  busy: busy,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
        SectionTitle(l.accountEmail),
        ListTile(
          leading: const Icon(Icons.alternate_email_rounded),
          title: Text(_profile.email.value),
          subtitle: pending == null
              ? null
              : Text(
                  l.accountEmailPending(pending.value),
                  key: emailPendingKey,
                  style: TextStyle(color: colors.accentText),
                ),
          trailing: TextButton(
            key: emailChangeKey,
            onPressed: () => _changeEmail(totp),
            child: Text(l.accountEmailChange),
          ),
        ),
        SectionTitle(l.accountExport),
        const _Export(),
        SectionTitle(l.accountDanger),
        SectionBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.accountDeleteWarning,
                style: FynonaTypography.body.copyWith(
                  color: colors.contentSecondary,
                ),
              ),
              const SizedBox(height: FynonaTokens.space8),
              OutlinedButton(
                key: deleteAccountKey,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _delete(totp),
                child: Text(l.accountDelete),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Start an export, follow it while it runs and download the archive
/// (SEC-60).
class _Export extends ConsumerStatefulWidget {
  const _Export();

  @override
  ConsumerState<_Export> createState() => _ExportState();
}

class _ExportState extends ConsumerState<_Export> {
  /// Failed polls in a row after which polling stops until the user retries.
  static const _maxPollFailures = 3;

  /// The longest wait between polls after failures.
  static const _maxPollWait = Duration(minutes: 1);

  Export? _export;
  Object? _error;
  bool _busy = false;
  Timer? _poll;
  int _pollFailures = 0;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  bool get _pending =>
      _export?.status == const ExportStatusKnown(ExportStatusValue.pending);

  /// Polling of a pending export gave up after failures.
  bool get _pollStopped => _pollFailures >= _maxPollFailures;

  Future<void> _run(Future<Export> Function(ApiTransport t) call) async {
    _poll?.cancel();
    setState(() {
      _busy = true;
      _error = null;
    });
    Duration? retryAfter;
    try {
      final export = await call(ref.read(apiTransportProvider));
      if (!mounted) return;
      setState(() {
        _export = export;
        _pollFailures = 0;
      });
    } on Object catch (e) {
      if (!mounted) return;
      final (status, wait) = switch (e) {
        ApiProblemException(:final status, :final retryAfter) => (
          status,
          retryAfter,
        ),
        ApiHttpException(:final status, :final retryAfter) => (
          status,
          retryAfter,
        ),
        _ => (null, null),
      };
      retryAfter = wait;
      setState(() {
        _error = e;
        // 404: the export is gone; another one can be started.
        if (status == 404) _export = null;
        if (_pending) _pollFailures++;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_pending && !_pollStopped) {
          _poll = Timer(retryAfter ?? _pollWait(), _refresh);
        }
      }
    }
  }

  /// The poll interval, doubled for each failed poll in a row.
  Duration _pollWait() {
    final wait = ref.read(exportPollIntervalProvider) * (1 << _pollFailures);
    return wait > _maxPollWait ? _maxPollWait : wait;
  }

  Future<void> _retryPoll() {
    setState(() => _pollFailures = 0);
    return _refresh();
  }

  Future<void> _start() => _run(
    (t) => t.call(
      (api) => api.account.startExport(idempotencyKey: newIdempotencyKey()),
    ),
  );

  Future<void> _refresh() {
    final id = _export!.id;
    return _run((t) => t.call((api) => api.account.getExport(id: id)));
  }

  Future<void> _download() async {
    final l = AppLocalizations.of(context);
    final id = _export!.id;
    setState(() => _busy = true);
    try {
      final bytes = await ref
          .read(apiTransportProvider)
          .downloadExportArchive(id);
      final where = await ref.read(fileSaverProvider)(
        exportArchiveFileName(id),
        bytes,
        'application/json',
      );
      if (mounted) showNotice(context, l.commonSavedTo(where));
    } on ApiProblemException catch (e) {
      // 404: the archive expired in the meantime.
      if (e.status == 404) {
        await _refresh();
      } else if (mounted) {
        setState(() => _error = e);
      }
    } on Object {
      if (mounted) showNotice(context, l.commonSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final export = _export;
    final error = _error;
    final status = switch (export?.status) {
      ExportStatusKnown(:final value) => value,
      _ => null,
    };
    final (String text, Widget action) = switch (status) {
      null => (
        l.accountExportHint,
        FilledButton(
          key: exportStartKey,
          onPressed: _busy ? null : _start,
          child: Text(l.accountExportStart),
        ),
      ),
      ExportStatusValue.pending when _pollStopped => (
        l.accountExportPending,
        TextButton(
          key: exportRetryKey,
          onPressed: _busy ? null : _retryPoll,
          child: Text(l.commonRetry),
        ),
      ),
      ExportStatusValue.pending => (
        l.accountExportPending,
        const SizedBox.square(
          key: exportProgressKey,
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      ExportStatusValue.ready => (
        export!.expiresAt == null
            ? l.accountExportReady
            : l.accountExportReadyUntil(
                formatDateTime(context, export.expiresAt!),
              ),
        FilledButton(
          key: exportDownloadKey,
          onPressed: _busy ? null : _download,
          child: Text(l.accountExportDownload),
        ),
      ),
      ExportStatusValue.failed || ExportStatusValue.expired => (
        status == ExportStatusValue.failed
            ? l.accountExportFailed
            : l.accountExportExpired,
        FilledButton(
          key: exportStartKey,
          onPressed: _busy ? null : _start,
          child: Text(l.accountExportStart),
        ),
      ),
    };
    return SectionBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(liveRegion: true, child: Text(text)),
          if (error != null) AuthMessage(authErrorText(l, error), error: true),
          const SizedBox(height: FynonaTokens.space8),
          Align(alignment: AlignmentDirectional.centerStart, child: action),
        ],
      ),
    );
  }
}
