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

  /// Account and security screens: moreAccount.
  ///
  /// In uk, this message translates to:
  /// **'Акаунт'**
  String get moreAccount;

  /// Account and security screens: commonCancel.
  ///
  /// In uk, this message translates to:
  /// **'Скасувати'**
  String get commonCancel;

  /// Account and security screens: commonClose.
  ///
  /// In uk, this message translates to:
  /// **'Закрити'**
  String get commonClose;

  /// Account and security screens: commonConfirm.
  ///
  /// In uk, this message translates to:
  /// **'Підтвердити'**
  String get commonConfirm;

  /// Account and security screens: commonCopied.
  ///
  /// In uk, this message translates to:
  /// **'Скопійовано'**
  String get commonCopied;

  /// Account and security screens: commonCopy.
  ///
  /// In uk, this message translates to:
  /// **'Копіювати'**
  String get commonCopy;

  /// Account and security screens: commonDelete.
  ///
  /// In uk, this message translates to:
  /// **'Видалити'**
  String get commonDelete;

  /// Account and security screens: commonDone.
  ///
  /// In uk, this message translates to:
  /// **'Готово'**
  String get commonDone;

  /// Account and security screens: commonRetry.
  ///
  /// In uk, this message translates to:
  /// **'Повторити'**
  String get commonRetry;

  /// Account and security screens: commonSave.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти'**
  String get commonSave;

  /// File name or path of a saved file.
  ///
  /// In uk, this message translates to:
  /// **'Збережено: {where}'**
  String commonSavedTo(String where);

  /// Account and security screens: commonSaveFailed.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося зберегти файл'**
  String get commonSaveFailed;

  /// Account and security screens: securitySessions.
  ///
  /// In uk, this message translates to:
  /// **'Сесії'**
  String get securitySessions;

  /// Account and security screens: securitySessionThisDevice.
  ///
  /// In uk, this message translates to:
  /// **'Цей пристрій'**
  String get securitySessionThisDevice;

  /// Account and security screens: securitySessionUnknownDevice.
  ///
  /// In uk, this message translates to:
  /// **'Невідомий пристрій'**
  String get securitySessionUnknownDevice;

  /// Date and time of the session's last use.
  ///
  /// In uk, this message translates to:
  /// **'востаннє {date}'**
  String securitySessionLastUsed(String date);

  /// Account and security screens: securitySessionRevoke.
  ///
  /// In uk, this message translates to:
  /// **'Завершити сесію'**
  String get securitySessionRevoke;

  /// Account and security screens: securitySessionsRevokeOthers.
  ///
  /// In uk, this message translates to:
  /// **'Вийти на інших пристроях'**
  String get securitySessionsRevokeOthers;

  /// Account and security screens: securitySessionsRevokeOthersConfirm.
  ///
  /// In uk, this message translates to:
  /// **'Завершити всі сесії, крім цієї? На інших пристроях доведеться увійти знову.'**
  String get securitySessionsRevokeOthersConfirm;

  /// Account and security screens: securityTotp.
  ///
  /// In uk, this message translates to:
  /// **'Двофакторна автентифікація'**
  String get securityTotp;

  /// Account and security screens: securityTotpOff.
  ///
  /// In uk, this message translates to:
  /// **'Вимкнено'**
  String get securityTotpOff;

  /// Account and security screens: securityTotpOffHint.
  ///
  /// In uk, this message translates to:
  /// **'Код із застосунку-автентифікатора під час входу'**
  String get securityTotpOffHint;

  /// Account and security screens: securityTotpOn.
  ///
  /// In uk, this message translates to:
  /// **'Увімкнено'**
  String get securityTotpOn;

  /// Unused recovery codes.
  ///
  /// In uk, this message translates to:
  /// **'Резервних кодів залишилось: {count}'**
  String securityRecoveryCodesLeft(int count);

  /// Account and security screens: securityTotpEnable.
  ///
  /// In uk, this message translates to:
  /// **'Увімкнути'**
  String get securityTotpEnable;

  /// Account and security screens: securityTotpDisable.
  ///
  /// In uk, this message translates to:
  /// **'Вимкнути 2FA'**
  String get securityTotpDisable;

  /// Account and security screens: securityTotpDisableConfirm.
  ///
  /// In uk, this message translates to:
  /// **'Вхід знову буде лише за паролем. Підтвердіть кодом із застосунку або паролем.'**
  String get securityTotpDisableConfirm;

  /// Account and security screens: securityTotpOrPassword.
  ///
  /// In uk, this message translates to:
  /// **'Або пароль'**
  String get securityTotpOrPassword;

  /// Account and security screens: securityTotpRegenerate.
  ///
  /// In uk, this message translates to:
  /// **'Нові резервні коди'**
  String get securityTotpRegenerate;

  /// Account and security screens: securityTotpRegenerateHint.
  ///
  /// In uk, this message translates to:
  /// **'Старі коди перестануть діяти. Введіть код із застосунку.'**
  String get securityTotpRegenerateHint;

  /// Account and security screens: securityTotpCode.
  ///
  /// In uk, this message translates to:
  /// **'Код із застосунку'**
  String get securityTotpCode;

  /// Account and security screens: securityTotpCodeInvalid.
  ///
  /// In uk, this message translates to:
  /// **'Шість цифр'**
  String get securityTotpCodeInvalid;

  /// Account and security screens: securityPasskeys.
  ///
  /// In uk, this message translates to:
  /// **'Ключі доступу'**
  String get securityPasskeys;

  /// Account and security screens: securityPasskeysEmpty.
  ///
  /// In uk, this message translates to:
  /// **'Ключів доступу ще немає'**
  String get securityPasskeysEmpty;

  /// Account and security screens: securityPasskeyAdd.
  ///
  /// In uk, this message translates to:
  /// **'Додати ключ доступу'**
  String get securityPasskeyAdd;

  /// Account and security screens: securityPasskeyName.
  ///
  /// In uk, this message translates to:
  /// **'Назва, наприклад MacBook'**
  String get securityPasskeyName;

  /// When the passkey was added.
  ///
  /// In uk, this message translates to:
  /// **'Додано {date}'**
  String securityPasskeyCreated(String date);

  /// Name of the passkey.
  ///
  /// In uk, this message translates to:
  /// **'Видалити ключ доступу «{name}»? Увійти з ним більше не вийде.'**
  String securityPasskeyDeleteConfirm(String name);

  /// Account and security screens: totpSetupTitle.
  ///
  /// In uk, this message translates to:
  /// **'Увімкнення 2FA'**
  String get totpSetupTitle;

  /// Account and security screens: totpSetupScan.
  ///
  /// In uk, this message translates to:
  /// **'Відскануйте QR-код застосунком-автентифікатором або введіть ключ вручну, потім введіть код, який він покаже.'**
  String get totpSetupScan;

  /// Account and security screens: totpSetupQrLabel.
  ///
  /// In uk, this message translates to:
  /// **'QR-код для застосунку-автентифікатора'**
  String get totpSetupQrLabel;

  /// Account and security screens: totpSetupManualKey.
  ///
  /// In uk, this message translates to:
  /// **'Ключ для введення вручну'**
  String get totpSetupManualKey;

  /// Account and security screens: recoveryCodesTitle.
  ///
  /// In uk, this message translates to:
  /// **'Резервні коди'**
  String get recoveryCodesTitle;

  /// Account and security screens: recoveryCodesHint.
  ///
  /// In uk, this message translates to:
  /// **'Збережіть ці коди в надійному місці: кожен один раз відкриває вхід без телефона. Більше їх не буде показано.'**
  String get recoveryCodesHint;

  /// Account and security screens: accountProfile.
  ///
  /// In uk, this message translates to:
  /// **'Профіль'**
  String get accountProfile;

  /// Account and security screens: accountDisplayName.
  ///
  /// In uk, this message translates to:
  /// **'Ім\'я'**
  String get accountDisplayName;

  /// Account and security screens: accountLocale.
  ///
  /// In uk, this message translates to:
  /// **'Мова'**
  String get accountLocale;

  /// Account and security screens: accountCurrency.
  ///
  /// In uk, this message translates to:
  /// **'Валюта підсумків'**
  String get accountCurrency;

  /// Account and security screens: accountCurrencyInvalid.
  ///
  /// In uk, this message translates to:
  /// **'Код валюти з трьох латинських літер, наприклад UAH'**
  String get accountCurrencyInvalid;

  /// Account and security screens: accountSaved.
  ///
  /// In uk, this message translates to:
  /// **'Збережено'**
  String get accountSaved;

  /// Account and security screens: accountConflict.
  ///
  /// In uk, this message translates to:
  /// **'Акаунт змінено в іншому місці. Дані оновлено — внесіть зміни ще раз.'**
  String get accountConflict;

  /// Account and security screens: accountEmail.
  ///
  /// In uk, this message translates to:
  /// **'Пошта'**
  String get accountEmail;

  /// The new address awaiting its link.
  ///
  /// In uk, this message translates to:
  /// **'Очікує підтвердження: {email}. Відкрийте посилання з листа.'**
  String accountEmailPending(String email);

  /// Account and security screens: accountEmailChange.
  ///
  /// In uk, this message translates to:
  /// **'Змінити пошту'**
  String get accountEmailChange;

  /// Account and security screens: accountEmailNew.
  ///
  /// In uk, this message translates to:
  /// **'Нова пошта'**
  String get accountEmailNew;

  /// Account and security screens: accountReauthHint.
  ///
  /// In uk, this message translates to:
  /// **'Підтвердіть, що це ви: пароль і, якщо 2FA увімкнено, код або резервний код.'**
  String get accountReauthHint;

  /// Account and security screens: accountReauthCode.
  ///
  /// In uk, this message translates to:
  /// **'Код 2FA або резервний код'**
  String get accountReauthCode;

  /// Account and security screens: accountExport.
  ///
  /// In uk, this message translates to:
  /// **'Експорт даних'**
  String get accountExport;

  /// Account and security screens: accountExportHint.
  ///
  /// In uk, this message translates to:
  /// **'Архів усіх ваших даних у форматі JSON.'**
  String get accountExportHint;

  /// Account and security screens: accountExportStart.
  ///
  /// In uk, this message translates to:
  /// **'Почати експорт'**
  String get accountExportStart;

  /// Account and security screens: accountExportPending.
  ///
  /// In uk, this message translates to:
  /// **'Готуємо архів…'**
  String get accountExportPending;

  /// Account and security screens: accountExportReady.
  ///
  /// In uk, this message translates to:
  /// **'Архів готовий'**
  String get accountExportReady;

  /// When the download link expires.
  ///
  /// In uk, this message translates to:
  /// **'Архів готовий, доступний до {date}'**
  String accountExportReadyUntil(String date);

  /// Account and security screens: accountExportDownload.
  ///
  /// In uk, this message translates to:
  /// **'Завантажити'**
  String get accountExportDownload;

  /// Account and security screens: accountExportFailed.
  ///
  /// In uk, this message translates to:
  /// **'Експорт не вдався. Спробуйте ще раз.'**
  String get accountExportFailed;

  /// Account and security screens: accountExportExpired.
  ///
  /// In uk, this message translates to:
  /// **'Архів більше недоступний. Почніть новий експорт.'**
  String get accountExportExpired;

  /// Account and security screens: accountDanger.
  ///
  /// In uk, this message translates to:
  /// **'Видалення акаунта'**
  String get accountDanger;

  /// Account and security screens: accountDelete.
  ///
  /// In uk, this message translates to:
  /// **'Видалити акаунт'**
  String get accountDelete;

  /// Account and security screens: accountDeleteWarning.
  ///
  /// In uk, this message translates to:
  /// **'Акаунт і всі дані буде видалено назавжди. Цю дію не можна скасувати.'**
  String get accountDeleteWarning;

  /// The account's email address.
  ///
  /// In uk, this message translates to:
  /// **'Щоб підтвердити, введіть {email}'**
  String accountDeleteType(String email);

  /// Account and security screens: languageUk.
  ///
  /// In uk, this message translates to:
  /// **'Українська'**
  String get languageUk;

  /// Account and security screens: languageRu.
  ///
  /// In uk, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// Account and security screens: languageEn.
  ///
  /// In uk, this message translates to:
  /// **'English'**
  String get languageEn;

  /// Name of the current plan.
  ///
  /// In uk, this message translates to:
  /// **'Тариф: {name}'**
  String subscriptionPlan(String name);

  /// Account and security screens: subscriptionEntitlements.
  ///
  /// In uk, this message translates to:
  /// **'Що входить'**
  String get subscriptionEntitlements;

  /// Account and security screens: entitlementProfilesMax.
  ///
  /// In uk, this message translates to:
  /// **'Профілі'**
  String get entitlementProfilesMax;

  /// Account and security screens: entitlementConnectionsMax.
  ///
  /// In uk, this message translates to:
  /// **'Підключення'**
  String get entitlementConnectionsMax;

  /// Account and security screens: entitlementConnectorsBusiness.
  ///
  /// In uk, this message translates to:
  /// **'Бізнес-підключення'**
  String get entitlementConnectorsBusiness;

  /// Account and security screens: entitlementHistoryMonths.
  ///
  /// In uk, this message translates to:
  /// **'Історія, місяців'**
  String get entitlementHistoryMonths;

  /// Account and security screens: entitlementSyncMinInterval.
  ///
  /// In uk, this message translates to:
  /// **'Синхронізація не частіше ніж'**
  String get entitlementSyncMinInterval;

  /// Account and security screens: entitlementExports.
  ///
  /// In uk, this message translates to:
  /// **'Формати вивантаження'**
  String get entitlementExports;

  /// Account and security screens: entitlementAiAnalyses.
  ///
  /// In uk, this message translates to:
  /// **'AI-аналізи на місяць'**
  String get entitlementAiAnalyses;

  /// Account and security screens: entitlementInvestmentsRebalance.
  ///
  /// In uk, this message translates to:
  /// **'Ребалансування портфеля'**
  String get entitlementInvestmentsRebalance;

  /// Account and security screens: entitlementUnlimited.
  ///
  /// In uk, this message translates to:
  /// **'Без обмежень'**
  String get entitlementUnlimited;

  /// Account and security screens: entitlementYes.
  ///
  /// In uk, this message translates to:
  /// **'Так'**
  String get entitlementYes;

  /// Account and security screens: entitlementNo.
  ///
  /// In uk, this message translates to:
  /// **'Ні'**
  String get entitlementNo;

  /// Minutes.
  ///
  /// In uk, this message translates to:
  /// **'{count} хв'**
  String entitlementMinutes(int count);

  /// Account and security screens: planOfferTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ліміт тарифу вичерпано'**
  String get planOfferTitle;

  /// Display name of the exceeded entitlement.
  ///
  /// In uk, this message translates to:
  /// **'«{entitlement}» на вашому тарифі вичерпано. Більше дають тарифи нижче.'**
  String planOfferMessage(String entitlement);

  /// Account and security screens: planOfferMessageUnknown.
  ///
  /// In uk, this message translates to:
  /// **'Ця дія не входить у ваш тариф.'**
  String get planOfferMessageUnknown;

  /// Account and security screens: planOfferSeePlans.
  ///
  /// In uk, this message translates to:
  /// **'Мій тариф'**
  String get planOfferSeePlans;
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
