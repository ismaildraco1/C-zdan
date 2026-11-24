import 'package:cuzdan/data/holdings_repository.dart';
import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('boş depoda load boş liste döndürür', () async {
    expect(await LocalHoldingsRepository().load(), isEmpty);
  });

  test('save sonrası load aynı kayıtları döndürür', () async {
    final repo = LocalHoldingsRepository();
    await repo.save(const [
      Holding(id: 'a', kind: AssetKind.usd, amount: 2500, note: 'Tatil'),
      Holding(id: 'b', kind: AssetKind.gramGold, amount: 40.5, note: ''),
    ]);

    final loaded = await LocalHoldingsRepository().load();

    expect(loaded.map((h) => h.id), ['a', 'b']);
    expect(loaded[0].kind, AssetKind.usd);
    expect(loaded[0].amount, 2500);
    expect(loaded[0].note, 'Tatil');
    expect(loaded[1].amount, 40.5);
  });

  test('bozuk kayıtlı veri çökmez, boş liste döner', () async {
    SharedPreferences.setMockInitialValues({'holdings': 'bozuk{json'});
    expect(await LocalHoldingsRepository().load(), isEmpty);
  });
}
