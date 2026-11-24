import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/auth_repository.dart';
import 'data/holdings_repository.dart';
import 'data/price_feed.dart';
import 'state/auth_controller.dart';
import 'state/market_controller.dart';
import 'state/portfolio_controller.dart';

/// Şimdilik sahte fiyat ve hesap servisleriyle çalışır. Gerçek servisler
/// bağlanınca yalnızca aşağıdaki üç uygulama değiştirilir.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final market = MarketController(FakePriceFeed());
  final portfolio = PortfolioController(LocalHoldingsRepository(), market);
  final auth = AuthController(FakeAuthRepository());
  portfolio.load();
  auth.restore();
  runApp(CuzdanApp(auth: auth, market: market, portfolio: portfolio));
}
