import 'dart:async';

import 'package:cuzdan/data/harem/harem_price_feed.dart';

/// Gerçek Socket.IO yerine elle olay gönderilen bağlantı.
class FakeHaremConnection implements HaremConnection {
  final StreamController<Object?> controller =
      StreamController<Object?>.broadcast(sync: true);
  int connectCalls = 0;
  bool disposed = false;

  @override
  Stream<Object?> get events => controller.stream;

  @override
  void connect() => connectCalls++;

  @override
  void dispose() {
    disposed = true;
    controller.close();
  }

  void send(Object? event) {
    if (!controller.isClosed) controller.add(event);
  }
}
