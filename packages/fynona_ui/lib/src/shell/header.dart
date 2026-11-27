import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../glass/glass.dart';
import '../tokens/tokens.g.dart';

/// Pinned, collapsing glass header of a list screen (CLI-21): one app-bar
/// row (profile switcher or title) and at most one compact summary row that
/// fades out while the list scrolls. Header text is capped at
/// `textScale.maxHeader` (CLI-24).
class FynonaSliverHeader extends StatelessWidget {
  const FynonaSliverHeader({
    super.key,
    required this.title,
    this.summary,
    this.surfaceKey,
    this.wide = false,
  });

  /// The app-bar row content, for example the profile switcher.
  final Widget title;

  /// Optional compact summary row (balance and filters in one line).
  final Widget? summary;

  /// Key of the header's glass surface (used to measure the work zone).
  final Key? surfaceKey;

  /// Medium and wider windows use `size.appBarWide`.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: FynonaTokens.textScaleMaxHeader);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderDelegate(
        title: title,
        summary: summary,
        surfaceKey: surfaceKey,
        topPadding: MediaQuery.paddingOf(context).top,
        barHeight: wide ? FynonaTokens.sizeAppBarWide : FynonaTokens.sizeAppBar,
        summaryHeight: summary == null ? 0 : summaryHeightFor(scaler),
      ),
    );
  }

  /// Height of the summary row at the (capped) [scaler].
  static double summaryHeightFor(TextScaler scaler) =>
      (scaler.scale(FynonaTokens.fontSizeLabel) *
              FynonaTokens.fontLineHeightBody)
          .ceilToDouble() +
      2 * FynonaTokens.space8;
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.title,
    required this.summary,
    required this.surfaceKey,
    required this.topPadding,
    required this.barHeight,
    required this.summaryHeight,
  });

  final Widget title;
  final Widget? summary;
  final Key? surfaceKey;
  final double topPadding;
  final double barHeight;
  final double summaryHeight;

  @override
  double get minExtent => topPadding + FynonaTokens.sizeAppBarCollapsed;

  @override
  double get maxExtent => topPadding + barHeight + summaryHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = math.max(1.0, maxExtent - minExtent);
    final t = (shrinkOffset / range).clamp(0.0, 1.0);
    final bar = math.max(
      FynonaTokens.sizeAppBarCollapsed,
      barHeight - shrinkOffset,
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: FynonaTokens.textScaleMaxHeader,
      child: GlassSurface(
        key: surfaceKey,
        edge: GlassEdge.bottom,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: topPadding,
              start: FynonaTokens.space12,
              end: FynonaTokens.space12,
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  height: bar,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: title,
                  ),
                ),
                if (summary != null)
                  PositionedDirectional(
                    top: bar,
                    start: FynonaTokens.space8,
                    end: FynonaTokens.space8,
                    height: summaryHeight,
                    child: Opacity(
                      opacity: 1 - t,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: summary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) =>
      old.title != title ||
      old.summary != summary ||
      old.surfaceKey != surfaceKey ||
      old.topPadding != topPadding ||
      old.barHeight != barHeight ||
      old.summaryHeight != summaryHeight;
}

/// Profile context switcher for the app bar (CLI-11): avatar in the profile
/// colour, name, chevron. One merged button node named [semanticLabel].
class ProfileSwitcherButton extends StatelessWidget {
  const ProfileSwitcherButton({
    super.key,
    required this.name,
    required this.color,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String name;

  /// One of `profile.color1…5`.
  final Color color;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FynonaTokens.sizeTouchTarget,
          ),
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: FynonaTokens.space4,
                end: FynonaTokens.space8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: FynonaTokens.sizeProfileAvatar,
                    height: FynonaTokens.sizeProfileAvatar,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(
                        alpha: FynonaTokens.opacityProfileTint,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: FynonaTokens.sizeIconSm,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: FynonaTokens.space8),
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FynonaTypography.profileName.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: FynonaTokens.sizeIconMd,
                    color: theme.colorScheme.onSurfaceVariant,
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
