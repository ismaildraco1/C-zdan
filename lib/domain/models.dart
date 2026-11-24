import 'asset_kind.dart';

/// Bir ürünün anlık fiyatı. Net değer `buy` (alış) üzerinden hesaplanır.
class Quote {
  const Quote({
    required this.symbol,
    required this.buy,
    required this.sell,
    required this.changePercent,
    required this.updatedAt,
  });

  final String symbol;
  final double buy;
  final double sell;

  /// Günlük değişim, yüzde olarak. Negatif değer düşüş demektir.
  final double changePercent;
  final DateTime updatedAt;
}

/// Kullanıcının portföyündeki tek bir kayıt.
class Holding {
  const Holding({
    required this.id,
    required this.kind,
    required this.amount,
    required this.note,
  });

  final String id;
  final AssetKind kind;
  final double amount;
  final String note;

  Holding copyWith({double? amount, String? note}) => Holding(
        id: id,
        kind: kind,
        amount: amount ?? this.amount,
        note: note ?? this.note,
      );
}
