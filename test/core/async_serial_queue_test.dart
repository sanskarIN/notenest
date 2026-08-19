import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:notenest/core/utils/async_serial_queue.dart';

void main() {
  test('runs tasks in submission order', () async {
    final AsyncSerialQueue queue = AsyncSerialQueue();
    final Completer<void> releaseFirst = Completer<void>();
    final List<String> events = <String>[];

    final Future<void> first = queue.add(() async {
      events.add('first-start');
      await releaseFirst.future;
      events.add('first-end');
    });
    final Future<void> second = queue.add(() async {
      events.add('second');
    });

    await Future<void>.delayed(Duration.zero);
    expect(events, <String>['first-start']);

    releaseFirst.complete();
    await Future.wait<void>(<Future<void>>[first, second]);

    expect(events, <String>['first-start', 'first-end', 'second']);
  });

  test('continues with later tasks after an earlier failure', () async {
    final AsyncSerialQueue queue = AsyncSerialQueue();
    bool secondRan = false;

    final Future<void> first = queue.add(() async {
      throw StateError('expected test failure');
    });
    final Future<void> second = queue.add(() async {
      secondRan = true;
    });

    await expectLater(first, throwsStateError);
    await second;

    expect(secondRan, isTrue);
  });
}
