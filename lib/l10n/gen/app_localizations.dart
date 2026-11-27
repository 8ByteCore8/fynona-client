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

  /// Title of the blocking screen when the API contract of the app is no longer supported (API-12)
  ///
  /// In uk, this message translates to:
  /// **'Застосунок застарів'**
  String get appOutdatedTitle;

  /// Body of the blocking «update the app» screen
  ///
  /// In uk, this message translates to:
  /// **'Оновіть застосунок, щоб продовжити роботу.'**
  String get appOutdatedMessage;

  /// Web only: button that reloads the page to get the new version
  ///
  /// In uk, this message translates to:
  /// **'Перезавантажити'**
  String get appOutdatedReload;

  /// Title of the blocking screen when the server runs an older contract minor (rollback or deploy)
  ///
  /// In uk, this message translates to:
  /// **'Сервіс оновлюється'**
  String get serverBehindTitle;

  /// Body of the blocking «service is updating» screen; never asks to update the app
  ///
  /// In uk, this message translates to:
  /// **'Спробуйте пізніше.'**
  String get serverBehindMessage;

  /// Button that checks the server versions again
  ///
  /// In uk, this message translates to:
  /// **'Спробувати ще раз'**
  String get serverBehindRetry;

  /// Field label: email address.
  ///
  /// In uk, this message translates to:
  /// **'Електронна пошта'**
  String get authEmail;

  /// Field label: password.
  ///
  /// In uk, this message translates to:
  /// **'Пароль'**
  String get authPassword;

  /// Field label: a new password (at least 8 characters).
  ///
  /// In uk, this message translates to:
  /// **'Новий пароль (щонайменше 8 символів)'**
  String get authNewPassword;

  /// Title of the sign-in screen.
  ///
  /// In uk, this message translates to:
  /// **'Вхід'**
  String get authSignInTitle;

  /// Button: sign in with email and password.
  ///
  /// In uk, this message translates to:
  /// **'Увійти'**
  String get authSignInAction;

  /// Title of the sign-up screen.
  ///
  /// In uk, this message translates to:
  /// **'Реєстрація'**
  String get authSignUpTitle;

  /// Button: create the account.
  ///
  /// In uk, this message translates to:
  /// **'Зареєструватися'**
  String get authSignUpAction;

  /// Link from sign-in to sign-up.
  ///
  /// In uk, this message translates to:
  /// **'Немає акаунта? Зареєструватися'**
  String get authToSignUp;

  /// Link back to the sign-in screen.
  ///
  /// In uk, this message translates to:
  /// **'Уже маєте акаунт? Увійти'**
  String get authToSignIn;

  /// Button back to the sign-in screen.
  ///
  /// In uk, this message translates to:
  /// **'До входу'**
  String get authBackToSignIn;

  /// Link to the password reset request.
  ///
  /// In uk, this message translates to:
  /// **'Забули пароль?'**
  String get authForgotPassword;

  /// Button: sign in with a passkey (web).
  ///
  /// In uk, this message translates to:
  /// **'Увійти з ключем доступу'**
  String get authPasskeySignIn;

  /// Error: the passkey sign-in was cancelled or refused.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося увійти з ключем доступу'**
  String get authPasskeyFailed;

  /// Error: wrong email or password; the same text whether or not the email exists.
  ///
  /// In uk, this message translates to:
  /// **'Неправильна пошта або пароль'**
  String get authInvalidCredentials;

  /// Error: the email address is not confirmed yet.
  ///
  /// In uk, this message translates to:
  /// **'Спершу підтвердіть пошту за посиланням з листа'**
  String get authEmailUnverified;

  /// Error: the account is blocked.
  ///
  /// In uk, this message translates to:
  /// **'Акаунт заблоковано. Зверніться до підтримки'**
  String get authAccountBlocked;

  /// Error: too many attempts, wait and retry.
  ///
  /// In uk, this message translates to:
  /// **'Забагато спроб. Спробуйте пізніше'**
  String get authRateLimited;

  /// Error: no connection to the server.
  ///
  /// In uk, this message translates to:
  /// **'Немає звʼязку з сервером. Спробуйте ще раз'**
  String get authNetworkError;

  /// Error: anything else.
  ///
  /// In uk, this message translates to:
  /// **'Щось пішло не так. Спробуйте ще раз'**
  String get authUnknownError;

  /// Validation: not an email address.
  ///
  /// In uk, this message translates to:
  /// **'Введіть адресу пошти'**
  String get authEmailInvalid;

  /// Validation: empty password.
  ///
  /// In uk, this message translates to:
  /// **'Введіть пароль'**
  String get authPasswordRequired;

  /// Validation: password under 8 characters.
  ///
  /// In uk, this message translates to:
  /// **'Щонайменше 8 символів'**
  String get authPasswordTooShort;

  /// Title: the confirmation email is on its way.
  ///
  /// In uk, this message translates to:
  /// **'Перевірте пошту'**
  String get authVerifyPendingTitle;

  /// Body after sign-up; the same text whether or not the email was already registered.
  ///
  /// In uk, this message translates to:
  /// **'Ми надіслали лист на {email}. Перейдіть за посиланням у ньому, щоб завершити реєстрацію.'**
  String authVerifyPendingMessage(String email);

  /// Hint under «check your email»: the app cannot resend the email, so the user checks spam or signs up again.
  ///
  /// In uk, this message translates to:
  /// **'Листа немає? Перевірте вхідні та теку «Спам» або поверніться й зареєструйтеся ще раз.'**
  String get authVerifyPendingHint;

  /// Button: back to the sign-up form to register again.
  ///
  /// In uk, this message translates to:
  /// **'Зареєструватися ще раз'**
  String get authSignUpAgain;

  /// Title of the email confirmation screen.
  ///
  /// In uk, this message translates to:
  /// **'Підтвердження пошти'**
  String get authVerifyTitle;

  /// Message: the email is confirmed.
  ///
  /// In uk, this message translates to:
  /// **'Пошту підтверджено. Тепер можна увійти'**
  String get authVerifyDone;

  /// Error: the emailed link is used, expired or wrong.
  ///
  /// In uk, this message translates to:
  /// **'Посилання недійсне або застаріло'**
  String get authLinkInvalid;

  /// Title of the password reset request screen.
  ///
  /// In uk, this message translates to:
  /// **'Відновлення пароля'**
  String get authForgotTitle;

  /// Button: email a password reset link.
  ///
  /// In uk, this message translates to:
  /// **'Надіслати посилання'**
  String get authForgotSend;

  /// Message after a reset request; the same text whether or not the email exists.
  ///
  /// In uk, this message translates to:
  /// **'Якщо акаунт з цією поштою існує, ми надіслали на неї посилання для нового пароля.'**
  String get authForgotSent;

  /// Title of the new password screen.
  ///
  /// In uk, this message translates to:
  /// **'Новий пароль'**
  String get authResetTitle;

  /// Button: save the new password.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти пароль'**
  String get authResetAction;

  /// Message: the password is changed.
  ///
  /// In uk, this message translates to:
  /// **'Пароль змінено. Увійдіть з новим паролем'**
  String get authResetDone;

  /// Title of the second-factor screen.
  ///
  /// In uk, this message translates to:
  /// **'Підтвердження входу'**
  String get authMfaTitle;

  /// Field label: six-digit code from the authenticator app.
  ///
  /// In uk, this message translates to:
  /// **'Код із застосунку автентифікації'**
  String get authMfaCode;

  /// Field label: a recovery code.
  ///
  /// In uk, this message translates to:
  /// **'Резервний код'**
  String get authMfaRecoveryCode;

  /// Link: enter a recovery code instead.
  ///
  /// In uk, this message translates to:
  /// **'Використати резервний код'**
  String get authMfaUseRecovery;

  /// Link: enter an authenticator code instead.
  ///
  /// In uk, this message translates to:
  /// **'Використати код із застосунку'**
  String get authMfaUseCode;

  /// Validation: the code is not six digits.
  ///
  /// In uk, this message translates to:
  /// **'Введіть 6 цифр'**
  String get authMfaCodeInvalid;

  /// Error: wrong or used code.
  ///
  /// In uk, this message translates to:
  /// **'Неправильний код'**
  String get authMfaInvalid;

  /// Error: the second-factor step expired; sign in again.
  ///
  /// In uk, this message translates to:
  /// **'Час вийшов. Увійдіть ще раз'**
  String get authMfaExpired;

  /// Button: confirm the code.
  ///
  /// In uk, this message translates to:
  /// **'Підтвердити'**
  String get authMfaAction;

  /// Screen-reader label while the saved session is resumed.
  ///
  /// In uk, this message translates to:
  /// **'Відновлення сесії'**
  String get authLoading;

  /// Button: sign out on this device.
  ///
  /// In uk, this message translates to:
  /// **'Вийти'**
  String get authSignOut;
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
