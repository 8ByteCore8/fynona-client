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
}
