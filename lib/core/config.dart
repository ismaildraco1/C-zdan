/// Supabase bağlantı ayarı. Koda gömülmez, derleme sırasında verilir:
///
///     flutter run \
///       --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///       --dart-define=SUPABASE_ANON_KEY=...genel anahtar...
///
/// Yalnızca genel (anon) anahtar kullanılır. `service_role` anahtarı uygulamaya
/// hiçbir zaman konmaz.
class AppConfig {
  const AppConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  /// Ayar verilmemişse uygulama sahte servislerle çalışır.
  bool get isConfigured => anonKey.isNotEmpty && url.startsWith('https://');

  static const AppConfig fromEnvironment = AppConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
}
