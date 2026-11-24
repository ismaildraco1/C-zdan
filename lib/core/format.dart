import 'package:intl/intl.dart';

final NumberFormat _money = NumberFormat('#,##0.00', 'tr_TR');
final NumberFormat _rate = NumberFormat('0.0000', 'tr_TR');
final NumberFormat _pct = NumberFormat('0.00', 'tr_TR');

/// `415206` -> `₺ 415.206,00`
String formatTry(double v) => '₺ ${_money.format(v)}';

final NumberFormat _amount = NumberFormat('#,##0.##', 'tr_TR');

/// `4148` -> `4.148,00` (TL işareti olmadan)
String formatMoney(double v) => _money.format(v);

/// Miktarı gereksiz sıfır olmadan yazar: `2500` -> `2.500`, `40.5` -> `40,5`
String formatAmount(double v) => _amount.format(v);

/// `41.18` -> `41,1800`
String formatRate(double v) => _rate.format(v);

/// `0.62` -> `%0,62` (işaretsiz; yön ayrıca gösterilir)
String formatPercent(double v) => '%${_pct.format(v.abs())}';

final RegExp _thousandsOnly = RegExp(r'^[1-9]\d{0,2}(\.\d{3})+$');

/// Kullanıcının yazdığı miktarı okur.
///
/// - Virgül varsa ondalık ayracıdır, noktalar binliktir: `2.500,5` -> 2500,5
/// - Virgül yoksa ve yazı tam 3 haneli gruplardan oluşuyorsa nokta binliktir:
///   `2.500` -> 2500 (`1.234` de 1234 olur; Türkçe yazımda noktanın anlamı budur)
/// - Aksi halde nokta ondalık ayracıdır: `0.5`, `2.5`, `40.75`, `0.500` (= 0,5)
///
/// Geçersiz, sıfır, negatif veya sonsuz değerde `null` döner.
double? parseAmount(String input) {
  final s = input.trim();
  if (s.isEmpty) return null;
  final String normalized;
  if (s.contains(',')) {
    normalized = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (_thousandsOnly.hasMatch(s)) {
    normalized = s.replaceAll('.', '');
  } else {
    normalized = s;
  }
  final v = double.tryParse(normalized);
  if (v == null || !v.isFinite || v <= 0) return null;
  return v;
}
