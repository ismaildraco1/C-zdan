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

/// Oturum açmış kullanıcının profil bilgileri.
class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone = '',
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  String get initials {
    final a = firstName.isEmpty ? '' : firstName[0];
    final b = lastName.isEmpty ? '' : lastName[0];
    return (a + b).toUpperCase();
  }

  String get fullName => '$firstName $lastName'.trim();
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
