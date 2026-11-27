import 'dart:async';

import 'package:cuzdan/data/harem/harem_price_feed.dart';
import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeConnection implements HaremConnection {
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

Map<String, dynamic> event(Map<String, List<num>> rows) => {
  'data': {
    for (final e in rows.entries)
      e.key: {
        'code': e.key,
        'alis': e.value[0],
        'satis': e.value[1],
        'kapanis': e.value.length > 2 ? e.value[2] : 0,
      },
  },
};

/// Yayın mikro görevde ulaşır; olaydan sonra bir tur bekle.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  final t = DateTime(2026, 11, 27, 14, 32);
  late FakeConnection conn;
  late HaremPriceFeed feed;

  setUp(() {
    conn = FakeConnection();
    feed = HaremPriceFeed(conn, now: () => t);
  });
  tearDown(() => feed.dispose());

  test('kaynak adı Harem Altın', () {
    expect(feed.sourceName, 'Harem Altın');
  });

  test('bağlantı ilk dinleyiciyle bir kez açılır', () {
    expect(conn.connectCalls, 0);
    final a = feed.quotes.listen((_) {});
    final b = feed.ons.listen((_) {});
    expect(conn.connectCalls, 1);
    a.cancel();
    b.cancel();
  });

  test('gelen fiyatlar Quote olarak yayılır', () async {
    final got = <Map<AssetKind, Quote>>[];
    final sub = feed.quotes.listen(got.add);

    conn.send(
      event({
        'USDTRY': [41.18, 41.22, 41.0],
        'ALTIN': [4148, 4152, 4120],
      }),
    );
    await settle();

    expect(got, hasLength(1));
    expect(got.single[AssetKind.usd]!.buy, 41.18);
    expect(got.single[AssetKind.usd]!.sell, 41.22);
    expect(got.single[AssetKind.usd]!.updatedAt, t);
    expect(got.single[AssetKind.gramGold]!.buy, 4148);
    await sub.cancel();
  });

  test('kısmi güncelleme öncekileri korur (birleştirir)', () async {
    final got = <Map<AssetKind, Quote>>[];
    final sub = feed.quotes.listen(got.add);

    conn.send(
      event({
        'USDTRY': [41.18, 41.22],
        'EURTRY': [48.06, 48.14],
      }),
    );
    await settle();
    conn.send(
      event({
        'USDTRY': [41.30, 41.34],
      }),
    );
    await settle();

    expect(got, hasLength(2));
    expect(got.last[AssetKind.usd]!.buy, 41.30);
    expect(got.last[AssetKind.eur]!.buy, 48.06); // önceki değer silinmedi
    await sub.cancel();
  });

  test('ons ayrı akıştan gelir ve portföy akışına karışmaz', () async {
    final onsGot = <Quote>[];
    final quotesGot = <Map<AssetKind, Quote>>[];
    final s1 = feed.ons.listen(onsGot.add);
    final s2 = feed.quotes.listen(quotesGot.add);

    conn.send(
      event({
        'ONS': [3120.4, 3121.4, 3130],
      }),
    );
    await settle();

    expect(onsGot.single.buy, 3120.4);
    expect(quotesGot, isEmpty);
    await s1.cancel();
    await s2.cancel();
  });

  test('tanımadığı ya da bozuk olay hiçbir şey yayınlamaz ve çökmez', () async {
    final got = <Map<AssetKind, Quote>>[];
    final sub = feed.quotes.listen(got.add);

    conn.send(
      event({
        'OMRUSD': [0.38, 0.39],
      }),
    );
    await settle();
    conn.send('saçma');
    await settle();
    conn.send(null);
    await settle();
    conn.send({'data': 5});
    await settle();

    expect(got, isEmpty);
    await sub.cancel();
  });

  test('geç gelen dinleyici son bilinen fiyatları hemen alır', () async {
    final first = feed.quotes.listen((_) {});
    conn.send(
      event({
        'USDTRY': [41.18, 41.22],
      }),
    );
    await settle();

    final late = <Map<AssetKind, Quote>>[];
    final sub = feed.quotes.listen(late.add);
    await Future<void>.delayed(Duration.zero);

    expect(late, hasLength(1));
    expect(late.single[AssetKind.usd]!.buy, 41.18);
    await first.cancel();
    await sub.cancel();
  });

  test('dispose bağlantıyı kapatır ve akışları sonlandırır', () async {
    var done = false;
    feed.quotes.listen((_) {}, onDone: () => done = true);

    feed.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(conn.disposed, isTrue);
    expect(done, isTrue);
  });

  test('dispose sonrası gelen olay çökmez', () {
    feed.quotes.listen((_) {});
    feed.dispose();
    expect(
      () => conn.send(
        event({
          'USDTRY': [1, 2],
        }),
      ),
      returnsNormally,
    );
  });
}
