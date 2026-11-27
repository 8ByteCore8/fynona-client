import 'package:flutter/rendering.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'connection_banner.dart';

/// Key of the compact bottom bar (work-zone tests measure it).
const navBarKey = ValueKey('shell-nav-bar');

/// Key of the wide-window rail.
const navRailKey = ValueKey('shell-nav-rail');

/// The app frame: background art, the current branch and the navigation —
/// bottom bar on compact windows (hidden while a list scrolls down, CLI-21),
/// rail on wider ones (CLI-13).
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _barHidden = false;

  void _select(int index) {
    setState(() => _barHidden = false);
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  bool _onUserScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final hide = switch (n.direction) {
      ScrollDirection.reverse => true,
      ScrollDirection.forward => false,
      ScrollDirection.idle => _barHidden,
    };
    if (hide != _barHidden) setState(() => _barHidden = hide);
    return false;
  }

  List<FynonaDestination> _destinations(AppLocalizations l) => [
    FynonaDestination(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: l.navOverview,
    ),
    FynonaDestination(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      label: l.navOperations,
    ),
    FynonaDestination(
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      label: l.navAnalytics,
    ),
    FynonaDestination(
      icon: Icons.more_horiz_rounded,
      selectedIcon: Icons.more_horiz_rounded,
      label: l.navMore,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final destinations = _destinations(l);
    final index = widget.navigationShell.currentIndex;
    final sizeClass = WindowSizeClass.of(MediaQuery.sizeOf(context).width);
    final body = Material(
      type: MaterialType.transparency,
      child: widget.navigationShell,
    );

    final Widget frame;
    if (sizeClass.usesBottomBar) {
      final mq = MediaQuery.of(context);
      final barHeight = FynonaNavBar.heightFor(
        mq.textScaler.clamp(maxScaleFactor: FynonaTokens.textScaleMaxNavLabel),
      );
      frame = Stack(
        children: [
          const Positioned.fill(child: FynonaBackground()),
          NotificationListener<UserScrollNotification>(
            onNotification: _onUserScroll,
            // Lists end above the overlaid bar.
            child: MediaQuery(
              data: mq.copyWith(
                padding: mq.padding.copyWith(
                  bottom: mq.padding.bottom + barHeight,
                ),
              ),
              child: body,
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: AnimatedSlide(
              offset: _barHidden ? const Offset(0, 1) : Offset.zero,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? FynonaTokens.motionDurationReduced
                  : FynonaTokens.motionDurationStandard,
              curve: Curves.ease,
              child: FynonaNavBar(
                key: navBarKey,
                destinations: destinations,
                selectedIndex: index,
                onSelected: _select,
                semanticLabel: l.navLandmark,
              ),
            ),
          ),
        ],
      );
    } else {
      frame = Stack(
        children: [
          const Positioned.fill(child: FynonaBackground()),
          Row(
            children: [
              FynonaNavRail(
                key: navRailKey,
                destinations: destinations,
                selectedIndex: index,
                onSelected: _select,
                semanticLabel: l.navLandmark,
              ),
              Expanded(child: body),
            ],
          ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: const Color(0x00000000),
      body: Stack(
        children: [
          frame,
          const PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: ConnectionBanner(),
          ),
        ],
      ),
    );
  }
}
