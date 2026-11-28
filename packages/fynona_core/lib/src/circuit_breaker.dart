/// State of one endpoint group's circuit breaker (API-63).
enum CircuitState { closed, open, halfOpen }

/// Circuit breaker for one endpoint group (API-63).
///
/// `closed` → `open` when the failure ratio over the sliding [window] is above
/// [failureRatio] with at least [minimumVolume] outcomes; after [openPause]
/// one probe is let through (`halfOpen`); its success closes the breaker, its
/// failure opens it again.
final class CircuitBreaker {
  CircuitBreaker({
    this.failureRatio = 0.5,
    this.minimumVolume = 10,
    this.window = const Duration(seconds: 30),
    this.openPause = const Duration(seconds: 15),
    DateTime Function()? now,
    this.onStateChange,
  }) : _now = now ?? DateTime.now;

  final double failureRatio;
  final int minimumVolume;
  final Duration window;
  final Duration openPause;
  final void Function(CircuitState state)? onStateChange;
  final DateTime Function() _now;

  final _outcomes = <(DateTime, bool)>[];
  CircuitState _state = CircuitState.closed;
  DateTime? _openedAt;
  bool _probeInFlight = false;

  CircuitState get state => _state;

  /// Whether a request may go out now. In `open` this turns the breaker
  /// `halfOpen` once the pause is over and admits exactly one probe.
  bool tryAcquire() {
    switch (_state) {
      case CircuitState.closed:
        return true;
      case CircuitState.open:
        if (_now().difference(_openedAt!) < openPause) return false;
        _setState(CircuitState.halfOpen);
        _probeInFlight = true;
        return true;
      case CircuitState.halfOpen:
        if (_probeInFlight) return false;
        _probeInFlight = true;
        return true;
    }
  }

  /// Records the outcome of an admitted request.
  void record({required bool success}) {
    final now = _now();
    if (_state == CircuitState.halfOpen) {
      _probeInFlight = false;
      if (success) {
        _outcomes.clear();
        _setState(CircuitState.closed);
      } else {
        _open(now);
      }
      return;
    }
    if (_state == CircuitState.open) return;
    _outcomes.add((now, success));
    final cutoff = now.subtract(window);
    _outcomes.removeWhere((o) => !o.$1.isAfter(cutoff));
    if (_outcomes.length < minimumVolume) return;
    final failures = _outcomes.where((o) => !o.$2).length;
    if (failures / _outcomes.length > failureRatio) _open(now);
  }

  void _open(DateTime now) {
    _openedAt = now;
    _outcomes.clear();
    _setState(CircuitState.open);
  }

  void _setState(CircuitState next) {
    if (next == _state) return;
    _state = next;
    onStateChange?.call(next);
  }
}
