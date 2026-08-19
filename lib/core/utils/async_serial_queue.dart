final class AsyncSerialQueue {
  Future<void> _tail = Future<void>.value();

  Future<void> add(Future<void> Function() action) {
    final Future<void> task = _tail.then((_) => action());
    _tail = task.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return task;
  }
}
