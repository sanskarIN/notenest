import 'dart:async';

final class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;

  void run(FutureOr<void> Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      unawaited(Future<void>.sync(action));
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
