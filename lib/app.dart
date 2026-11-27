import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'l10n/gen/app_localizations.dart';
import 'settings/appearance.dart';
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
  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: GlassAutoDegrade(child: child!),
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
