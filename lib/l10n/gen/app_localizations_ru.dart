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
}
