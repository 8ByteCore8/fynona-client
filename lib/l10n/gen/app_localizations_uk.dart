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

  @override
  String get moreAccount => 'Акаунт';

  @override
  String get commonCancel => 'Скасувати';

  @override
  String get commonClose => 'Закрити';

  @override
  String get commonConfirm => 'Підтвердити';

  @override
  String get commonCopied => 'Скопійовано';

  @override
  String get commonCopy => 'Копіювати';

  @override
  String get commonDelete => 'Видалити';

  @override
  String get commonDone => 'Готово';

  @override
  String get commonRetry => 'Повторити';

  @override
  String get commonSave => 'Зберегти';

  @override
  String commonSavedTo(String where) {
    return 'Збережено: $where';
  }

  @override
  String get commonSaveFailed => 'Не вдалося зберегти файл';

  @override
  String get securitySessions => 'Сесії';

  @override
  String get securitySessionThisDevice => 'Цей пристрій';

  @override
  String get securitySessionUnknownDevice => 'Невідомий пристрій';

  @override
  String securitySessionLastUsed(String date) {
    return 'востаннє $date';
  }

  @override
  String get securitySessionRevoke => 'Завершити сесію';

  @override
  String get securitySessionsRevokeOthers => 'Вийти на інших пристроях';

  @override
  String get securitySessionsRevokeOthersConfirm =>
      'Завершити всі сесії, крім цієї? На інших пристроях доведеться увійти знову.';

  @override
  String get securityTotp => 'Двофакторна автентифікація';

  @override
  String get securityTotpOff => 'Вимкнено';

  @override
  String get securityTotpOffHint =>
      'Код із застосунку-автентифікатора під час входу';

  @override
  String get securityTotpOn => 'Увімкнено';

  @override
  String securityRecoveryCodesLeft(int count) {
    return 'Резервних кодів залишилось: $count';
  }

  @override
  String get securityTotpEnable => 'Увімкнути';

  @override
  String get securityTotpDisable => 'Вимкнути 2FA';

  @override
  String get securityTotpDisableConfirm =>
      'Вхід знову буде лише за паролем. Підтвердіть кодом із застосунку або паролем.';

  @override
  String get securityTotpOrPassword => 'Або пароль';

  @override
  String get securityTotpRegenerate => 'Нові резервні коди';

  @override
  String get securityTotpRegenerateHint =>
      'Старі коди перестануть діяти. Введіть код із застосунку.';

  @override
  String get securityTotpCode => 'Код із застосунку';

  @override
  String get securityTotpCodeInvalid => 'Шість цифр';

  @override
  String get securityPasskeys => 'Ключі доступу';

  @override
  String get securityPasskeysEmpty => 'Ключів доступу ще немає';

  @override
  String get securityPasskeyAdd => 'Додати ключ доступу';

  @override
  String get securityPasskeyName => 'Назва, наприклад MacBook';

  @override
  String securityPasskeyCreated(String date) {
    return 'Додано $date';
  }

  @override
  String securityPasskeyDeleteConfirm(String name) {
    return 'Видалити ключ доступу «$name»? Увійти з ним більше не вийде.';
  }

  @override
  String get totpSetupTitle => 'Увімкнення 2FA';

  @override
  String get totpSetupScan =>
      'Відскануйте QR-код застосунком-автентифікатором або введіть ключ вручну, потім введіть код, який він покаже.';

  @override
  String get totpSetupQrLabel => 'QR-код для застосунку-автентифікатора';

  @override
  String get totpSetupManualKey => 'Ключ для введення вручну';

  @override
  String get recoveryCodesTitle => 'Резервні коди';

  @override
  String get recoveryCodesHint =>
      'Збережіть ці коди в надійному місці: кожен один раз відкриває вхід без телефона. Більше їх не буде показано.';

  @override
  String get accountProfile => 'Профіль';

  @override
  String get accountDisplayName => 'Ім\'я';

  @override
  String get accountLocale => 'Мова';

  @override
  String get accountCurrency => 'Валюта підсумків';

  @override
  String get accountCurrencyInvalid =>
      'Код валюти з трьох латинських літер, наприклад UAH';

  @override
  String get accountSaved => 'Збережено';

  @override
  String get accountConflict =>
      'Акаунт змінено в іншому місці. Дані оновлено — внесіть зміни ще раз.';

  @override
  String get accountEmail => 'Пошта';

  @override
  String accountEmailPending(String email) {
    return 'Очікує підтвердження: $email. Відкрийте посилання з листа.';
  }

  @override
  String get accountEmailChange => 'Змінити пошту';

  @override
  String get accountEmailNew => 'Нова пошта';

  @override
  String get accountReauthHint =>
      'Підтвердіть, що це ви: пароль і, якщо 2FA увімкнено, код або резервний код.';

  @override
  String get accountReauthCode => 'Код 2FA або резервний код';

  @override
  String get accountExport => 'Експорт даних';

  @override
  String get accountExportHint => 'Архів усіх ваших даних у форматі JSON.';

  @override
  String get accountExportStart => 'Почати експорт';

  @override
  String get accountExportPending => 'Готуємо архів…';

  @override
  String get accountExportReady => 'Архів готовий';

  @override
  String accountExportReadyUntil(String date) {
    return 'Архів готовий, доступний до $date';
  }

  @override
  String get accountExportDownload => 'Завантажити';

  @override
  String get accountExportFailed => 'Експорт не вдався. Спробуйте ще раз.';

  @override
  String get accountExportExpired =>
      'Архів більше недоступний. Почніть новий експорт.';

  @override
  String get accountDanger => 'Видалення акаунта';

  @override
  String get accountDelete => 'Видалити акаунт';

  @override
  String get accountDeleteWarning =>
      'Акаунт і всі дані буде видалено назавжди. Цю дію не можна скасувати.';

  @override
  String accountDeleteType(String email) {
    return 'Щоб підтвердити, введіть $email';
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
  String get subscriptionEntitlements => 'Що входить';

  @override
  String get entitlementProfilesMax => 'Профілі';

  @override
  String get entitlementConnectionsMax => 'Підключення';

  @override
  String get entitlementConnectorsBusiness => 'Бізнес-підключення';

  @override
  String get entitlementHistoryMonths => 'Історія, місяців';

  @override
  String get entitlementSyncMinInterval => 'Синхронізація не частіше ніж';

  @override
  String get entitlementExports => 'Формати вивантаження';

  @override
  String get entitlementAiAnalyses => 'AI-аналізи на місяць';

  @override
  String get entitlementInvestmentsRebalance => 'Ребалансування портфеля';

  @override
  String get entitlementUnlimited => 'Без обмежень';

  @override
  String get entitlementYes => 'Так';

  @override
  String get entitlementNo => 'Ні';

  @override
  String entitlementMinutes(int count) {
    return '$count хв';
  }

  @override
  String get planOfferTitle => 'Ліміт тарифу вичерпано';

  @override
  String planOfferMessage(String entitlement) {
    return '«$entitlement» на вашому тарифі вичерпано. Більше дають тарифи нижче.';
  }

  @override
  String get planOfferMessageUnknown => 'Ця дія не входить у ваш тариф.';

  @override
  String get planOfferSeePlans => 'Мій тариф';
}
