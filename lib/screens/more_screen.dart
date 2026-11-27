import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth.dart';
import '../l10n/gen/app_localizations.dart';
import '../settings/appearance.dart';
import '../shell/router.dart';

/// Key of the sign-out entry.
const signOutKey = ValueKey('more-sign-out');

/// Key of the entry that opens [path].
ValueKey<String> moreEntryKey(String path) => ValueKey('more-entry-$path');

/// Ще (CLI-12): section entries (placeholders until their stage), account,
/// subscription and security, and the appearance switches.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.fynonaColors;
    final appearance = ref.watch(appearanceProvider);
    final wide = !WindowSizeClass.of(MediaQuery.sizeOf(context).width)
        .usesBottomBar;
    void comingSoon() =>
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.comingSoon)));
    final sections = <(IconData, String, String?)>[
      (Icons.account_circle_outlined, l.moreProfiles, null),
      (Icons.account_balance_outlined, l.moreConnections, null),
      (Icons.category_outlined, l.moreCategories, null),
      (Icons.fact_check_outlined, l.moreReconciliation, null),
      (Icons.trending_up_rounded, l.moreInvestments, null),
      (Icons.file_download_outlined, l.moreExports, null),
      (Icons.workspace_premium_outlined, l.moreSubscription, subscriptionPath),
      (Icons.person_outline_rounded, l.moreAccount, accountPath),
      (Icons.shield_outlined, l.moreSecurity, securityPath),
      (Icons.info_outline_rounded, l.moreAbout, null),
    ];
    return CustomScrollView(
      slivers: [
        FynonaSliverHeader(
          wide: wide,
          title: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: FynonaTokens.space8,
            ),
            child: Semantics(
              header: true,
              child: Text(
                l.navMore,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FynonaTypography.title.copyWith(color: c.contentPrimary),
              ),
            ),
          ),
        ),
        SliverList.list(
          children: [
            for (final (icon, title, path) in sections)
              ListTile(
                key: path == null ? null : moreEntryKey(path),
                leading: Icon(icon),
                title: Text(title),
                onTap: path == null ? comingSoon : () => context.go(path),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: FynonaTokens.spaceContentInset,
                end: FynonaTokens.spaceContentInset,
                top: FynonaTokens.space16,
                bottom: FynonaTokens.space4,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l.moreAppearance,
                  style: FynonaTypography.sectionTitle.copyWith(
                    color: c.contentPrimary,
                  ),
                ),
              ),
            ),
            SwitchListTile(
              title: Text(l.settingsNoGlass),
              subtitle: Text(l.settingsNoGlassHint),
              value: appearance.noGlass,
              onChanged: ref.read(appearanceProvider.notifier).setNoGlass,
            ),
            SwitchListTile(
              title: Text(l.settingsHighContrast),
              value: appearance.highContrast,
              onChanged: ref.read(appearanceProvider.notifier).setHighContrast,
            ),
            ListTile(
              key: signOutKey,
              leading: const Icon(Icons.logout_rounded),
              title: Text(l.authSignOut),
              onTap: ref.read(authStateProvider.notifier).signOut,
            ),
          ],
        ),
        SliverPadding(
          padding: EdgeInsetsDirectional.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
        ),
      ],
    );
  }
}
