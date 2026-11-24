import 'package:cuzdan/data/holdings_repository.dart';
import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/state/market_controller.dart';
import 'package:cuzdan/state/portfolio_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_feed.dart';
import '../support/flaky_repository.dart';

void main() {
  late TestFeed feed;
  late MarketController market;
  late PortfolioController portfolio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    feed = TestFeed();
    market = MarketController(feed);
    portfolio = PortfolioController(LocalHoldingsRepository(), market);
    await portfolio.load();
  });

  tearDown(() => market.dispose());

  test('eklenen varlık depoya yazılır ve yeniden yüklenince gelir', () async {
    await portfolio.add(AssetKind.usd, 2500, 'Tatil');

    final fresh = PortfolioController(LocalHoldingsRepository(), market);
    await fresh.load();

    expect(fresh.holdings.single.amount, 2500);
    expect(fresh.holdings.single.note, 'Tatil');
  });

  test('update miktarı ve notu değiştirir', () async {
    await portfolio.add(AssetKind.usd, 100, '');
    final id = portfolio.holdings.single.id;
    await portfolio.update(id, 250, 'Yeni');
    expect(portfolio.holdings.single.amount, 250);
    expect(portfolio.holdings.single.note, 'Yeni');
  });

  test('remove varlığı kaldırır', () async {
    await portfolio.add(AssetKind.usd, 100, '');
    await portfolio.remove(portfolio.holdings.single.id);
    expect(portfolio.holdings, isEmpty);
  });

  test('aynı türden iki varlık ayrı satır olur', () async {
    await portfolio.add(AssetKind.usd, 100, '');
    await portfolio.add(AssetKind.usd, 50, '');
    expect(portfolio.holdings, hasLength(2));
    expect(portfolio.holdings[0].id, isNot(portfolio.holdings[1].id));
  });

  test('toplam fiyat gelince değişir', () async {
    await portfolio.add(AssetKind.usd, 100, '');
    expect(portfolio.total, 0);

    feed.push({AssetKind.usd: quote('USD', 41.18)});

    expect(portfolio.total, closeTo(4118.0, 0.005));
  });

  test('fiyat yokken valueOf null döner', () async {
    await portfolio.add(AssetKind.eur, 10, '');
    expect(portfolio.valueOf(portfolio.holdings.single), isNull);
  });

  test('fiyat gelince valueOf alış fiyatıyla hesaplar', () async {
    await portfolio.add(AssetKind.eur, 10, '');
    feed.push({AssetKind.eur: quote('EUR', 48.06)});
    expect(portfolio.valueOf(portfolio.holdings.single), closeTo(480.6, 0.005));
  });

  test('clear tüm varlıkları siler ve depoya yazar', () async {
    await portfolio.add(AssetKind.usd, 100, '');
    await portfolio.add(AssetKind.eur, 10, '');
    await portfolio.clear();

    expect(portfolio.holdings, isEmpty);
    final fresh = PortfolioController(LocalHoldingsRepository(), market);
    await fresh.load();
    expect(fresh.holdings, isEmpty);
  });

  test('boş portföyde toplam sıfırdır', () {
    expect(portfolio.total, 0);
    expect(portfolio.holdings, isEmpty);
  });

  group('depo hatası', () {
    test(
      'add başarısızsa liste geri döner, hata yazar ve false verir',
      () async {
        final repo = FlakyHoldingsRepository();
        final p = PortfolioController(repo, market);
        await p.load();
        await p.add(AssetKind.usd, 100, '');
        repo.failing = true;

        final ok = await p.add(AssetKind.eur, 10, '');

        expect(ok, isFalse);
        expect(p.holdings.map((h) => h.kind), [AssetKind.usd]);
        expect(
          p.error,
          'Değişiklik kaydedilemedi. Bağlantını kontrol edip tekrar dene.',
        );
      },
    );

    test('update ve remove başarısızsa eski haline döner', () async {
      final repo = FlakyHoldingsRepository();
      final p = PortfolioController(repo, market);
      await p.load();
      await p.add(AssetKind.usd, 100, 'a');
      final id = p.holdings.single.id;
      repo.failing = true;

      expect(await p.update(id, 999, 'b'), isFalse);
      expect(p.holdings.single.amount, 100);
      expect(p.holdings.single.note, 'a');

      expect(await p.remove(id), isFalse);
      expect(p.holdings, hasLength(1));
    });

    test('sonraki başarılı işlem hatayı temizler', () async {
      final repo = FlakyHoldingsRepository();
      final p = PortfolioController(repo, market);
      await p.load();
      repo.failing = true;
      await p.add(AssetKind.usd, 1, '');
      expect(p.error, isNotNull);

      repo.failing = false;
      expect(await p.add(AssetKind.usd, 1, ''), isTrue);
      expect(p.error, isNull);
      expect(p.holdings, hasLength(1));
    });

    test('load başarısızsa liste boş kalır ve hata yazar', () async {
      final repo = FlakyHoldingsRepository()..failing = true;
      final p = PortfolioController(repo, market);
      await p.load();
      expect(p.holdings, isEmpty);
      expect(p.error, isNotNull);
    });
  });

  test('reset listeyi ve hatayı depoya yazmadan temizler', () async {
    final repo = FlakyHoldingsRepository();
    final p = PortfolioController(repo, market);
    await p.load();
    await p.add(AssetKind.usd, 1, '');
    final saves = repo.saves;

    p.reset();

    expect(p.holdings, isEmpty);
    expect(p.error, isNull);
    expect(repo.saves, saves);
  });
}
