import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/gen/app_localizations.dart';
import '../settings/appearance.dart';

/// Ще (CLI-12): section entries (placeholders) and the appearance switches.
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
    final sections = [
      (Icons.account_circle_outlined, l.moreProfiles),
      (Icons.account_balance_outlined, l.moreConnections),
      (Icons.category_outlined, l.moreCategories),
      (Icons.fact_check_outlined, l.moreReconciliation),
      (Icons.trending_up_rounded, l.moreInvestments),
      (Icons.file_download_outlined, l.moreExports),
      (Icons.workspace_premium_outlined, l.moreSubscription),
      (Icons.shield_outlined, l.moreSecurity),
      (Icons.info_outline_rounded, l.moreAbout),
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
            for (final (icon, title) in sections)
              ListTile(
                leading: Icon(icon),
                title: Text(title),
                onTap: comingSoon,
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
