import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/gen/app_localizations.dart';

/// A profile context of the switcher (CLI-11). Placeholder data until
/// profiles come from the API.
@immutable
class ProfileOption {
  const ProfileOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorOf,
  });

  /// Null for «all profiles».
  final String? id;
  final String Function(AppLocalizations l) name;
  final IconData icon;
  final Color Function(FynonaColors c) colorOf;
}

final profileOptionsProvider = Provider<List<ProfileOption>>(
  (ref) => [
    ProfileOption(
      id: null,
      name: (l) => l.profileAll,
      icon: Icons.layers_rounded,
      colorOf: (c) => c.accentBase,
    ),
    ProfileOption(
      id: 'personal',
      name: (l) => l.profilePlaceholderPersonal,
      icon: Icons.person_rounded,
      colorOf: (c) => c.profileColor1,
    ),
    ProfileOption(
      id: 'business',
      name: (l) => l.profilePlaceholderBusiness,
      icon: Icons.storefront_rounded,
      colorOf: (c) => c.profileColor2,
    ),
  ],
);

/// The selected profile id; null is «all profiles». Shared by Огляд,
/// Операції and Аналітика, so the choice is remembered across them.
class SelectedProfileNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedProfileProvider =
    NotifierProvider<SelectedProfileNotifier, String?>(
      SelectedProfileNotifier.new,
    );

/// Profile switcher slot at the top of Огляд, Операції, Аналітика.
class ProfileSwitcher extends ConsumerWidget {
  const ProfileSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final colors = context.fynonaColors;
    final options = ref.watch(profileOptionsProvider);
    final selectedId = ref.watch(selectedProfileProvider);
    final selected = options.firstWhere(
      (o) => o.id == selectedId,
      orElse: () => options.first,
    );
    final name = selected.name(l);
    return ProfileSwitcherButton(
      name: name,
      color: selected.colorOf(colors),
      icon: selected.icon,
      semanticLabel: l.profileSwitcherLabel(name),
      onPressed: () => _pick(context, ref, options, selectedId),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    List<ProfileOption> options,
    String? selectedId,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l = AppLocalizations.of(context);
      final colors = context.fynonaColors;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: FynonaTokens.spaceContentInset,
                vertical: FynonaTokens.space8,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l.profileSheetTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                leading: Icon(option.icon, color: option.colorOf(colors)),
                title: Text(option.name(l)),
                selected: option.id == selectedId,
                trailing: option.id == selectedId
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  ref.read(selectedProfileProvider.notifier).select(option.id);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      );
    },
  );
}
