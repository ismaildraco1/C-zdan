import '../../domain/asset_kind.dart';
import '../../domain/models.dart';

/// Harem Altın ürün kodları ile portföy türleri arasındaki eşleşme.
///
/// - Gram altın: `ALTIN` (has altın, 24 ayar). 22 ayar (`AYAR22`) kullanılmaz.
/// - Çeyrek, yarım, tam: güncel yıl sikkeleri (`*_YENI`). Eski sikkeler (`*_ESKI`) kullanılmaz.
const Map<AssetKind, String> haremCodes = {
  AssetKind.gramGold: 'ALTIN',
  AssetKind.quarterGold: 'CEYREK_YENI',
  AssetKind.halfGold: 'YARIM_YENI',
  AssetKind.fullGold: 'TEK_YENI',
  AssetKind.usd: 'USDTRY',
  AssetKind.eur: 'EURTRY',
  AssetKind.gbp: 'GBPTRY',
};

/// Ons altın (USD) yalnızca Piyasa ekranında gösterilir.
const String haremOnsCode = 'ONS';

final Map<String, AssetKind> _kindByCode = {
  for (final e in haremCodes.entries) e.value: e.key,
};

/// Bir akış olayından çıkarılan fiyatlar.
class HaremSnapshot {
  const HaremSnapshot(this.quotes, this.ons);

  final Map<AssetKind, Quote> quotes;
  final Quote? ons;

  bool get isEmpty => quotes.isEmpty && ons == null;
}

/// Sayıyı okur. Sayı ya da metin gelebilir:
/// - `4148.25`, `'4148.25'` → noktalı metin ondalık sayılır (makine biçimi)
/// - `'4.148,25'`, `'41,18'` → virgül varsa Türkçe biçimdir (nokta binlik)
/// Geçersiz, boş ya da sonsuz değerde `null` döner.
double? parseHaremNumber(Object? value) {
  if (value is num) return value.isFinite ? value.toDouble() : null;
  if (value is! String) return null;
  var s = value.trim();
  if (s.isEmpty) return null;
  if (s.contains(',')) s = s.replaceAll('.', '').replaceAll(',', '.');
  final d = double.tryParse(s);
  return (d != null && d.isFinite) ? d : null;
}

/// Bir `price_changed` olayını fiyatlara çevirir. Beklenmeyen biçimde çökmez,
/// boş sonuç döner. Bozuk ya da sıfır/negatif fiyatlı satır atlanır, diğerleri
/// korunur. Günlük değişim sitedeki gibi satış fiyatının kapanışa göre farkıdır.
HaremSnapshot parseHaremEvent(Object? event, {required DateTime receivedAt}) {
  final quotes = <AssetKind, Quote>{};
  Quote? ons;
  if (event is! Map) return HaremSnapshot(quotes, ons);
  final data = event['data'];
  if (data is! Map) return HaremSnapshot(quotes, ons);

  for (final entry in data.entries) {
    final row = entry.value;
    if (row is! Map) continue;
    final code = (row['code'] ?? entry.key).toString();
    final kind = _kindByCode[code];
    if (kind == null && code != haremOnsCode) continue;

    final buy = parseHaremNumber(row['alis']);
    final sell = parseHaremNumber(row['satis']);
    if (buy == null || sell == null || buy <= 0 || sell <= 0) continue;
    final close = parseHaremNumber(row['kapanis']);
    final change = (close != null && close > 0)
        ? 100 * (sell - close) / close
        : 0.0;

    final quote = Quote(
      symbol: code,
      buy: buy,
      sell: sell,
      changePercent: change,
      updatedAt: receivedAt,
    );
    if (kind != null) {
      quotes[kind] = quote;
    } else {
      ons = quote;
    }
  }
  return HaremSnapshot(quotes, ons);
}
