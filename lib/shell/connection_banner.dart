import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../api/api.dart';
import '../l10n/gen/app_localizations.dart';

/// Key of the «no connection» banner.
const connectionBannerKey = ValueKey('shell-connection-banner');

/// Placeholder «no connection» banner, shown while a circuit breaker of the
/// API transport is open (API-63). Cached data and «Retry» come with M2.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineProvider).value ?? false;
    if (!offline) return const SizedBox.shrink();
    final colors = context.fynonaColors;
    final l = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(FynonaTokens.space8),
        child: Semantics(
          liveRegion: true,
          child: DecoratedBox(
            key: connectionBannerKey,
            decoration: BoxDecoration(
              color: colors.statusWarningContainer,
              borderRadius: BorderRadius.circular(FynonaTokens.radiusRow),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: FynonaTokens.space16,
                vertical: FynonaTokens.space10,
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_off_rounded, color: colors.statusWarning),
                  const SizedBox(width: FynonaTokens.space10),
                  Expanded(
                    child: Text(
                      l.connectionLost,
                      style: FynonaTypography.body.copyWith(
                        color: colors.contentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
