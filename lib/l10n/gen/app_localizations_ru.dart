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

  @override
  String get moreAccount => 'Аккаунт';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonConfirm => 'Подтвердить';

  @override
  String get commonCopied => 'Скопировано';

  @override
  String get commonCopy => 'Копировать';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonDone => 'Готово';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonSave => 'Сохранить';

  @override
  String commonSavedTo(String where) {
    return 'Сохранено: $where';
  }

  @override
  String get commonSaveFailed => 'Не удалось сохранить файл';

  @override
  String get securitySessions => 'Сессии';

  @override
  String get securitySessionThisDevice => 'Это устройство';

  @override
  String get securitySessionUnknownDevice => 'Неизвестное устройство';

  @override
  String securitySessionLastUsed(String date) {
    return 'последний раз $date';
  }

  @override
  String get securitySessionRevoke => 'Завершить сессию';

  @override
  String get securitySessionsRevokeOthers => 'Выйти на других устройствах';

  @override
  String get securitySessionsRevokeOthersConfirm =>
      'Завершить все сессии, кроме этой? На других устройствах придётся войти снова.';

  @override
  String get securityTotp => 'Двухфакторная аутентификация';

  @override
  String get securityTotpOff => 'Выключена';

  @override
  String get securityTotpOffHint =>
      'Код из приложения-аутентификатора при входе';

  @override
  String get securityTotpOn => 'Включена';

  @override
  String securityRecoveryCodesLeft(int count) {
    return 'Резервных кодов осталось: $count';
  }

  @override
  String get securityTotpEnable => 'Включить';

  @override
  String get securityTotpDisable => 'Выключить 2FA';

  @override
  String get securityTotpDisableConfirm =>
      'Вход снова будет только по паролю. Подтвердите кодом из приложения или паролем.';

  @override
  String get securityTotpOrPassword => 'Или пароль';

  @override
  String get securityTotpRegenerate => 'Новые резервные коды';

  @override
  String get securityTotpRegenerateHint =>
      'Старые коды перестанут работать. Введите код из приложения.';

  @override
  String get securityTotpCode => 'Код из приложения';

  @override
  String get securityTotpCodeInvalid => 'Шесть цифр';

  @override
  String get securityPasskeys => 'Ключи доступа';

  @override
  String get securityPasskeysEmpty => 'Ключей доступа пока нет';

  @override
  String get securityPasskeyAdd => 'Добавить ключ доступа';

  @override
  String get securityPasskeyName => 'Название, например MacBook';

  @override
  String securityPasskeyCreated(String date) {
    return 'Добавлен $date';
  }

  @override
  String securityPasskeyDeleteConfirm(String name) {
    return 'Удалить ключ доступа «$name»? Войти с ним больше не получится.';
  }

  @override
  String get totpSetupTitle => 'Включение 2FA';

  @override
  String get totpSetupScan =>
      'Отсканируйте QR-код приложением-аутентификатором или введите ключ вручную, затем введите код, который оно покажет.';

  @override
  String get totpSetupQrLabel => 'QR-код для приложения-аутентификатора';

  @override
  String get totpSetupManualKey => 'Ключ для ввода вручную';

  @override
  String get recoveryCodesTitle => 'Резервные коды';

  @override
  String get recoveryCodesHint =>
      'Сохраните эти коды в надёжном месте: каждый один раз открывает вход без телефона. Больше они показаны не будут.';

  @override
  String get accountProfile => 'Профиль';

  @override
  String get accountDisplayName => 'Имя';

  @override
  String get accountLocale => 'Язык';

  @override
  String get accountCurrency => 'Валюта итогов';

  @override
  String get accountCurrencyInvalid =>
      'Код валюты из трёх латинских букв, например UAH';

  @override
  String get accountSaved => 'Сохранено';

  @override
  String get accountConflict =>
      'Аккаунт изменён в другом месте. Данные обновлены — внесите изменения ещё раз.';

  @override
  String get accountEmail => 'Почта';

  @override
  String accountEmailPending(String email) {
    return 'Ожидает подтверждения: $email. Откройте ссылку из письма.';
  }

  @override
  String get accountEmailChange => 'Изменить почту';

  @override
  String get accountEmailNew => 'Новая почта';

  @override
  String get accountReauthHint =>
      'Подтвердите, что это вы: пароль и, если 2FA включена, код или резервный код.';

  @override
  String get accountReauthCode => 'Код 2FA или резервный код';

  @override
  String get accountExport => 'Экспорт данных';

  @override
  String get accountExportHint => 'Архив всех ваших данных в формате JSON.';

  @override
  String get accountExportStart => 'Начать экспорт';

  @override
  String get accountExportPending => 'Готовим архив…';

  @override
  String get accountExportReady => 'Архив готов';

  @override
  String accountExportReadyUntil(String date) {
    return 'Архив готов, доступен до $date';
  }

  @override
  String get accountExportDownload => 'Скачать';

  @override
  String get accountExportFailed => 'Экспорт не удался. Попробуйте ещё раз.';

  @override
  String get accountExportExpired =>
      'Архив больше недоступен. Начните новый экспорт.';

  @override
  String get accountDanger => 'Удаление аккаунта';

  @override
  String get accountDelete => 'Удалить аккаунт';

  @override
  String get accountDeleteWarning =>
      'Аккаунт и все данные будут удалены навсегда. Это действие нельзя отменить.';

  @override
  String accountDeleteType(String email) {
    return 'Чтобы подтвердить, введите $email';
  }

  @override
  String get languageUk => 'Українська';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String subscriptionPlan(String name) {
    return 'Тариф: $name';
  }

  @override
  String get subscriptionEntitlements => 'Что входит';

  @override
  String get entitlementProfilesMax => 'Профили';

  @override
  String get entitlementConnectionsMax => 'Подключения';

  @override
  String get entitlementConnectorsBusiness => 'Бизнес-подключения';

  @override
  String get entitlementHistoryMonths => 'История, месяцев';

  @override
  String get entitlementSyncMinInterval => 'Синхронизация не чаще чем';

  @override
  String get entitlementExports => 'Форматы выгрузки';

  @override
  String get entitlementAiAnalyses => 'AI-анализы в месяц';

  @override
  String get entitlementInvestmentsRebalance => 'Ребалансировка портфеля';

  @override
  String get entitlementUnlimited => 'Без ограничений';

  @override
  String get entitlementYes => 'Да';

  @override
  String get entitlementNo => 'Нет';

  @override
  String entitlementMinutes(int count) {
    return '$count мин';
  }

  @override
  String get planOfferTitle => 'Лимит тарифа исчерпан';

  @override
  String planOfferMessage(String entitlement) {
    return '«$entitlement» на вашем тарифе исчерпан. Больше дают тарифы ниже.';
  }

  @override
  String get planOfferMessageUnknown => 'Это действие не входит в ваш тариф.';

  @override
  String get planOfferSeePlans => 'Мой тариф';
}
