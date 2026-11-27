import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uk'),
  ];

  /// Application name.
  ///
  /// In uk, this message translates to:
  /// **'Fynona'**
  String get appTitle;

  /// Bottom bar and rail destination: home dashboard.
  ///
  /// In uk, this message translates to:
  /// **'Огляд'**
  String get navOverview;

  /// Bottom bar and rail destination: transaction list.
  ///
  /// In uk, this message translates to:
  /// **'Операції'**
  String get navOperations;

  /// Bottom bar and rail destination: charts and reports.
  ///
  /// In uk, this message translates to:
  /// **'Аналітика'**
  String get navAnalytics;

  /// Bottom bar and rail destination: everything else.
  ///
  /// In uk, this message translates to:
  /// **'Ще'**
  String get navMore;

  /// Screen-reader name of the navigation landmark.
  ///
  /// In uk, this message translates to:
  /// **'Основна навігація'**
  String get navLandmark;

  /// Profile context: the combined dashboard of every profile.
  ///
  /// In uk, this message translates to:
  /// **'Усі профілі'**
  String get profileAll;

  /// Placeholder profile name until profiles come from the API.
  ///
  /// In uk, this message translates to:
  /// **'Особистий'**
  String get profilePlaceholderPersonal;

  /// Placeholder business profile name until profiles come from the API.
  ///
  /// In uk, this message translates to:
  /// **'ФОП'**
  String get profilePlaceholderBusiness;

  /// Screen-reader label of the profile switcher button.
  ///
  /// In uk, this message translates to:
  /// **'Профіль: {name}. Змінити профіль'**
  String profileSwitcherLabel(String name);

  /// Title of the profile picker sheet.
  ///
  /// In uk, this message translates to:
  /// **'Профіль'**
  String get profileSheetTitle;

  /// Placeholder summary row above the operations list.
  ///
  /// In uk, this message translates to:
  /// **'Усі рахунки · Цей місяць'**
  String get operationsSummary;

  /// Placeholder operation row title until operations come from the API.
  ///
  /// In uk, this message translates to:
  /// **'Операція {number}'**
  String operationsPlaceholderTitle(int number);

  /// Placeholder operation row subtitle.
  ///
  /// In uk, this message translates to:
  /// **'Демонстраційні дані'**
  String get operationsPlaceholderSubtitle;

  /// Placeholder body of the overview screen.
  ///
  /// In uk, this message translates to:
  /// **'Тут будуть баланс, останні операції та віджети.'**
  String get overviewPlaceholder;

  /// Placeholder body of the analytics screen.
  ///
  /// In uk, this message translates to:
  /// **'Тут будуть графіки та звіти.'**
  String get analyticsPlaceholder;

  /// More: profiles section.
  ///
  /// In uk, this message translates to:
  /// **'Профілі'**
  String get moreProfiles;

  /// More: connections section.
  ///
  /// In uk, this message translates to:
  /// **'Підключення та рахунки'**
  String get moreConnections;

  /// More: categories section.
  ///
  /// In uk, this message translates to:
  /// **'Категорії та правила'**
  String get moreCategories;

  /// More: reconciliation section.
  ///
  /// In uk, this message translates to:
  /// **'Звірка'**
  String get moreReconciliation;

  /// More: investments section.
  ///
  /// In uk, this message translates to:
  /// **'Інвестиції'**
  String get moreInvestments;

  /// More: exports section.
  ///
  /// In uk, this message translates to:
  /// **'Вивантаження'**
  String get moreExports;

  /// More: subscription section.
  ///
  /// In uk, this message translates to:
  /// **'Підписка'**
  String get moreSubscription;

  /// More: security section.
  ///
  /// In uk, this message translates to:
  /// **'Безпека'**
  String get moreSecurity;

  /// More: about section.
  ///
  /// In uk, this message translates to:
  /// **'Про застосунок'**
  String get moreAbout;

  /// More: appearance settings header.
  ///
  /// In uk, this message translates to:
  /// **'Вигляд'**
  String get moreAppearance;

  /// Switch: opaque chrome instead of glass.
  ///
  /// In uk, this message translates to:
  /// **'Без скла'**
  String get settingsNoGlass;

  /// Subtitle of the no-glass switch.
  ///
  /// In uk, this message translates to:
  /// **'Непрозорі панелі замість розмиття'**
  String get settingsNoGlassHint;

  /// Switch: high-contrast theme.
  ///
  /// In uk, this message translates to:
  /// **'Високий контраст'**
  String get settingsHighContrast;

  /// Message for sections that are not built yet.
  ///
  /// In uk, this message translates to:
  /// **'Незабаром'**
  String get comingSoon;

  /// Banner while the API circuit breaker is open (API-63).
  ///
  /// In uk, this message translates to:
  /// **'Немає звʼязку з сервером'**
  String get connectionLost;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
