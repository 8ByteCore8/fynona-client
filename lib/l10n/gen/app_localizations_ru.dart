// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Fynona';

  @override
  String get navOverview => 'Обзор';

  @override
  String get navOperations => 'Операции';

  @override
  String get navAnalytics => 'Аналитика';

  @override
  String get navMore => 'Ещё';

  @override
  String get navLandmark => 'Основная навигация';

  @override
  String get profileAll => 'Все профили';

  @override
  String get profilePlaceholderPersonal => 'Личный';

  @override
  String get profilePlaceholderBusiness => 'ФЛП';

  @override
  String profileSwitcherLabel(String name) {
    return 'Профиль: $name. Сменить профиль';
  }

  @override
  String get profileSheetTitle => 'Профиль';

  @override
  String get operationsSummary => 'Все счета · Этот месяц';

  @override
  String operationsPlaceholderTitle(int number) {
    return 'Операция $number';
  }

  @override
  String get operationsPlaceholderSubtitle => 'Демонстрационные данные';

  @override
  String get overviewPlaceholder =>
      'Здесь будут баланс, последние операции и виджеты.';

  @override
  String get analyticsPlaceholder => 'Здесь будут графики и отчёты.';

  @override
  String get moreProfiles => 'Профили';

  @override
  String get moreConnections => 'Подключения и счета';

  @override
  String get moreCategories => 'Категории и правила';

  @override
  String get moreReconciliation => 'Сверка';

  @override
  String get moreInvestments => 'Инвестиции';

  @override
  String get moreExports => 'Выгрузки';

  @override
  String get moreSubscription => 'Подписка';

  @override
  String get moreSecurity => 'Безопасность';

  @override
  String get moreAbout => 'О приложении';

  @override
  String get moreAppearance => 'Внешний вид';

  @override
  String get settingsNoGlass => 'Без стекла';

  @override
  String get settingsNoGlassHint => 'Непрозрачные панели вместо размытия';

  @override
  String get settingsHighContrast => 'Высокий контраст';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get connectionLost => 'Нет связи с сервером';

  @override
  String get appOutdatedTitle => 'Приложение устарело';

  @override
  String get appOutdatedMessage =>
      'Обновите приложение, чтобы продолжить работу.';

  @override
  String get appOutdatedReload => 'Перезагрузить';

  @override
  String get serverBehindTitle => 'Сервис обновляется';

  @override
  String get serverBehindMessage => 'Попробуйте позже.';

  @override
  String get serverBehindRetry => 'Повторить';

  @override
  String get authEmail => 'Электронная почта';

  @override
  String get authPassword => 'Пароль';

  @override
  String get authNewPassword => 'Новый пароль (не меньше 8 символов)';

  @override
  String get authSignInTitle => 'Вход';

  @override
  String get authSignInAction => 'Войти';

  @override
  String get authSignUpTitle => 'Регистрация';

  @override
  String get authSignUpAction => 'Зарегистрироваться';

  @override
  String get authToSignUp => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get authToSignIn => 'Уже есть аккаунт? Войти';

  @override
  String get authBackToSignIn => 'Ко входу';

  @override
  String get authForgotPassword => 'Забыли пароль?';

  @override
  String get authPasskeySignIn => 'Войти с ключом доступа';

  @override
  String get authPasskeyFailed => 'Не удалось войти с ключом доступа';

  @override
  String get authInvalidCredentials => 'Неверная почта или пароль';

  @override
  String get authEmailUnverified =>
      'Сначала подтвердите почту по ссылке из письма';

  @override
  String get authAccountBlocked =>
      'Аккаунт заблокирован. Обратитесь в поддержку';

  @override
  String get authRateLimited => 'Слишком много попыток. Попробуйте позже';

  @override
  String get authNetworkError => 'Нет связи с сервером. Попробуйте ещё раз';

  @override
  String get authUnknownError => 'Что-то пошло не так. Попробуйте ещё раз';

  @override
  String get authEmailInvalid => 'Введите адрес почты';

  @override
  String get authPasswordRequired => 'Введите пароль';

  @override
  String get authPasswordTooShort => 'Не меньше 8 символов';

  @override
  String get authVerifyPendingTitle => 'Проверьте почту';

  @override
  String authVerifyPendingMessage(String email) {
    return 'Мы отправили письмо на $email. Перейдите по ссылке в нём, чтобы завершить регистрацию.';
  }

  @override
  String get authVerifyPendingHint =>
      'Письма нет? Проверьте входящие и папку «Спам» или вернитесь и зарегистрируйтесь ещё раз.';

  @override
  String get authSignUpAgain => 'Зарегистрироваться ещё раз';

  @override
  String get authVerifyTitle => 'Подтверждение почты';

  @override
  String get authVerifyDone => 'Почта подтверждена. Теперь можно войти';

  @override
  String get authLinkInvalid => 'Ссылка недействительна или устарела';

  @override
  String get authForgotTitle => 'Восстановление пароля';

  @override
  String get authForgotSend => 'Отправить ссылку';

  @override
  String get authForgotSent =>
      'Если аккаунт с этой почтой существует, мы отправили на неё ссылку для нового пароля.';

  @override
  String get authResetTitle => 'Новый пароль';

  @override
  String get authResetAction => 'Сохранить пароль';

  @override
  String get authResetDone => 'Пароль изменён. Войдите с новым паролем';

  @override
  String get authMfaTitle => 'Подтверждение входа';

  @override
  String get authMfaCode => 'Код из приложения аутентификации';

  @override
  String get authMfaRecoveryCode => 'Резервный код';

  @override
  String get authMfaUseRecovery => 'Использовать резервный код';

  @override
  String get authMfaUseCode => 'Использовать код из приложения';

  @override
  String get authMfaCodeInvalid => 'Введите 6 цифр';

  @override
  String get authMfaInvalid => 'Неверный код';

  @override
  String get authMfaExpired => 'Время вышло. Войдите ещё раз';

  @override
  String get authMfaAction => 'Подтвердить';

  @override
  String get authLoading => 'Восстановление сессии';

  @override
  String get authSignOut => 'Выйти';
}
