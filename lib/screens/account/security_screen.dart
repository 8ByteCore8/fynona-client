import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;
import 'package:fynona_ui/fynona_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../account/account.dart';
import '../../api/api.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shell/router.dart';
import '../auth/auth_widgets.dart';
import 'account_widgets.dart';

const revokeOtherSessionsKey = ValueKey('sessions-revoke-others');
const totpEnableKey = ValueKey('totp-enable');
const totpDisableKey = ValueKey('totp-disable');
const totpRegenerateKey = ValueKey('totp-regenerate');
const totpCodeFieldKey = ValueKey('totp-code-field');
const totpPasswordFieldKey = ValueKey('totp-password-field');
const passkeyAddKey = ValueKey('passkey-add');
const passkeyNameFieldKey = ValueKey('passkey-name-field');

/// Key of the session row with [id].
ValueKey<String> sessionTileKey(String id) => ValueKey('session-$id');

/// Key of the «end session» button of the session [id].
ValueKey<String> sessionRevokeKey(String id) => ValueKey('session-revoke-$id');

/// Key of the «delete» button of the passkey [id].
ValueKey<String> passkeyDeleteKey(String id) => ValueKey('passkey-delete-$id');

/// Ще → Безпека (CLI-12): sessions, two-factor authentication and, on web,
/// passkeys (SEC-1, SEC-2, SEC-4).
class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final passkeys = ref.watch(passkeyRegistrarProvider) != null;
    return SettingsPage(
      title: l.moreSecurity,
      children: [
        SectionTitle(l.securitySessions),
        AsyncSection(
          provider: sessionsProvider,
          data: (sessions) => _Sessions(sessions: sessions),
        ),
        SectionTitle(l.securityTotp),
        AsyncSection(
          provider: totpStatusProvider,
          data: (status) => _Totp(status: status),
        ),
        if (passkeys) ...[
          SectionTitle(l.securityPasskeys),
          AsyncSection(
            provider: passkeysProvider,
            data: (items) => _Passkeys(passkeys: items),
          ),
        ],
      ],
    );
  }
}

class _Sessions extends ConsumerWidget {
  const _Sessions({required this.sessions});

  final List<Session> sessions;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Iterable<Session> targets,
  ) async {
    final l = AppLocalizations.of(context);
    final transport = ref.read(apiTransportProvider);
    try {
      for (final session in targets) {
        await transport.call(
          (api) => api.sessions.revokeSession(
            id: session.id,
            idempotencyKey: newIdempotencyKey(),
          ),
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) showNotice(context, authErrorText(l, error));
    } finally {
      ref.invalidate(sessionsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final others = [
      for (final s in sessions)
        if (!s.current) s,
    ];
    return Column(
      children: [
        for (final session in sessions)
          ListTile(
            key: sessionTileKey(session.id),
            leading: Icon(
              session.current
                  ? Icons.smartphone_rounded
                  : Icons.devices_other_rounded,
            ),
            title: Text(
              session.device.isNotEmpty
                  ? session.device
                  : session.userAgent.isNotEmpty
                  ? session.userAgent
                  : l.securitySessionUnknownDevice,
            ),
            subtitle: Text(
              [
                if (session.current) l.securitySessionThisDevice,
                if (session.ip case final ip? when ip.isNotEmpty) ip,
                l.securitySessionLastUsed(
                  formatDateTime(context, session.lastUsedAt),
                ),
              ].join(' · '),
            ),
            trailing: session.current
                ? null
                : IconButton(
                    key: sessionRevokeKey(session.id),
                    tooltip: l.securitySessionRevoke,
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () => _run(context, ref, [session]),
                  ),
          ),
        if (others.isNotEmpty)
          SectionBody(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: revokeOtherSessionsKey,
                icon: const Icon(Icons.phonelink_erase_rounded),
                label: Text(l.securitySessionsRevokeOthers),
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    message: l.securitySessionsRevokeOthersConfirm,
                    action: l.securitySessionsRevokeOthers,
                  );
                  if (ok && context.mounted) await _run(context, ref, others);
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _Totp extends ConsumerWidget {
  const _Totp({required this.status});

  final TotpStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final transport = ref.read(apiTransportProvider);
    final codeField = DialogField(
      key: totpCodeFieldKey,
      label: l.securityTotpCode,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
    );
    if (!status.enabled) {
      return ListTile(
        leading: const Icon(Icons.lock_open_rounded),
        title: Text(l.securityTotpOff),
        subtitle: Text(l.securityTotpOffHint),
        trailing: FilledButton(
          key: totpEnableKey,
          onPressed: () => context.go(totpSetupPath),
          child: Text(l.securityTotpEnable),
        ),
      );
    }
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.verified_user_rounded),
          title: Text(l.securityTotpOn),
          subtitle: Text(l.securityRecoveryCodesLeft(status.recoveryCodesLeft)),
        ),
        SectionBody(
          child: Wrap(
            spacing: FynonaTokens.space8,
            children: [
              OutlinedButton(
                key: totpRegenerateKey,
                onPressed: () async {
                  final codes = await showFormDialog<List<String>>(
                    context,
                    title: l.securityTotpRegenerate,
                    message: l.securityTotpRegenerateHint,
                    fields: [
                      DialogField(
                        key: codeField.key,
                        label: codeField.label,
                        keyboardType: codeField.keyboardType,
                        autofillHints: codeField.autofillHints,
                        validator: (v) => validateTotpCode(l, v),
                      ),
                    ],
                    action: l.commonConfirm,
                    run: (values) async {
                      final result = await transport.call(
                        (api) => api.auth.regenerateRecoveryCodes(
                          body: TotpCodeRequest(code: TotpCode(values[0])),
                        ),
                      );
                      return result.codes;
                    },
                  );
                  ref.invalidate(totpStatusProvider);
                  if (codes != null && context.mounted) {
                    await showRecoveryCodes(context, codes);
                  }
                },
                child: Text(l.securityTotpRegenerate),
              ),
              TextButton(
                key: totpDisableKey,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  final done = await showFormDialog<bool>(
                    context,
                    title: l.securityTotpDisable,
                    message: l.securityTotpDisableConfirm,
                    fields: [
                      codeField,
                      DialogField(
                        key: totpPasswordFieldKey,
                        label: l.securityTotpOrPassword,
                        obscure: true,
                        autofillHints: const [AutofillHints.password],
                      ),
                    ],
                    action: l.securityTotpDisable,
                    destructive: true,
                    canSubmit: (v) => v[0].isNotEmpty != v[1].isNotEmpty,
                    run: (values) async {
                      await transport.call(
                        (api) => api.auth.disableTotp(
                          body: values[0].isNotEmpty
                              ? TotpDisableRequest(code: TotpCode(values[0]))
                              : TotpDisableRequest(password: values[1]),
                        ),
                      );
                      return true;
                    },
                  );
                  if (done ?? false) ref.invalidate(totpStatusProvider);
                },
                child: Text(l.securityTotpDisable),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Passkeys extends ConsumerWidget {
  const _Passkeys({required this.passkeys});

  final List<Passkey> passkeys;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final transport = ref.read(apiTransportProvider);
    final register = ref.read(passkeyRegistrarProvider)!;
    final added = await showFormDialog<Passkey>(
      context,
      title: l.securityPasskeyAdd,
      fields: [
        DialogField(key: passkeyNameFieldKey, label: l.securityPasskeyName),
      ],
      action: l.securityPasskeyAdd,
      run: (values) async {
        final ceremony = await transport.call(
          (api) => api.auth.beginPasskeyRegistration(),
        );
        final credential = await register(ceremony.options);
        return transport.call(
          (api) => api.auth.finishPasskeyRegistration(
            body: PasskeyRegistration(
              ceremonyId: ceremony.ceremonyId,
              name: values[0].isEmpty ? null : values[0],
              credential: credential,
            ),
          ),
        );
      },
    );
    if (added != null) ref.invalidate(passkeysProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Passkey key) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmAction(
      context,
      message: l.securityPasskeyDeleteConfirm(key.name),
      action: l.commonDelete,
    );
    if (!ok) return;
    try {
      await ref
          .read(apiTransportProvider)
          .call((api) => api.auth.deletePasskey(id: key.id));
    } on ApiException catch (error) {
      if (context.mounted) showNotice(context, authErrorText(l, error));
    }
    ref.invalidate(passkeysProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        if (passkeys.isEmpty) ListTile(title: Text(l.securityPasskeysEmpty)),
        for (final key in passkeys)
          ListTile(
            leading: const Icon(Icons.key_rounded),
            title: Text(key.name),
            subtitle: Text(
              l.securityPasskeyCreated(formatDateTime(context, key.createdAt)),
            ),
            trailing: IconButton(
              key: passkeyDeleteKey(key.id),
              tooltip: l.commonDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _delete(context, ref, key),
            ),
          ),
        SectionBody(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: passkeyAddKey,
              icon: const Icon(Icons.add_rounded),
              label: Text(l.securityPasskeyAdd),
              onPressed: () => _add(context, ref),
            ),
          ),
        ),
      ],
    );
  }
}
