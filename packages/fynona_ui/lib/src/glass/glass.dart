import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../theme/fynona_theme.dart';
import '../tokens/tokens.g.dart';

/// How chrome surfaces (headers, bars, rails, sheets) are painted (CLI-32,
/// docs/design/README.md «Glass»). Never used on list rows (CLI-31).
enum GlassMode {
  /// Backdrop blur σ `glass.blurSigma`, saturation `glass.saturation`, tint.
  blur,

  /// Automatic fallback: the pre-blurred background art behind the tint, no
  /// `BackdropFilter`; content under the chrome is covered, not blurred.
  prebaked,

  /// Manual «no glass»: opaque `surface.chrome`.
  opaque,

  /// High contrast (toggle or OS setting): opaque chrome of the hc themes.
  highContrast,
}

/// The effective chrome mode. High contrast wins, then the manual switch; in
/// auto mode the blur falls back to [GlassMode.prebaked] when blur is not
/// supported (or too slow, see `LowFpsDetector`).
GlassMode resolveGlassMode({
  required bool highContrast,
  required bool noGlass,
  required bool blurSupported,
}) {
  if (highContrast) return GlassMode.highContrast;
  if (noGlass) return GlassMode.opaque;
  return blurSupported ? GlassMode.blur : GlassMode.prebaked;
}

/// Provides the effective [GlassMode] to every [GlassSurface] below it.
class GlassScope extends InheritedWidget {
  const GlassScope({super.key, required this.mode, required super.child});

  final GlassMode mode;

  static GlassMode of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassScope>()?.mode ??
      GlassMode.blur;

  @override
  bool updateShouldNotify(GlassScope oldWidget) => mode != oldWidget.mode;
}

/// The backdrop filter of brand A: blur, then saturate.
ui.ImageFilter glassFilter() => ui.ImageFilter.compose(
  outer: ui.ColorFilter.matrix(_saturation(FynonaTokens.glassSaturation)),
  inner: ui.ImageFilter.blur(
    sigmaX: FynonaTokens.glassBlurSigma,
    sigmaY: FynonaTokens.glassBlurSigma,
    tileMode: TileMode.clamp,
  ),
);

List<double> _saturation(double s) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final i = 1 - s;
  return [
    i * r + s, i * g, i * b, 0, 0, //
    i * r, i * g + s, i * b, 0, 0, //
    i * r, i * g, i * b + s, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}

/// Which edge of a chrome surface carries the edge line.
enum GlassEdge { none, top, bottom, end }

/// A chrome surface in the mode of the nearest [GlassScope]. The mode changes
/// only what is inside the surface, so switching it never rebuilds content
/// around it (ADR-002 Q5).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.edge = GlassEdge.none,
    this.backdropAlignment = AlignmentDirectional.topCenter,
  });

  final Widget child;
  final GlassEdge edge;

  /// Where the surface sits in the window, for the prebaked backdrop slice.
  final AlignmentGeometry backdropAlignment;

  @override
  Widget build(BuildContext context) {
    final mode = GlassScope.of(context);
    final c = context.fynonaColors;
    final hc = mode == GlassMode.highContrast;
    final edgeSide = BorderSide(
      color: hc ? c.borderOutline : c.borderGlass,
      width: hc
          ? FynonaTokens.glassHighContrastEdgeWidth
          : FynonaTokens.glassEdgeWidth,
    );
    final border = switch (edge) {
      GlassEdge.none => null,
      GlassEdge.top => BorderDirectional(top: edgeSide),
      GlassEdge.bottom => BorderDirectional(bottom: edgeSide),
      GlassEdge.end => BorderDirectional(end: edgeSide),
    };
    final fill = switch (mode) {
      GlassMode.blur || GlassMode.prebaked => c.surfaceGlassTint,
      GlassMode.opaque || GlassMode.highContrast => c.surfaceChrome,
    };
    final tinted = DecoratedBox(
      decoration: BoxDecoration(color: fill, border: border),
      child: child,
    );
    final Widget surface = switch (mode) {
      GlassMode.blur => BackdropFilter(filter: glassFilter(), child: tinted),
      GlassMode.prebaked => Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: PrebakedBackdropSlice(alignment: backdropAlignment),
          ),
          tinted,
        ],
      ),
      GlassMode.opaque || GlassMode.highContrast => tinted,
    };
    return ClipRect(child: surface);
  }
}

/// The app background: `background.base` and, outside high contrast, the
/// three soft colour blobs `background.artA/B/C`.
class FynonaBackground extends StatelessWidget {
  const FynonaBackground({super.key});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: BackgroundPainter(
        colors: context.fynonaColors,
        textDirection: Directionality.of(context),
      ),
      size: Size.infinite,
    ),
  );
}

/// Paints the background art. Blob geometry is
/// `color.*.background.art*.$extensions.app.fynona.gradient` in tokens.json.
class BackgroundPainter extends CustomPainter {
  const BackgroundPainter({required this.colors, required this.textDirection});

  final FynonaColors colors;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.backgroundBase);
    final rtl = textDirection == TextDirection.rtl;
    void blob(double atX, double atY, double w, double h, Color color) {
      final x = (rtl ? 1 - atX : atX) * size.width;
      final center = Offset(x, atY * size.height);
      final rx = w * size.width;
      final ry = h * size.height;
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..scale(1, ry / rx);
      canvas.drawCircle(
        Offset.zero,
        rx,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            rx,
            [color, color.withValues(alpha: 0)],
            const [0, 0.7],
          ),
      );
      canvas.restore();
    }

    if (colors.backgroundArtA != colors.backgroundBase) {
      blob(0, 0, .7, .45, colors.backgroundArtA);
    }
    if (colors.backgroundArtB != colors.backgroundBase) {
      blob(1, .22, .6, .4, colors.backgroundArtB);
    }
    if (colors.backgroundArtC != colors.backgroundBase) {
      blob(.4, 1.05, .7, .45, colors.backgroundArtC);
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) =>
      oldDelegate.colors != colors ||
      oldDelegate.textDirection != textDirection;
}

/// One pre-blurred copy of the background per window size, theme and
/// direction, rendered once with `toImageSync`; prebaked chrome only draws it.
class PrebakedBackdrop {
  PrebakedBackdrop._();

  static ui.Image? _image;
  static Object? _key;

  static ui.Image of(Size size, double dpr, BackgroundPainter painter) {
    final key = (size, dpr, painter.colors, painter.textDirection);
    final cached = _image;
    if (cached != null && _key == key) return cached;
    cached?.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    canvas.saveLayer(Offset.zero & size, Paint()..imageFilter = glassFilter());
    painter.paint(canvas, size);
    canvas.restore();
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      (size.width * dpr).ceil(),
      (size.height * dpr).ceil(),
    );
    picture.dispose();
    _image = image;
    _key = key;
    return image;
  }
}

/// The part of the [PrebakedBackdrop] that lies under a chrome surface.
class PrebakedBackdropSlice extends StatelessWidget {
  const PrebakedBackdropSlice({super.key, required this.alignment});

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final image = PrebakedBackdrop.of(
      size,
      dpr,
      BackgroundPainter(
        colors: context.fynonaColors,
        textDirection: Directionality.of(context),
      ),
    );
    return ClipRect(
      child: OverflowBox(
        alignment: alignment,
        minWidth: size.width,
        maxWidth: size.width,
        minHeight: size.height,
        maxHeight: size.height,
        child: RawImage(image: image, scale: dpr),
      ),
    );
  }
}
