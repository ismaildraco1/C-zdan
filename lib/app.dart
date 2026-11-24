import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'state/auth_controller.dart';
import 'state/market_controller.dart';
import 'state/portfolio_controller.dart';
import 'ui/auth/giris.dart';
import 'ui/auth/kayit.dart';
import 'ui/auth/sifre.dart';
import 'ui/auth/sifre_gonderildi.dart';
import 'ui/home/shell.dart';

class CuzdanApp extends StatelessWidget {
  const CuzdanApp({
    super.key,
    required this.auth,
    required this.market,
    required this.portfolio,
    this.useGoogleFonts = true,
  });

  final AuthController auth;
  final MarketController market;
  final PortfolioController portfolio;
  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: auth),
        ChangeNotifierProvider<MarketController>.value(value: market),
        ChangeNotifierProvider<PortfolioController>.value(value: portfolio),
      ],
      child: MaterialApp(
        title: 'Cüzdan',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(useGoogleFonts: useGoogleFonts),
        home: const _Root(),
        onGenerateRoute: _route,
      ),
    );
  }
}

/// Oturum yoksa Giriş, varsa ana ekran. Çıkış ve giriş bu kök üzerinden olur.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    return user == null ? const GirisScreen() : const HomeShell();
  }
}

Route<dynamic>? _route(RouteSettings settings) {
  final Widget page;
  switch (settings.name) {
    case '/kayit':
      page = const KayitScreen();
    case '/sifre':
      page = const SifreScreen();
    case '/sifre-gonderildi':
      page = SifreGonderildiScreen(email: settings.arguments as String);
    default:
      return null;
  }
  return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
}
