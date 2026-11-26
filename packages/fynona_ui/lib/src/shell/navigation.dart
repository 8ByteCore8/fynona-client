import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../glass/glass.dart';
import '../theme/fynona_theme.dart';
import '../tokens/tokens.g.dart';

/// One top-level destination of the bottom bar and the rail.
@immutable
class FynonaDestination {
  const FynonaDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.semanticLabel,
  });

  final IconData icon;
  final IconData selectedIcon;

  /// Visible label, also the large long-press label (CLI-24).
  final String label;

  /// Screen-reader name; [label] when null.
  final String? semanticLabel;
}

/// Key of the large label shown while a navigation item is long-pressed.
const navLargeLabelKey = ValueKey('fynona-nav-large-label');

/// Compact-window bottom bar (CLI-10): glass chrome, four equal items, labels
/// capped at `textScale.maxNavLabel`, long press shows a large label (CLI-24).
class FynonaNavBar extends StatelessWidget {
  const FynonaNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.semanticLabel,
  });

  final List<FynonaDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Name of the navigation landmark.
  final String? semanticLabel;

  static const double _paddingTop = 5;
  static const double _paddingBottom = 8;

  /// Height of the bar without the bottom safe-area inset.
  static double heightFor(TextScaler scaler) =>
      _paddingTop + _NavItem.contentHeight(scaler) + _paddingBottom;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final userScaler = MediaQuery.textScalerOf(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: GlassSurface(
        edge: GlassEdge.top,
        backdropAlignment: AlignmentDirectional.bottomCenter,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: FynonaTokens.textScaleMaxNavLabel,
          child: Material(
            type: MaterialType.transparency,
            child: Builder(
              builder: (context) => Padding(
                padding: EdgeInsetsDirectional.only(
                  top: _paddingTop,
                  bottom: _paddingBottom + bottomInset,
                  start: FynonaTokens.space4,
                  end: FynonaTokens.space4,
                ),
                child: SizedBox(
                  height: _NavItem.contentHeight(
                    MediaQuery.textScalerOf(context),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Expanded(
                          child: _NavItem(
                            destination: destinations[i],
                            selected: i == selectedIndex,
                            onTap: () => onSelected(i),
                            largeLabelScaler: userScaler,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rail for medium and wider windows (CLI-13): the same items stacked.
class FynonaNavRail extends StatelessWidget {
  const FynonaNavRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.leading,
    this.semanticLabel,
  });

  final List<FynonaDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget? leading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final userScaler = MediaQuery.textScalerOf(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: GlassSurface(
        edge: GlassEdge.end,
        backdropAlignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: FynonaTokens.sizeRailWidth,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: FynonaTokens.textScaleMaxNavLabel,
            child: Material(
              type: MaterialType.transparency,
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.only(
                  top: padding.top + FynonaTokens.space12,
                  bottom: padding.bottom + FynonaTokens.space12,
                ),
                child: Column(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(height: FynonaTokens.space16),
                    ],
                    for (var i = 0; i < destinations.length; i++)
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: FynonaTokens.space4,
                          horizontal: FynonaTokens.space4,
                        ),
                        child: _NavItem(
                          destination: destinations[i],
                          selected: i == selectedIndex,
                          onTap: () => onSelected(i),
                          largeLabelScaler: userScaler,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.largeLabelScaler,
  });

  final FynonaDestination destination;
  final bool selected;
  final VoidCallback onTap;

  /// The user's text scaler before the nav-label cap.
  final TextScaler largeLabelScaler;

  static const double _gap = 2;

  static double _labelLine(TextScaler scaler) =>
      (scaler.scale(FynonaTokens.fontSizeNav) * FynonaTokens.fontLineHeightBody)
          .ceilToDouble() +
      1;

  /// Pill, gap and one label line at the (already capped) [scaler].
  static double contentHeight(TextScaler scaler) =>
      FynonaTokens.sizeNavPillHeight + _gap + _labelLine(scaler);

  @override
  Widget build(BuildContext context) {
    final c = context.fynonaColors;
    final scaler = MediaQuery.textScalerOf(context);
    final visual = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? FynonaTokens.motionDurationReduced
              : FynonaTokens.motionDurationFast,
          width: FynonaTokens.sizeNavPillWidth,
          height: FynonaTokens.sizeNavPillHeight,
          decoration: BoxDecoration(
            color: selected ? c.accentContainer : const Color(0x00000000),
            borderRadius: BorderRadius.circular(FynonaTokens.radiusNavPill),
          ),
          child: Icon(
            selected ? destination.selectedIcon : destination.icon,
            size: FynonaTokens.sizeIconMd,
            color: selected ? c.accentOnContainer : c.contentSecondary,
          ),
        ),
        const SizedBox(height: _gap),
        SizedBox(
          height: _labelLine(scaler),
          child: Text(
            destination.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: FynonaTypography.navLabel.copyWith(
              color: selected ? c.contentPrimary : c.contentSecondary,
            ),
          ),
        ),
      ],
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: destination.semanticLabel ?? destination.label,
      child: _LongPressLabel(
        label: destination.label,
        scaler: largeLabelScaler,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FynonaTokens.radiusRow),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: FynonaTokens.sizeTouchTarget,
              minHeight: FynonaTokens.sizeTouchTarget,
            ),
            child: ExcludeSemantics(child: Center(child: visual)),
          ),
        ),
      ),
    );
  }
}

/// Shows [label] large above [child] while it is long-pressed (CLI-24); the
/// tap still belongs to the child. Visual only: the item's accessible name
/// already carries the label.
class _LongPressLabel extends StatefulWidget {
  const _LongPressLabel({
    required this.label,
    required this.scaler,
    required this.child,
  });

  final String label;
  final TextScaler scaler;
  final Widget child;

  @override
  State<_LongPressLabel> createState() => _LongPressLabelState();
}

class _LongPressLabelState extends State<_LongPressLabel> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();

  void _show() => _portal.show();

  void _hide() {
    if (_portal.isShowing) _portal.hide();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fynonaColors;
    return RawGestureDetector(
      excludeFromSemantics: true,
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: FynonaTokens.gestureLongPress,
              ),
              (r) => r
                ..onLongPressStart = ((_) => _show())
                ..onLongPressEnd = ((_) => _hide())
                ..onLongPressCancel = _hide,
            ),
      },
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) => CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -FynonaTokens.space8),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: ExcludeSemantics(
                child: IgnorePointer(
                  // The large label grows with the user's text scale up to
                  // `textScale.maxBody`, unlike the capped item label.
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: widget.scaler.clamp(
                        maxScaleFactor: FynonaTokens.textScaleMaxBody,
                      ),
                    ),
                    child: DecoratedBox(
                      key: navLargeLabelKey,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          c.surfaceSheetTint,
                          c.surfaceContainerHigh,
                        ),
                        borderRadius: BorderRadius.circular(
                          FynonaTokens.radiusRow,
                        ),
                        boxShadow: const [
                          // elevation.floating
                          BoxShadow(
                            color: FynonaShadowColors.medium,
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: FynonaTokens.space16,
                          vertical: FynonaTokens.space10,
                        ),
                        child: Text(
                          widget.label,
                          style: FynonaTypography.rowTitle.copyWith(
                            color: c.contentPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
