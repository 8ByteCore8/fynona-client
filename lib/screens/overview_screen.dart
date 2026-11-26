import 'package:material_ui/material_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'placeholder_screen.dart';

/// Огляд placeholder (V1 layout lands with the dashboard API).
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) => ProfileScopedPlaceholder(
    text: AppLocalizations.of(context).overviewPlaceholder,
  );
}
