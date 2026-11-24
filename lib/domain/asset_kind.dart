/// Portföye eklenebilen varlık türleri. Ons yalnızca Piyasa'da fiyat olarak görünür.
enum AssetKind {
  gramGold('Gram Altın', 'gr', isGold: true),
  quarterGold('Çeyrek Altın', 'adet', isGold: true),
  halfGold('Yarım Altın', 'adet', isGold: true),
  fullGold('Tam Altın', 'adet', isGold: true),
  usd('Amerikan Doları', 'USD', isGold: false),
  eur('Euro', 'EUR', isGold: false),
  gbp('İngiliz Sterlini', 'GBP', isGold: false);

  const AssetKind(this.label, this.unit, {required this.isGold});

  final String label;
  final String unit;
  final bool isGold;
}
