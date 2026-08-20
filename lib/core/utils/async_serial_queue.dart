final class AsyncSerialQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> add<T>(Future<T> Function() action) {
    final Future<T> task = _tail.then<T>((_) => action());
    _tail = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }
}
