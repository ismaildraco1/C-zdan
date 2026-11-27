/// Supabase bağlantı ayarı. Koda gömülmez, derleme sırasında verilir:
///
///     flutter run \
///       --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///       --dart-define=SUPABASE_ANON_KEY=...genel anahtar... \
///       --dart-define=PRICE_SOURCE=harem
///
/// `PRICE_SOURCE=harem` canlı Harem Altın fiyatlarını açar; verilmezse örnek
/// (sahte) fiyatlar kullanılır.
///
/// Yalnızca genel (anon) anahtar kullanılır. `service_role` anahtarı uygulamaya
/// hiçbir zaman konmaz.
class AppConfig {
  const AppConfig({
    required this.url,
    required this.anonKey,
    this.priceSource = 'fake',
  });

  final String url;
  final String anonKey;

  /// `fake` (varsayılan) ya da `harem`.
  final String priceSource;

  /// Canlı Harem Altın fiyatları seçildi mi? Tanınmayan değer sahteye döner.
  bool get useHarem => priceSource.trim().toLowerCase() == 'harem';

  /// Ayar verilmemişse uygulama sahte servislerle çalışır.
  bool get isConfigured => anonKey.isNotEmpty && url.startsWith('https://');

  static const AppConfig fromEnvironment = AppConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    priceSource: String.fromEnvironment('PRICE_SOURCE', defaultValue: 'fake'),
  );
}
