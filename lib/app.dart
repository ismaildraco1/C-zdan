import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'domain/models.dart';
import 'state/auth_controller.dart';
import 'ui/account/hesap_sil.dart';
import 'ui/account/profil.dart';
import 'ui/assets/detay.dart';
import 'ui/assets/varlik_ekle.dart';
import 'state/market_controller.dart';
import 'state/portfolio_controller.dart';
import 'ui/auth/giris.dart';
import 'ui/auth/kayit.dart';
import 'ui/auth/sifre.dart';
import 'ui/auth/sifre_gonderildi.dart';
import 'ui/home/shell.dart';

class CuzdanApp extends StatefulWidget {
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
  State<CuzdanApp> createState() => _CuzdanAppState();
}

class _CuzdanAppState extends State<CuzdanApp> {
  // Oturumdaki hesabın kimliği. Değişince varlıklar o hesaba göre yeniden yüklenir.
  String? _session;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_syncSession);
    _syncSession();
  }

  @override
  void dispose() {
    widget.auth.removeListener(_syncSession);
    super.dispose();
  }

  void _syncSession() {
    final id = widget.auth.user?.email;
    if (id == _session) return;
    _session = id;
    if (id == null) {
      widget.portfolio.reset();
    } else {
      widget.portfolio.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: widget.auth),
        ChangeNotifierProvider<MarketController>.value(value: widget.market),
        ChangeNotifierProvider<PortfolioController>.value(
          value: widget.portfolio,
        ),
      ],
      child: MaterialApp(
        title: 'Cüzdan',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(useGoogleFonts: widget.useGoogleFonts),
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
    case '/ekle':
      page = VarlikEkleScreen(editing: settings.arguments as Holding?);
    case '/detay':
      page = DetayScreen(holding: settings.arguments as Holding);
    case '/profil':
      page = const ProfilScreen();
    case '/hesap-sil':
      page = const HesapSilScreen();
    case '/sifre':
      page = const SifreScreen();
    case '/sifre-gonderildi':
      page = SifreGonderildiScreen(email: settings.arguments as String);
    default:
      return null;
  }
  return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
}
