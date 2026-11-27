import 'dart:ui' show FrameTiming;

import 'package:flutter_test/flutter_test.dart';
import 'package:fynona_ui/fynona_ui.dart';

/// A synthetic frame whose build takes [buildUs] and raster takes [rasterUs].
FrameTiming frame(int i, int buildUs, int rasterUs) {
  final t0 = i * 16667;
  return FrameTiming(
    vsyncStart: t0,
    buildStart: t0 + 100,
    buildFinish: t0 + 100 + buildUs,
    rasterStart: t0 + 200 + buildUs,
    rasterFinish: t0 + 200 + buildUs + rasterUs,
    rasterFinishWallTime: t0 + 200 + buildUs + rasterUs,
  );
}

void main() {
  const budget = 16667; // 60 Hz

  test('smooth frames never trip', () {
    final d = LowFpsDetector(budgetMicros: budget);
    expect(
      d.add([for (var i = 0; i < 600; i++) frame(i, 4000, 7000)]),
      isFalse,
    );
    expect(d.tripped, isFalse);
  });

  test('occasional jank (10 %) does not trip', () {
    final d = LowFpsDetector(budgetMicros: budget);
    d.add([
      for (var i = 0; i < 600; i++) frame(i, 4000, i % 10 == 0 ? 30000 : 7000),
    ]);
    expect(d.tripped, isFalse);
  });

  test('sustained slow raster (every 3rd frame over budget) trips once', () {
    final d = LowFpsDetector(budgetMicros: budget);
    final fired = <bool>[];
    for (var batch = 0; batch < 5; batch++) {
      fired.add(
        d.add([
          for (var i = 0; i < 40; i++)
            frame(batch * 40 + i, 4000, i % 3 == 0 ? 24000 : 9000),
        ]),
      );
    }
    expect(fired.where((f) => f), hasLength(1));
    expect(d.tripped, isTrue);
  });

  test('needs a minimum sample before deciding', () {
    final d = LowFpsDetector(budgetMicros: budget);
    expect(
      d.add([for (var i = 0; i < 30; i++) frame(i, 4000, 40000)]),
      isFalse,
    );
    expect(
      d.add([for (var i = 30; i < 60; i++) frame(i, 4000, 40000)]),
      isTrue,
    );
  });
}
