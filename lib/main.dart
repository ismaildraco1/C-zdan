import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/config.dart';
import 'state/auth_controller.dart';
import 'state/market_controller.dart';
import 'state/portfolio_controller.dart';

/// Supabase ayarı `--dart-define` ile verilir (bkz. README). Verilmezse hesap ve
/// varlıklar sahtedir: uygulama kapanınca hesaplar silinir.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await createServices(AppConfig.fromEnvironment);
  if (!services.usingSupabase) {
    debugPrint(
      'Supabase ayarı yok: sahte hesap ve cihaz içi varlıklar kullanılıyor.',
    );
  }
  final market = MarketController(services.feed);
  final portfolio = PortfolioController(services.holdings, market);
  final auth = AuthController(services.auth);
  await auth.restore();
  runApp(CuzdanApp(auth: auth, market: market, portfolio: portfolio));
}
