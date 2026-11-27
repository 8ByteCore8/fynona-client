import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/gen/app_localizations.dart';
import '../shell/profile_switcher.dart';

/// Key of the Операції header surface (work-zone tests measure it).
const operationsHeaderKey = ValueKey('operations-header');

/// Key of the Операції scroll view.
const operationsListKey = ValueKey('operations-list');

/// Placeholder rows until operations come from the API.
const placeholderOperationCount = 1000;

/// Операції placeholder: a collapsing header with the profile switcher and
/// one summary row, then the list (CLI-20, CLI-21). Nothing is pinned above
/// the list except the collapsed app bar.
class OperationsScreen extends StatelessWidget {
  const OperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.fynonaColors;
    final wide = !WindowSizeClass.of(MediaQuery.sizeOf(context).width)
        .usesBottomBar;
    return CustomScrollView(
      key: operationsListKey,
      slivers: [
        FynonaSliverHeader(
          surfaceKey: operationsHeaderKey,
          wide: wide,
          title: const ProfileSwitcher(),
          summary: Text(
            l.operationsSummary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FynonaTypography.headerLabel.copyWith(
              color: c.contentSecondary,
            ),
          ),
        ),
        SliverList.builder(
          itemCount: placeholderOperationCount,
          itemBuilder: (context, i) => PlaceholderOperationRow(number: i + 1),
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

/// A list row with placeholder text; read as one node.
class PlaceholderOperationRow extends StatelessWidget {
  const PlaceholderOperationRow({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.fynonaColors;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: FynonaTokens.spaceGutter + FynonaTokens.spaceRowInline,
          vertical: FynonaTokens.spaceRowBlock,
        ),
        child: Row(
          children: [
            Container(
              width: FynonaTokens.sizeAvatar,
              height: FynonaTokens.sizeAvatar,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surfaceContainerHigh,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: FynonaTokens.sizeAvatarIcon,
                color: c.contentSecondary,
              ),
            ),
            const SizedBox(width: FynonaTokens.spaceRowGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.operationsPlaceholderTitle(number),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FynonaTypography.rowTitle.copyWith(
                      color: c.contentPrimary,
                    ),
                  ),
                  Text(
                    l.operationsPlaceholderSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FynonaTypography.caption.copyWith(
                      color: c.contentSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
