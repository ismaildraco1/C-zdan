import 'dart:ui';

import 'package:cuzdan/app.dart';
import 'package:cuzdan/data/auth_repository.dart';
import 'package:cuzdan/data/holdings_repository.dart';
import 'package:cuzdan/domain/models.dart';
import 'package:cuzdan/state/auth_controller.dart';
import 'package:cuzdan/state/market_controller.dart';
import 'package:cuzdan/state/portfolio_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_feed.dart';

class MemoryHoldingsRepository implements HoldingsRepository {
  List<Holding> _data = [];

  @override
  Future<List<Holding>> load() async => List.of(_data);

  @override
  Future<void> save(List<Holding> holdings) async => _data = List.of(holdings);
}

class Harness {
  Harness(this.repo, this.feed, this.auth, this.market, this.portfolio);
  final FakeAuthRepository repo;
  final TestFeed feed;
  final AuthController auth;
  final MarketController market;
  final PortfolioController portfolio;
}

/// Uygulamayı 390x844'lük sahte bir telefonda, sahte servislerle açar.
Future<Harness> pumpApp(
  WidgetTester tester, {
  bool registered = false,
  bool signedIn = false,
}) async {
  final repo = FakeAuthRepository();
  if (registered || signedIn) {
    await repo.signUp(
      firstName: 'Ayşe',
      lastName: 'Yılmaz',
      email: 'ayse.yilmaz@ornek.com',
      password: 'ornek-sifre',
    );
    if (!signedIn) await repo.signOut();
  }
  final feed = TestFeed();
  final market = MarketController(feed);
  final portfolio = PortfolioController(MemoryHoldingsRepository(), market);
  final auth = AuthController(repo);
  await portfolio.load();
  await auth.restore();

  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  addTearDown(market.dispose);

  await tester.pumpWidget(CuzdanApp(
    auth: auth,
    market: market,
    portfolio: portfolio,
    useGoogleFonts: false,
  ));
  await tester.pumpAndSettle();
  return Harness(repo, feed, auth, market, portfolio);
}
