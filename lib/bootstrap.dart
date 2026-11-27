import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'core/config.dart';
import 'data/auth_repository.dart';
import 'data/harem/harem_price_feed.dart';
import 'data/holdings_repository.dart';
import 'data/price_feed.dart';
import 'data/supabase/supabase_auth_repository.dart';
import 'data/supabase/supabase_holdings_repository.dart';

/// Uygulamanın dış dünyayla konuşan üç parçası.
class Services {
  const Services({
    required this.auth,
    required this.holdings,
    required this.feed,
    required this.usingSupabase,
  });

  final AuthRepository auth;
  final HoldingsRepository holdings;
  final PriceFeed feed;

  /// `false` ise hesap ve varlıklar sahtedir (ayar verilmemiştir).
  final bool usingSupabase;
}

typedef SupabaseConnector = Future<sb.SupabaseClient> Function(
  AppConfig config,
);

Future<sb.SupabaseClient> _connect(AppConfig config) async {
  await sb.Supabase.initialize(
    url: config.url,
    publishableKey:
        config.anonKey, // genel (publishable ya da eski anon) anahtar
  );
  return sb.Supabase.instance.client;
}

/// Ayar verilmişse hesap ve varlıklar için Supabase'i, verilmemişse sahte
/// servisleri kurar. Fiyat kaynağı bunlardan bağımsızdır: `PRICE_SOURCE=harem`
/// ise canlı Harem Altın akışı, değilse örnek fiyatlar. Harem bağlantısı ilk
/// dinleyiciye kadar açılmaz.
Future<Services> createServices(
  AppConfig config, {
  SupabaseConnector connect = _connect,
  HaremConnection Function()? haremConnection,
}) async {
  final PriceFeed feed = config.useHarem
      ? HaremPriceFeed((haremConnection ?? SocketIoHaremConnection.new)())
      : FakePriceFeed();
  if (!config.isConfigured) {
    return Services(
      auth: FakeAuthRepository(),
      holdings: LocalHoldingsRepository(),
      feed: feed,
      usingSupabase: false,
    );
  }
  final client = await connect(config);
  return Services(
    auth: SupabaseAuthRepository(client),
    holdings: SupabaseHoldingsRepository(client),
    feed: feed,
    usingSupabase: true,
  );
}
