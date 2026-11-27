// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Fynona';

  @override
  String get navOverview => 'Огляд';

  @override
  String get navOperations => 'Операції';

  @override
  String get navAnalytics => 'Аналітика';

  @override
  String get navMore => 'Ще';

  @override
  String get navLandmark => 'Основна навігація';

  @override
  String get profileAll => 'Усі профілі';

  @override
  String get profilePlaceholderPersonal => 'Особистий';

  @override
  String get profilePlaceholderBusiness => 'ФОП';

  @override
  String profileSwitcherLabel(String name) {
    return 'Профіль: $name. Змінити профіль';
  }

  @override
  String get profileSheetTitle => 'Профіль';

  @override
  String get operationsSummary => 'Усі рахунки · Цей місяць';

  @override
  String operationsPlaceholderTitle(int number) {
    return 'Операція $number';
  }

  @override
  String get operationsPlaceholderSubtitle => 'Демонстраційні дані';

  @override
  String get overviewPlaceholder =>
      'Тут будуть баланс, останні операції та віджети.';

  @override
  String get analyticsPlaceholder => 'Тут будуть графіки та звіти.';

  @override
  String get moreProfiles => 'Профілі';

  @override
  String get moreConnections => 'Підключення та рахунки';

  @override
  String get moreCategories => 'Категорії та правила';

  @override
  String get moreReconciliation => 'Звірка';

  @override
  String get moreInvestments => 'Інвестиції';

  @override
  String get moreExports => 'Вивантаження';

  @override
  String get moreSubscription => 'Підписка';

  @override
  String get moreSecurity => 'Безпека';

  @override
  String get moreAbout => 'Про застосунок';

  @override
  String get moreAppearance => 'Вигляд';

  @override
  String get settingsNoGlass => 'Без скла';

  @override
  String get settingsNoGlassHint => 'Непрозорі панелі замість розмиття';

  @override
  String get settingsHighContrast => 'Високий контраст';

  @override
  String get comingSoon => 'Незабаром';

  @override
  String get connectionLost => 'Немає звʼязку з сервером';

  @override
  String get appOutdatedTitle => 'Застосунок застарів';

  @override
  String get appOutdatedMessage => 'Оновіть застосунок, щоб продовжити роботу.';

  @override
  String get appOutdatedReload => 'Перезавантажити';

  @override
  String get serverBehindTitle => 'Сервіс оновлюється';

  @override
  String get serverBehindMessage => 'Спробуйте пізніше.';

  @override
  String get serverBehindRetry => 'Спробувати ще раз';

  @override
  String get authEmail => 'Електронна пошта';

  @override
  String get authPassword => 'Пароль';

  @override
  String get authNewPassword => 'Новий пароль (щонайменше 8 символів)';

  @override
  String get authSignInTitle => 'Вхід';

  @override
  String get authSignInAction => 'Увійти';

  @override
  String get authSignUpTitle => 'Реєстрація';

  @override
  String get authSignUpAction => 'Зареєструватися';

  @override
  String get authToSignUp => 'Немає акаунта? Зареєструватися';

  @override
  String get authToSignIn => 'Уже маєте акаунт? Увійти';

  @override
  String get authBackToSignIn => 'До входу';

  @override
  String get authForgotPassword => 'Забули пароль?';

  @override
  String get authPasskeySignIn => 'Увійти з ключем доступу';

  @override
  String get authPasskeyFailed => 'Не вдалося увійти з ключем доступу';

  @override
  String get authInvalidCredentials => 'Неправильна пошта або пароль';

  @override
  String get authEmailUnverified =>
      'Спершу підтвердіть пошту за посиланням з листа';

  @override
  String get authAccountBlocked =>
      'Акаунт заблоковано. Зверніться до підтримки';

  @override
  String get authRateLimited => 'Забагато спроб. Спробуйте пізніше';

  @override
  String get authNetworkError => 'Немає звʼязку з сервером. Спробуйте ще раз';

  @override
  String get authUnknownError => 'Щось пішло не так. Спробуйте ще раз';

  @override
  String get authEmailInvalid => 'Введіть адресу пошти';

  @override
  String get authPasswordRequired => 'Введіть пароль';

  @override
  String get authPasswordTooShort => 'Щонайменше 8 символів';

  @override
  String get authVerifyPendingTitle => 'Перевірте пошту';

  @override
  String authVerifyPendingMessage(String email) {
    return 'Ми надіслали лист на $email. Перейдіть за посиланням у ньому, щоб завершити реєстрацію.';
  }

  @override
  String get authVerifyPendingHint =>
      'Листа немає? Перевірте вхідні та теку «Спам» або поверніться й зареєструйтеся ще раз.';

  @override
  String get authSignUpAgain => 'Зареєструватися ще раз';

  @override
  String get authVerifyTitle => 'Підтвердження пошти';

  @override
  String get authVerifyDone => 'Пошту підтверджено. Тепер можна увійти';

  @override
  String get authLinkInvalid => 'Посилання недійсне або застаріло';

  @override
  String get authForgotTitle => 'Відновлення пароля';

  @override
  String get authForgotSend => 'Надіслати посилання';

  @override
  String get authForgotSent =>
      'Якщо акаунт з цією поштою існує, ми надіслали на неї посилання для нового пароля.';

  @override
  String get authResetTitle => 'Новий пароль';

  @override
  String get authResetAction => 'Зберегти пароль';

  @override
  String get authResetDone => 'Пароль змінено. Увійдіть з новим паролем';

  @override
  String get authMfaTitle => 'Підтвердження входу';

  @override
  String get authMfaCode => 'Код із застосунку автентифікації';

  @override
  String get authMfaRecoveryCode => 'Резервний код';

  @override
  String get authMfaUseRecovery => 'Використати резервний код';

  @override
  String get authMfaUseCode => 'Використати код із застосунку';

  @override
  String get authMfaCodeInvalid => 'Введіть 6 цифр';

  @override
  String get authMfaInvalid => 'Неправильний код';

  @override
  String get authMfaExpired => 'Час вийшов. Увійдіть ще раз';

  @override
  String get authMfaAction => 'Підтвердити';

  @override
  String get authLoading => 'Відновлення сесії';

  @override
  String get authSignOut => 'Вийти';
}
