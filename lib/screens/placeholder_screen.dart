import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../shell/profile_switcher.dart';

/// A top-level screen with the profile switcher header and placeholder text
/// (Огляд, Аналітика until their content lands).
class ProfileScopedPlaceholder extends StatelessWidget {
  const ProfileScopedPlaceholder({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.fynonaColors;
    final wide = !WindowSizeClass.of(MediaQuery.sizeOf(context).width)
        .usesBottomBar;
    return CustomScrollView(
      slivers: [
        FynonaSliverHeader(wide: wide, title: const ProfileSwitcher()),
        SliverPadding(
          padding: EdgeInsetsDirectional.only(
            start: FynonaTokens.spaceContentInset,
            end: FynonaTokens.spaceContentInset,
            top: FynonaTokens.space24,
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              text,
              style: FynonaTypography.body.copyWith(color: c.contentSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
