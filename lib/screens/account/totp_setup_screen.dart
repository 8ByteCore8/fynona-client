import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;
import 'package:fynona_ui/fynona_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr/qr.dart';

import '../../account/account.dart';
import '../../api/api.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shell/router.dart';
import '../auth/auth_widgets.dart';
import 'account_widgets.dart';

const totpQrKey = ValueKey('totp-qr');
const totpSecretKey = ValueKey('totp-secret');
const totpSecretCopyKey = ValueKey('totp-secret-copy');
const totpSetupCodeKey = ValueKey('totp-setup-code');
const totpSetupSubmitKey = ValueKey('totp-setup-submit');
const totpSetupDoneKey = ValueKey('totp-setup-done');

/// Turns TOTP on (SEC-2): a new secret as a QR code and a manual key, a first
/// code to confirm, then the recovery codes, shown once.
class TotpSetupScreen extends ConsumerStatefulWidget {
  const TotpSetupScreen({super.key});

  @override
  ConsumerState<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends ConsumerState<TotpSetupScreen>
    with AuthFormState {
  final _code = TextEditingController();

  /// The secret and its otpauth URI, dropped once a code confirms them.
  Future<TotpEnrollment>? _enrollment;
  List<String>? _codes;

  @override
  void initState() {
    super.initState();
    _enrollment = _enroll();
  }

  Future<TotpEnrollment> _enroll() =>
      ref.read(apiTransportProvider).call((api) => api.auth.enrollTotp());

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() => submit(() async {
    final codes = await ref
        .read(apiTransportProvider)
        .call(
          (api) => api.auth.verifyTotp(
            body: TotpCodeRequest(code: TotpCode(_code.text.trim())),
          ),
        );
    ref.invalidate(totpStatusProvider);
    _code.clear();
    if (mounted) {
      setState(() {
        _enrollment = null;
        _codes = codes.codes;
      });
    }
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final codes = _codes;
    return SettingsPage(
      title: codes == null ? l.totpSetupTitle : l.recoveryCodesTitle,
      children: [
        SectionBody(
          child: codes != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: FynonaTokens.space16),
                    RecoveryCodesView(codes: codes),
                    const SizedBox(height: FynonaTokens.space24),
                    FilledButton(
                      key: totpSetupDoneKey,
                      onPressed: () => context.go(securityPath),
                      child: Text(l.commonDone),
                    ),
                  ],
                )
              : FutureBuilder(
                  future: _enrollment,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          AuthMessage(
                            authErrorText(l, snapshot.error!),
                            error: true,
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _enrollment = _enroll()),
                            child: Text(l.commonRetry),
                          ),
                        ],
                      );
                    }
                    final enrollment = snapshot.data;
                    if (enrollment == null) {
                      return const Padding(
                        padding: EdgeInsetsDirectional.all(
                          FynonaTokens.space24,
                        ),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _form(context, l, enrollment);
                  },
                ),
        ),
      ],
    );
  }

  Widget _form(
    BuildContext context,
    AppLocalizations l,
    TotpEnrollment enrollment,
  ) {
    final colors = context.fynonaColors;
    final error = this.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: FynonaTokens.space16),
        Text(
          l.totpSetupScan,
          style: FynonaTypography.body.copyWith(color: colors.contentSecondary),
        ),
        const SizedBox(height: FynonaTokens.space16),
        Center(
          child: Semantics(
            label: l.totpSetupQrLabel,
            image: true,
            child: QrCodeView(key: totpQrKey, data: enrollment.otpauthUri),
          ),
        ),
        const SizedBox(height: FynonaTokens.space16),
        Text(
          l.totpSetupManualKey,
          style: FynonaTypography.body.copyWith(color: colors.contentSecondary),
        ),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                enrollment.secret,
                key: totpSecretKey,
                style: FynonaTypography.body.copyWith(
                  color: colors.contentPrimary,
                ),
              ),
            ),
            IconButton(
              key: totpSecretCopyKey,
              tooltip: l.commonCopy,
              icon: const Icon(Icons.copy_rounded),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: enrollment.secret));
                if (context.mounted) showNotice(context, l.commonCopied);
              },
            ),
          ],
        ),
        Form(
          key: formKey,
          child: TextFormField(
            key: totpSetupCodeKey,
            controller: _code,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            onFieldSubmitted: (_) => _verify(),
            decoration: InputDecoration(labelText: l.securityTotpCode),
            validator: (v) => validateTotpCode(l, v?.trim() ?? ''),
          ),
        ),
        if (error != null) AuthMessage(authErrorText(l, error), error: true),
        AuthSubmitButton(
          key: totpSetupSubmitKey,
          label: l.commonConfirm,
          busy: busy,
          onPressed: _verify,
        ),
      ],
    );
  }
}

/// [data] as a QR code, dark modules on a light quiet zone so any camera
/// reads it in either theme.
class QrCodeView extends StatelessWidget {
  const QrCodeView({super.key, required this.data, this.size = 200});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFFFFFFF),
    padding: const EdgeInsetsDirectional.all(FynonaTokens.space12),
    child: CustomPaint(
      size: Size.square(size),
      painter: _QrPainter(
        QrImage(
          QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
        ),
      ),
    ),
  );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final QrImage image;

  @override
  void paint(Canvas canvas, Size size) {
    final count = image.moduleCount;
    final module = size.width / count;
    final paint = Paint()..color = const Color(0xFF000000);
    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (image.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(col * module, row * module, module, module),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.image != image;
}
