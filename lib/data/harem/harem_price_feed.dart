import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../../domain/asset_kind.dart';
import '../../domain/models.dart';
import '../price_feed.dart';
import 'harem_parser.dart';

/// Harem Altın sayfasının kullandığı Socket.IO fiyat akışı.
const String haremSocketUrl = 'wss://hrmsocketonly.haremaltin.com:443';

/// Fiyat olaylarını getiren bağlantı. Gerçeği Socket.IO'dur; testlerde sahtesi kullanılır.
abstract class HaremConnection {
  /// Her `price_changed` olayının yükü (`{data: {KOD: {...}}, meta: {...}}`).
  Stream<Object?> get events;

  void connect();
  void dispose();
}

/// Sitenin kendi sayfası gibi: yalnızca `websocket` taşıması, kimlik doğrulama yok.
/// Bağlantı koparsa kendiliğinden yeniden dener.
class SocketIoHaremConnection implements HaremConnection {
  SocketIoHaremConnection({this.url = haremSocketUrl});

  final String url;
  final StreamController<Object?> _events = StreamController.broadcast();
  sio.Socket? _socket;

  @override
  Stream<Object?> get events => _events.stream;

  @override
  void connect() {
    if (_socket != null) return;
    final socket = sio.io(
      url,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(30000)
          .disableAutoConnect()
          .build(),
    );
    socket.on('price_changed', (data) {
      if (!_events.isClosed) _events.add(data);
    });
    _socket = socket..connect();
  }

  @override
  void dispose() {
    _socket?.dispose();
    _socket = null;
    _events.close();
  }
}

/// Fiyatları [PriceFeed] olarak sunar. Sunucu yalnızca değişen ürünleri
/// gönderebildiği için son bilinen fiyatlar saklanır ve her olayda o ana kadar
/// bilinen **tüm** türler birlikte yayılır. Yeni dinleyici son bilinenleri hemen alır.
/// Bağlantı ilk dinleyiciyle açılır. `updatedAt`, fiyatın bu cihaza ulaştığı andır.
class HaremPriceFeed implements PriceFeed {
  HaremPriceFeed(this._connection, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final HaremConnection _connection;
  final DateTime Function() _now;
  final StreamController<Map<AssetKind, Quote>> _quotesBus =
      StreamController.broadcast();
  final StreamController<Quote> _onsBus = StreamController.broadcast();
  final Map<AssetKind, Quote> _latest = {};
  Quote? _latestOns;
  StreamSubscription<Object?>? _sub;
  bool _disposed = false;

  @override
  String get sourceName => 'Harem Altın';

  @override
  Stream<Map<AssetKind, Quote>> get quotes => Stream.multi((c) {
    _start();
    if (_latest.isNotEmpty) c.add(Map.unmodifiable(Map.of(_latest)));
    final sub = _quotesBus.stream.listen(c.add, onDone: c.close);
    c.onCancel = sub.cancel;
  }, isBroadcast: true);

  @override
  Stream<Quote> get ons => Stream.multi((c) {
    _start();
    final last = _latestOns;
    if (last != null) c.add(last);
    final sub = _onsBus.stream.listen(c.add, onDone: c.close);
    c.onCancel = sub.cancel;
  }, isBroadcast: true);

  void _start() {
    if (_sub != null || _disposed) return;
    _sub = _connection.events.listen(_onEvent);
    _connection.connect();
  }

  void _onEvent(Object? event) {
    if (_disposed) return;
    final snap = parseHaremEvent(event, receivedAt: _now());
    if (snap.quotes.isNotEmpty) {
      _latest.addAll(snap.quotes);
      _quotesBus.add(Map.unmodifiable(Map.of(_latest)));
    }
    final ons = snap.ons;
    if (ons != null) {
      _latestOns = ons;
      _onsBus.add(ons);
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _sub?.cancel();
    _connection.dispose();
    _quotesBus.close();
    _onsBus.close();
  }
}
