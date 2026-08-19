import 'dart:async';

final class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;
  bool _disposed = false;

  void run(FutureOr<void> Function() action) {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (_disposed) return;
      unawaited(Future<void>.sync(action));
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _disposed = true;
    cancel();
  }
}
