import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'api/contract.dart';
import 'auth/auth.dart';
import 'l10n/gen/app_localizations.dart';
import 'settings/appearance.dart';
import 'shell/contract_gate.dart';
import 'shell/router.dart';

const supportedLanguages = ['uk', 'ru', 'en'];

/// System language when it is one of uk, ru, en; otherwise Ukrainian (CLI-40).
Locale resolveAppLocale(List<Locale>? preferred) {
  for (final locale in preferred ?? const <Locale>[]) {
    if (supportedLanguages.contains(locale.languageCode)) {
      return Locale(locale.languageCode);
    }
  }
  return const Locale('uk');
}

class FynonaApp extends ConsumerStatefulWidget {
  const FynonaApp({super.key, this.initialLocation = overviewPath});

  final String initialLocation;

  @override
  ConsumerState<FynonaApp> createState() => _FynonaAppState();
}

class _FynonaAppState extends ConsumerState<FynonaApp> {
  /// The auth state as the router's guard sees it.
  late final _auth = ValueNotifier(ref.read(authStateProvider));

  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation,
    auth: _auth,
  );

  /// Checks the API contract again on every return from the background
  /// (API-12); the first check runs when [contractStatusProvider] starts.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(contractStatusProvider.notifier).check(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) => _auth.value = next);
    final appearance = ref.watch(appearanceProvider);
    final highContrast = appearance.highContrast;
    return MaterialApp.router(
      routerConfig: _router,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: highContrast
          ? FynonaTheme.highContrastLight()
          : FynonaTheme.light(),
      darkTheme: highContrast
          ? FynonaTheme.highContrastDark()
          : FynonaTheme.dark(),
      highContrastTheme: FynonaTheme.highContrastLight(),
      highContrastDarkTheme: FynonaTheme.highContrastDark(),
      supportedLocales: [for (final l in supportedLanguages) Locale(l)],
      localeListResolutionCallback: (locales, _) => resolveAppLocale(locales),
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: FynonaTokens.textScaleMaxBody,
        child: GlassScope(
          mode: resolveGlassMode(
            highContrast: highContrast || MediaQuery.highContrastOf(context),
            noGlass: appearance.noGlass,
            blurSupported: ref.watch(blurSupportedProvider),
          ),
          child: ContractGate(
            child: AuthGate(child: GlassAutoDegrade(child: child!)),
          ),
        ),
      ),
    );
  }
}

/// Key of the screen shown while the saved session is resumed.
const authLoadingKey = ValueKey('auth-loading');

/// Hides the app behind a progress indicator until the saved session is
/// resumed or found missing; the router guard takes over from there.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authStateProvider) != AuthState.unknown) return child;
    return Scaffold(
      key: authLoadingKey,
      backgroundColor: context.fynonaColors.backgroundBase,
      body: Center(
        child: Semantics(
          label: AppLocalizations.of(context).authLoading,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

/// Feeds frame timings to [LowFpsDetector] while blur is on and switches the
/// auto mode to the prebaked fallback once it trips (CLI-32).
class GlassAutoDegrade extends ConsumerStatefulWidget {
  const GlassAutoDegrade({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GlassAutoDegrade> createState() => _GlassAutoDegradeState();
}

class _GlassAutoDegradeState extends ConsumerState<GlassAutoDegrade> {
  LowFpsDetector? _detector;
  int _budgetMicros = 16667;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final refresh = View.of(context).display.refreshRate;
    if (refresh > 0) _budgetMicros = (1e6 / refresh).round();
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!mounted) return;
    final mode = context.getInheritedWidgetOfExactType<GlassScope>()?.mode;
    if (mode != GlassMode.blur) return;
    final detector = _detector ??= LowFpsDetector(budgetMicros: _budgetMicros);
    if (detector.add(timings)) {
      ref.read(glassDegradedProvider.notifier).trip();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
