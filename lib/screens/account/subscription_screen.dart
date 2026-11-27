import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../account/account.dart';
import '../../l10n/gen/app_localizations.dart';
import 'account_widgets.dart';

const subscriptionPlanKey = ValueKey('subscription-plan');
const planOfferKey = ValueKey('plan-offer');
const planOfferSeePlansKey = ValueKey('plan-offer-see-plans');

/// Key of the row of entitlement [name].
ValueKey<String> entitlementRowKey(String name) =>
    ValueKey('entitlement-$name');

/// The entitlements the client knows how to name (MON-1), in display order;
/// any other name is shown as the server sends it.
const knownEntitlements = [
  'profiles.max',
  'connections.max',
  'connectors.business',
  'history.months',
  'sync.min_interval',
  'exports',
  'ai.analyses_per_month',
  'investments.rebalance',
];

/// The display name of entitlement [name].
String entitlementLabel(AppLocalizations l, String name) => switch (name) {
  'profiles.max' => l.entitlementProfilesMax,
  'connections.max' => l.entitlementConnectionsMax,
  'connectors.business' => l.entitlementConnectorsBusiness,
  'history.months' => l.entitlementHistoryMonths,
  'sync.min_interval' => l.entitlementSyncMinInterval,
  'exports' => l.entitlementExports,
  'ai.analyses_per_month' => l.entitlementAiAnalyses,
  'investments.rebalance' => l.entitlementInvestmentsRebalance,
  _ => name,
};

/// A value of entitlement [name]: a feature (yes/no), a limit (null is no
/// limit) or a set of options (MON-1).
String entitlementValueText(AppLocalizations l, String name, Object? value) =>
    switch (value) {
      null => l.entitlementUnlimited,
      true => l.entitlementYes,
      false => l.entitlementNo,
      final num n when name == 'sync.min_interval' => l.entitlementMinutes(
        (n / 60).ceil(),
      ),
      final num n => '$n',
      final List<Object?> items when items.isEmpty => l.entitlementNo,
      final List<Object?> items => items.join(', '),
      _ => '$value',
    };

/// Whether [offered] gives more of entitlement [name] than [current]. A
/// lower `sync.min_interval` is more.
bool givesMore(String name, Object? offered, Object? current) =>
    switch ((offered, current)) {
      (_, null) when name != 'sync.min_interval' => false,
      (null, _) => name != 'sync.min_interval',
      (true, false) => true,
      (final num a, final num b) when name == 'sync.min_interval' => a < b,
      (final num a, final num b) => a > b,
      (final List<Object?> a, final List<Object?> b) => a.length > b.length,
      _ => false,
    };

List<String> _ordered(Iterable<String> names) => [
  for (final name in knownEntitlements)
    if (names.contains(name)) name,
  for (final name in names)
    if (!knownEntitlements.contains(name)) name,
];

/// Ще → Підписка: the current plan and its entitlements from
/// `/v1/entitlements`, for display only (MON-3).
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final plans = ref.watch(plansProvider).value ?? const <Plan>[];
    return SettingsPage(
      title: l.moreSubscription,
      children: [
        AsyncSection(
          provider: entitlementsProvider,
          data: (current) {
            final values = current.entitlements.value;
            final name =
                plans.where((p) => p.code == current.plan).firstOrNull?.name ??
                current.plan;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  key: subscriptionPlanKey,
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text(l.subscriptionPlan(name)),
                ),
                SectionTitle(l.subscriptionEntitlements),
                for (final entry in _ordered(values.keys))
                  ListTile(
                    key: entitlementRowKey(entry),
                    title: Text(entitlementLabel(l, entry)),
                    trailing: Text(
                      entitlementValueText(l, entry, values[entry]),
                      style: FynonaTypography.body.copyWith(
                        color: context.fynonaColors.contentPrimary,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The plan offer of a `402 entitlement.exceeded` (MON-4): what ran out and
/// the plans that give more of it. Nothing is bought here (payments come in
/// M9); [onSeePlans] opens the subscription screen.
class PlanOfferSheet extends ConsumerWidget {
  const PlanOfferSheet({
    super.key,
    required this.exception,
    required this.onSeePlans,
  });

  final EntitlementExceededException exception;
  final VoidCallback onSeePlans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final colors = context.fynonaColors;
    final name = exception.entitlement;
    final current = ref.watch(entitlementsProvider).value;
    final plans = ref.watch(plansProvider).value ?? const <Plan>[];
    final have = current?.entitlements.value[name];
    final offers = name == null
        ? const <Plan>[]
        : [
            for (final plan in plans)
              if (plan.code != current?.plan &&
                  givesMore(name, plan.entitlements.value[name], have))
                plan,
          ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(FynonaTokens.space24),
        child: Column(
          key: planOfferKey,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l.planOfferTitle,
                style: FynonaTypography.title.copyWith(
                  color: colors.contentPrimary,
                ),
              ),
            ),
            const SizedBox(height: FynonaTokens.space8),
            Text(
              name == null
                  ? l.planOfferMessageUnknown
                  : l.planOfferMessage(entitlementLabel(l, name)),
              style: FynonaTypography.body.copyWith(
                color: colors.contentSecondary,
              ),
            ),
            if (name != null && offers.isNotEmpty) ...[
              const SizedBox(height: FynonaTokens.space8),
              for (final plan in offers)
                ListTile(
                  contentPadding: EdgeInsetsDirectional.zero,
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text(plan.name),
                  trailing: Text(
                    entitlementValueText(
                      l,
                      name,
                      plan.entitlements.value[name],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: FynonaTokens.space16),
            FilledButton(
              key: planOfferSeePlansKey,
              onPressed: onSeePlans,
              child: Text(l.planOfferSeePlans),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.commonClose),
            ),
          ],
        ),
      ),
    );
  }
}
