/// Varlığın sınıfı: simge, Piyasa filtresi ve fiyat biçimi buna göre seçilir.
enum AssetGroup { gold, silver, fx }

/// Portföye eklenebilen varlık türleri. Ons yalnızca Piyasa'da fiyat olarak görünür.
///
/// Kayıtlar türü **adıyla** saklar; adlar değiştirilmemeli. Yeni tür eklenince
/// `supabase/migrations` içindeki tür kısıtı da güncellenmeli.
enum AssetKind {
  gramGold('Gram Altın', 'gr', AssetGroup.gold),
  gold22('22 Ayar Altın', 'gr', AssetGroup.gold),
  quarterGold('Çeyrek Altın', 'adet', AssetGroup.gold),
  halfGold('Yarım Altın', 'adet', AssetGroup.gold),
  fullGold('Tam Altın', 'adet', AssetGroup.gold),
  silver('Gümüş', 'gr', AssetGroup.silver),
  usd('Amerikan Doları', 'USD', AssetGroup.fx),
  eur('Euro', 'EUR', AssetGroup.fx),
  gbp('İngiliz Sterlini', 'GBP', AssetGroup.fx);

  const AssetKind(this.label, this.unit, this.group);

  final String label;
  final String unit;
  final AssetGroup group;
}
