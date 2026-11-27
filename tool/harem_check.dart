// Harem Altın canlı fiyat akışını dinler ve uygulamanın gördüğü biçimde yazdırır.
//
//   dart run tool/harem_check.dart            # 15 sn dinler
//   dart run tool/harem_check.dart --saniye=30
//   dart run tool/harem_check.dart --ham      # ilk olayı ham olarak da yazar
//   dart run tool/harem_check.dart --url=ws://localhost:3999   # yerel sahte sunucu
//
// Çıktı "eksik" diyorsa ya da değerler beklenmedikse, çıktıyı olduğu gibi paylaş.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cuzdan/data/harem/harem_parser.dart';
import 'package:cuzdan/data/harem/harem_price_feed.dart';
import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/domain/models.dart';

Future<void> main(List<String> args) async {
  String arg(String name, String fallback) {
    for (final a in args) {
      if (a.startsWith('--$name=')) return a.substring(name.length + 3);
    }
    return fallback;
  }

  final seconds = int.tryParse(arg('saniye', '15')) ?? 15;
  final url = arg('url', haremSocketUrl);
  final raw = args.contains('--ham');

  final connection = SocketIoHaremConnection(url: url);
  final feed = HaremPriceFeed(connection);
  var events = 0;
  Object? first;

  final rawSub = connection.events.listen((e) {
    events++;
    first ??= e;
  });
  Map<AssetKind, Quote> latest = {};
  Quote? ons;
  final s1 = feed.quotes.listen((m) => latest = m);
  final s2 = feed.ons.listen((q) => ons = q);

  stdout.writeln('Bağlanılıyor: $url ($seconds sn dinlenecek)...');
  await Future<void>.delayed(Duration(seconds: seconds));

  stdout.writeln('\nAlınan olay sayısı: $events');
  if (events == 0) {
    stdout.writeln(
      'HİÇ OLAY GELMEDİ: bağlantı kurulamadı ya da piyasa kapalı.',
    );
  }
  if (raw && first != null) {
    final text = jsonEncode(first);
    stdout.writeln('\nİlk ham olay (${text.length} karakter):');
    stdout.writeln(text.length > 2500 ? '${text.substring(0, 2500)}...' : text);
  }

  stdout.writeln('\nUygulamanın gördüğü fiyatlar:');
  String f(double v) => v.toStringAsFixed(4);
  for (final kind in AssetKind.values) {
    final q = latest[kind];
    stdout.writeln(
      q == null
          ? '  ${kind.label.padRight(18)} EKSİK (kod: ${haremCodes[kind]})'
          : '  ${kind.label.padRight(18)} alış ${f(q.buy)}  satış ${f(q.sell)}  değişim %${q.changePercent.toStringAsFixed(2)}  [${q.symbol}]',
    );
  }
  final o = ons;
  stdout.writeln(
    o == null
        ? '  Ons Altın          EKSİK (kod: $haremOnsCode)'
        : '  Ons Altın          alış ${f(o.buy)}  satış ${f(o.sell)}  değişim %${o.changePercent.toStringAsFixed(2)}',
  );
  final missing = AssetKind.values.where((k) => latest[k] == null).length;
  stdout.writeln(
    missing == 0 && o != null
        ? '\nTAMAM: tüm türler geldi.'
        : '\nUYARI: ${missing + (o == null ? 1 : 0)} ürün gelmedi.',
  );

  await rawSub.cancel();
  await s1.cancel();
  await s2.cancel();
  feed.dispose();
}
