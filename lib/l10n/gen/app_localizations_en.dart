// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fynona';

  @override
  String get navOverview => 'Overview';

  @override
  String get navOperations => 'Operations';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navMore => 'More';

  @override
  String get navLandmark => 'Main navigation';

  @override
  String get profileAll => 'All profiles';

  @override
  String get profilePlaceholderPersonal => 'Personal';

  @override
  String get profilePlaceholderBusiness => 'Sole proprietor';

  @override
  String profileSwitcherLabel(String name) {
    return 'Profile: $name. Change profile';
  }

  @override
  String get profileSheetTitle => 'Profile';

  @override
  String get operationsSummary => 'All accounts · This month';

  @override
  String operationsPlaceholderTitle(int number) {
    return 'Operation $number';
  }

  @override
  String get operationsPlaceholderSubtitle => 'Demo data';

  @override
  String get overviewPlaceholder =>
      'Balance, recent operations and widgets will appear here.';

  @override
  String get analyticsPlaceholder => 'Charts and reports will appear here.';

  @override
  String get moreProfiles => 'Profiles';

  @override
  String get moreConnections => 'Connections and accounts';

  @override
  String get moreCategories => 'Categories and rules';

  @override
  String get moreReconciliation => 'Reconciliation';

  @override
  String get moreInvestments => 'Investments';

  @override
  String get moreExports => 'Exports';

  @override
  String get moreSubscription => 'Subscription';

  @override
  String get moreSecurity => 'Security';

  @override
  String get moreAbout => 'About';

  @override
  String get moreAppearance => 'Appearance';

  @override
  String get settingsNoGlass => 'No glass';

  @override
  String get settingsNoGlassHint => 'Opaque bars instead of blur';

  @override
  String get settingsHighContrast => 'High contrast';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get connectionLost => 'No connection to the server';
}
