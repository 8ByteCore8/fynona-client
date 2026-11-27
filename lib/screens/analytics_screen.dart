import 'package:material_ui/material_ui.dart';

import '../l10n/gen/app_localizations.dart';
import 'placeholder_screen.dart';

/// Аналітика placeholder.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) => ProfileScopedPlaceholder(
    text: AppLocalizations.of(context).analyticsPlaceholder,
  );
}
