import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/domain/models.dart';
import 'package:cuzdan/domain/portfolio.dart';
import 'package:flutter_test/flutter_test.dart';

Quote q(String symbol, double buy) => Quote(
      symbol: symbol,
      buy: buy,
      sell: buy + 1,
      changePercent: 0.1,
      updatedAt: DateTime(2026, 11, 16, 14, 32),
    );

Holding h(String id, AssetKind kind, double amount) =>
    Holding(id: id, kind: kind, amount: amount, note: '');

final quotes = <AssetKind, Quote>{
  AssetKind.gramGold: q('GRAM', 4148),
  AssetKind.quarterGold: q('CEYREK', 6940),
  AssetKind.usd: q('USD', 41.18),
  AssetKind.eur: q('EUR', 48.06),
  AssetKind.gbp: q('GBP', 55.24),
};

void main() {
  test('tasarımdaki örnek portföy 415.206,00 TL eder', () {
    final holdings = [
      h('1', AssetKind.gramGold, 40),
      h('2', AssetKind.quarterGold, 8),
      h('3', AssetKind.usd, 2500),
      h('4', AssetKind.eur, 1200),
      h('5', AssetKind.gbp, 600),
    ];
    expect(netValue(holdings, quotes), closeTo(415206.00, 0.005));
  });

  test('boş portföy sıfır eder', () {
    expect(netValue(const [], quotes), 0);
  });

  test('fiyatı olmayan varlığın değeri null ve toplamda sayılmaz', () {
    final holdings = [
      h('1', AssetKind.usd, 100),
      h('2', AssetKind.halfGold, 3),
    ];
    expect(rowValue(holdings[1], quotes), isNull);
    expect(netValue(holdings, quotes), closeTo(4118.0, 0.005));
  });

  test('aynı türden iki varlık da toplamda sayılır', () {
    final holdings = [
      h('1', AssetKind.usd, 100),
      h('2', AssetKind.usd, 50),
    ];
    expect(netValue(holdings, quotes), closeTo(6177.0, 0.005));
  });

  group('dayChange', () {
    Quote qc(double buy, double change) => Quote(
          symbol: 'X',
          buy: buy,
          sell: buy + 1,
          changePercent: change,
          updatedAt: DateTime(2026, 11, 16),
        );

    test('tek varlıkta yüzde fiyatın yüzdesine eşittir', () {
      final r = dayChange(
        [h('1', AssetKind.usd, 100)],
        {AssetKind.usd: qc(41.18, 1.0)},
      );
      expect(r.percent, closeTo(1.0, 0.0001));
      expect(r.amount, closeTo(4118.0 - 4118.0 / 1.01, 0.005));
    });

    test('artış ve düşüş birbirini götürür', () {
      final r = dayChange(
        [h('1', AssetKind.usd, 100), h('2', AssetKind.eur, 100)],
        {AssetKind.usd: qc(10, 10), AssetKind.eur: qc(10, -8.3333333333)},
      );
      expect(r.amount, closeTo(0, 0.01));
    });

    test('boş portföyde sıfır döner', () {
      final r = dayChange(const [], const {});
      expect(r.amount, 0);
      expect(r.percent, 0);
    });

    test('fiyatı olmayan varlık hesaba girmez', () {
      final r = dayChange([h('1', AssetKind.halfGold, 2)], const {});
      expect(r.amount, 0);
      expect(r.percent, 0);
    });
  });

  test('rowValue miktarı alış fiyatıyla çarpar', () {
    expect(rowValue(h('1', AssetKind.usd, 2500), quotes),
        closeTo(102950.0, 0.005));
  });
}
