import 'package:cuzdan/data/harem/harem_parser.dart';
import 'package:cuzdan/domain/asset_kind.dart';
import 'package:flutter_test/flutter_test.dart';

final _t = DateTime(2026, 11, 27, 14, 32);

Map<String, dynamic> row(
  String code,
  Object? alis,
  Object? satis, [
  Object? kapanis = 0,
]) => {
  'code': code,
  'alis': alis,
  'satis': satis,
  'kapanis': kapanis,
  'tarih': '2026-11-27 14:32:00',
};

Map<String, dynamic> event(List<Map<String, dynamic>> rows) => {
  'data': {for (final r in rows) r['code'] as String: r},
  'meta': {'time': 1796000000000, 'fiyat_yayini': 'socket'},
};

void main() {
  group('parseHaremNumber', () {
    test('sayıyı olduğu gibi alır', () {
      expect(parseHaremNumber(4148.25), 4148.25);
      expect(parseHaremNumber(41), 41);
    });
    test('noktalı metni ondalık olarak okur', () {
      expect(parseHaremNumber('4148.25'), 4148.25);
      expect(parseHaremNumber('41.18'), 41.18);
    });
    test('virgüllü Türkçe biçimi okur', () {
      expect(parseHaremNumber('4.148,25'), 4148.25);
      expect(parseHaremNumber('41,18'), 41.18);
    });
    test('geçersiz değerlerde null döner', () {
      expect(parseHaremNumber(null), isNull);
      expect(parseHaremNumber(''), isNull);
      expect(parseHaremNumber('abc'), isNull);
      expect(parseHaremNumber(double.nan), isNull);
      expect(parseHaremNumber(double.infinity), isNull);
      expect(parseHaremNumber(<String>[]), isNull);
    });
  });

  group('parseHaremEvent', () {
    test('yedi portföy türünü ve onsu doğru kodlardan eşler', () {
      final s = parseHaremEvent(
        event([
          row('ALTIN', 4148, 4152),
          row('CEYREK_YENI', 6940, 6960),
          row('YARIM_YENI', 13880, 13920),
          row('TEK_YENI', 27760, 27840),
          row('USDTRY', 41.18, 41.22),
          row('EURTRY', 48.06, 48.14),
          row('GBPTRY', 55.24, 55.36),
          row('ONS', 3120.4, 3121.4),
        ]),
        receivedAt: _t,
      );

      expect(s.quotes.keys.toSet(), AssetKind.values.toSet());
      expect(s.quotes[AssetKind.gramGold]!.buy, 4148);
      expect(s.quotes[AssetKind.gramGold]!.sell, 4152);
      expect(s.quotes[AssetKind.quarterGold]!.buy, 6940);
      expect(s.quotes[AssetKind.fullGold]!.sell, 27840);
      expect(s.quotes[AssetKind.usd]!.buy, 41.18);
      expect(s.ons!.buy, 3120.4);
      expect(s.ons!.symbol, 'ONS');
      expect(s.quotes[AssetKind.usd]!.symbol, 'USDTRY');
    });

    test('has altın ALTIN koduyla eşlenir, 22 ayar karışmaz', () {
      final s = parseHaremEvent(
        event([row('AYAR22', 3800, 3900), row('ALTIN', 4148, 4152)]),
        receivedAt: _t,
      );
      expect(s.quotes[AssetKind.gramGold]!.buy, 4148);
      expect(s.quotes, hasLength(1));
    });

    test('bilinmeyen kodlar yok sayılır', () {
      final s = parseHaremEvent(
        event([row('OMRUSD', 0.38, 0.39), row('USDTRY', 41.18, 41.22)]),
        receivedAt: _t,
      );
      expect(s.quotes.keys, [AssetKind.usd]);
      expect(s.ons, isNull);
    });

    test('günlük değişim kapanışa göre satış fiyatından hesaplanır', () {
      final s = parseHaremEvent(
        event([row('ALTIN', 4150, 4160, 4120)]),
        receivedAt: _t,
      );
      expect(
        s.quotes[AssetKind.gramGold]!.changePercent,
        closeTo(0.9709, 0.001),
      );
    });

    test('kapanış yoksa ya da sıfırsa değişim sıfırdır', () {
      for (final k in [null, 0, '0', '']) {
        final s = parseHaremEvent(
          event([row('USDTRY', 41.18, 41.22, k)]),
          receivedAt: _t,
        );
        expect(s.quotes[AssetKind.usd]!.changePercent, 0, reason: '$k');
      }
    });

    test('düşüşte değişim negatiftir', () {
      final s = parseHaremEvent(
        event([row('EURTRY', 47, 48, 50)]),
        receivedAt: _t,
      );
      expect(s.quotes[AssetKind.eur]!.changePercent, closeTo(-4.0, 0.001));
    });

    test('metin olarak gelen sayılar okunur', () {
      final s = parseHaremEvent(
        event([row('USDTRY', '41.18', '41,22', '40.9')]),
        receivedAt: _t,
      );
      expect(s.quotes[AssetKind.usd]!.buy, 41.18);
      expect(s.quotes[AssetKind.usd]!.sell, 41.22);
    });

    test('bozuk ya da sıfır fiyatlı satır atlanır, diğerleri korunur', () {
      final s = parseHaremEvent(
        event([
          row('USDTRY', 'abc', 41.22),
          row('EURTRY', 0, 48.14),
          row('GBPTRY', -1, 55.36),
          row('ALTIN', 4148, null),
          row('CEYREK_YENI', 6940, 6960),
        ]),
        receivedAt: _t,
      );
      expect(s.quotes.keys, [AssetKind.quarterGold]);
    });

    test('alış satıştan büyükse satır yine de alınır (olduğu gibi)', () {
      final s = parseHaremEvent(
        event([row('USDTRY', 41.5, 41.2)]),
        receivedAt: _t,
      );
      expect(s.quotes[AssetKind.usd]!.buy, 41.5);
    });

    test('alınma zamanı receivedAt olur', () {
      final s = parseHaremEvent(
        event([row('ALTIN', 4148, 4152)]),
        receivedAt: _t,
      );
      expect(s.quotes[AssetKind.gramGold]!.updatedAt, _t);
    });

    test('beklenmeyen biçimler çökmez ve boş döner', () {
      for (final bad in [
        null,
        'x',
        5,
        <int>[],
        {'data': null},
        {'data': 'x'},
        {'data': []},
        {},
      ]) {
        final s = parseHaremEvent(bad, receivedAt: _t);
        expect(s.isEmpty, isTrue, reason: '$bad');
      }
    });

    test('Socket.IO’dan gelen dinamik Map türleri okunur', () {
      final dyn = <dynamic, dynamic>{
        'data': <dynamic, dynamic>{
          'USDTRY': <dynamic, dynamic>{
            'code': 'USDTRY',
            'alis': 41.18,
            'satis': 41.22,
            'kapanis': 41.0,
          },
        },
      };
      final s = parseHaremEvent(dyn, receivedAt: _t);
      expect(s.quotes[AssetKind.usd]!.buy, 41.18);
    });

    test('satırdaki code alanı yoksa anahtar kod olarak kullanılır', () {
      final s = parseHaremEvent({
        'data': {
          'USDTRY': {'alis': 41.18, 'satis': 41.22},
        },
      }, receivedAt: _t);
      expect(s.quotes[AssetKind.usd]!.symbol, 'USDTRY');
    });
  });

  group('gerçek akıştan alınmış satırlar (2026-11-28)', () {
    // Harem Altın'ın canlı akışından olduğu gibi alındı: sayılar bazen metin bazen
    // sayı, fazladan alanlar (dir, dusuk, yuksek) var.
    final real = {
      'meta': {'time': 1795813709952},
      'data': {
        'USDTRY': {
          'code': 'USDTRY',
          'alis': '50.6420',
          'satis': '50.7980',
          'tarih': '28-11-2026 00:08:30',
          'dir': {'alis_dir': '', 'satis_dir': 'up'},
          'dusuk': '50.7950',
          'yuksek': '50.7990',
          'kapanis': 50.798,
        },
        'EURTRY': {
          'code': 'EURTRY',
          'alis': '55.1710',
          'satis': '55.4480',
          'tarih': '28-11-2026 00:08:30',
          'dir': {'alis_dir': '', 'satis_dir': 'up'},
          'dusuk': '55.4440',
          'yuksek': '55.4480',
          'kapanis': 55.624,
        },
        'ALTIN': {
          'code': 'ALTIN',
          'alis': '6063.750',
          'satis': '6124.600',
          'tarih': '28-11-2026 00:08:30',
          'dir': {'alis_dir': '', 'satis_dir': 'up'},
          'dusuk': '6124.200',
          'yuksek': '6124.670',
          'kapanis': 6034.1,
        },
        'CEYREK_YENI': {
          'code': 'CEYREK_YENI',
          'alis': 9884,
          'satis': 10172,
          'tarih': '28-11-2026 00:08:31',
          'dir': {'alis_dir': '', 'satis_dir': ''},
          'dusuk': 10171,
          'yuksek': 10172,
          'kapanis': 10022,
        },
        'CEYREK_ESKI': {
          'code': 'CEYREK_ESKI',
          'alis': 9854,
          'satis': 10111,
          'kapanis': 9991,
        },
        'AYAR22': {
          'code': 'AYAR22',
          'alis': '5516.010',
          'satis': '5737.120',
          'kapanis': 5652.05,
        },
        'ONS': {
          'code': 'ONS',
          'alis': '3643.20',
          'satis': '3643.60',
          'tarih': '27-11-2026 22:14:59',
          'dusuk': 3558.7,
          'yuksek': '3685.10',
          'kapanis': 3567.2,
        },
      },
    };

    test('has altın, çeyrek ve dövizler doğru okunur', () {
      final s = parseHaremEvent(real, receivedAt: _t);
      expect(s.quotes[AssetKind.gramGold]!.buy, 6063.75);
      expect(s.quotes[AssetKind.gramGold]!.sell, 6124.6);
      expect(s.quotes[AssetKind.quarterGold]!.buy, 9884);
      expect(s.quotes[AssetKind.usd]!.buy, 50.642);
      expect(s.quotes[AssetKind.eur]!.sell, 55.448);
    });

    test('eski çeyrek ve 22 ayar karışmaz', () {
      final s = parseHaremEvent(real, receivedAt: _t);
      expect(s.quotes[AssetKind.quarterGold]!.symbol, 'CEYREK_YENI');
      expect(s.quotes[AssetKind.gramGold]!.symbol, 'ALTIN');
      expect(s.quotes.length, 4);
    });

    test('değişim sitedeki formülle tutar (satış, kapanışa göre)', () {
      final s = parseHaremEvent(real, receivedAt: _t);
      expect(s.quotes[AssetKind.usd]!.changePercent, closeTo(0.0, 0.0001));
      expect(s.quotes[AssetKind.eur]!.changePercent, closeTo(-0.3164, 0.001));
      expect(s.quotes[AssetKind.gramGold]!.changePercent, closeTo(1.5, 0.01));
      expect(s.ons!.changePercent, closeTo(2.1417, 0.001));
    });

    test('ons okunur', () {
      final s = parseHaremEvent(real, receivedAt: _t);
      expect(s.ons!.buy, 3643.2);
      expect(s.ons!.sell, 3643.6);
    });
  });
}
