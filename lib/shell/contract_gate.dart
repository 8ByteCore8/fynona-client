import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../api/contract.dart';
import '../l10n/gen/app_localizations.dart';
import 'reload.dart';

/// Key of the blocking «the app is out of date» screen.
const appOutdatedKey = ValueKey('contract-app-outdated');

/// Key of the blocking «the service is updating» screen.
const serverBehindKey = ValueKey('contract-server-behind');

/// Key of the web reload button on [appOutdatedKey].
const reloadButtonKey = ValueKey('contract-reload');

/// Key of the retry button on [serverBehindKey].
const retryButtonKey = ValueKey('contract-retry');

/// Whether the app runs in a browser; a provider so tests can switch it.
final isWebProvider = Provider<bool>((ref) => kIsWeb);

/// Shows [child] while the API contract is compatible and a blocking
/// full-screen state instead of it otherwise (API-12): nothing of the app
/// stays mounted behind either screen.
class ContractGate extends ConsumerWidget {
  const ContractGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return switch (ref.watch(contractStatusProvider)) {
      ContractCompatibility.compatible => child,
      ContractCompatibility.clientOutdated => _BlockingScreen(
        key: appOutdatedKey,
        icon: Icons.system_update_rounded,
        title: l.appOutdatedTitle,
        message: l.appOutdatedMessage,
        action: ref.watch(isWebProvider)
            ? (
                key: reloadButtonKey,
                label: l.appOutdatedReload,
                run: reloadPage,
              )
            : null,
      ),
      ContractCompatibility.serverBehind => _BlockingScreen(
        key: serverBehindKey,
        icon: Icons.construction_rounded,
        title: l.serverBehindTitle,
        message: l.serverBehindMessage,
        action: (
          key: retryButtonKey,
          label: l.serverBehindRetry,
          run: ref.read(contractStatusProvider.notifier).check,
        ),
      ),
    };
  }
}

class _BlockingScreen extends StatelessWidget {
  const _BlockingScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final ({Key key, String label, VoidCallback run})? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.fynonaColors;
    final action = this.action;
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: colors.accentText),
                  const SizedBox(height: FynonaTokens.space16),
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
                  const SizedBox(height: FynonaTokens.space8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: FynonaTypography.body.copyWith(
                      color: colors.contentSecondary,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: FynonaTokens.space24),
                    FilledButton(
                      key: action.key,
                      onPressed: action.run,
                      child: Text(action.label),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
