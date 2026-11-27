import 'dart:collection';
import 'dart:ui' show FrameTiming;

import '../tokens/tokens.g.dart';

/// Decides when blur is too slow on this device (CLI-32, ADR-002 Q5).
///
/// A frame is slow when its build or raster phase exceeds the frame budget
/// (1 / display refresh rate). The detector trips once when at least
/// [slowShare] of the last [window] frames were slow and the window holds at
/// least [minFrames] frames. The decision is one-way for the session.
/// Thresholds come from `glass.autoDegrade*` and are not calibrated yet.
class LowFpsDetector {
  LowFpsDetector({
    required this.budgetMicros,
    int? window,
    int? minFrames,
    this.slowShare = FynonaTokens.glassAutoDegradeSlowShare,
  }) : window = window ?? FynonaTokens.glassAutoDegradeWindowFrames.toInt(),
       minFrames = minFrames ?? FynonaTokens.glassAutoDegradeMinFrames.toInt();

  final int budgetMicros;
  final int window;
  final int minFrames;
  final double slowShare;

  final Queue<bool> _recent = Queue<bool>();
  int _slow = 0;
  bool _tripped = false;

  bool get tripped => _tripped;

  /// Feeds a batch from `SchedulerBinding.addTimingsCallback`; returns true
  /// once, at the moment the detector trips.
  bool add(Iterable<FrameTiming> timings) {
    if (_tripped) return false;
    for (final t in timings) {
      final build = t.buildDuration.inMicroseconds;
      final raster = t.rasterDuration.inMicroseconds;
      final slow = (build > raster ? build : raster) > budgetMicros;
      _recent.addLast(slow);
      if (slow) _slow++;
      if (_recent.length > window && _recent.removeFirst()) _slow--;
      if (_recent.length >= minFrames && _slow >= slowShare * _recent.length) {
        _tripped = true;
        return true;
      }
    }
    return false;
  }
}
