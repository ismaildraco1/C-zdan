import 'package:cuzdan/data/auth_repository.dart';
import 'package:cuzdan/data/holdings_repository.dart';
import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

/// Sunucudaki gibi: varlıklar o an oturumdaki hesaba aittir.
class UserScopedHoldings implements HoldingsRepository {
  UserScopedHoldings(this._auth);
  final FakeAuthRepository _auth;
  final Map<String, List<Holding>> data = {};

  @override
  Future<List<Holding>> load() async {
    final u = await _auth.currentUser();
    return u == null ? [] : List.of(data[u.email] ?? const []);
  }

  @override
  Future<void> save(List<Holding> holdings) async {
    final u = await _auth.currentUser();
    if (u != null) data[u.email] = List.of(holdings);
  }
}

Future<FakeAuthRepository> twoAccounts() async {
  final auth = FakeAuthRepository();
  for (final e in ['a@ornek.com', 'b@ornek.com']) {
    await auth.signUp(
      firstName: e[0],
      lastName: 'X',
      email: e,
      password: '12345678',
    );
    await auth.signOut();
  }
  return auth;
}

void main() {
  testWidgets('giriş yapınca o hesabın varlıkları görünür', (tester) async {
    final auth = await twoAccounts();
    final store = UserScopedHoldings(auth)
      ..data['a@ornek.com'] = [
        const Holding(id: 'h1', kind: AssetKind.usd, amount: 100, note: ''),
      ];
    final h = await pumpApp(tester, authRepo: auth, holdingsRepo: store);
    expect(find.text('Amerikan Doları'), findsNothing);

    await h.auth.signIn('a@ornek.com', '12345678');
    await tester.pumpAndSettle();

    expect(find.text('Amerikan Doları'), findsOneWidget);
  });

  testWidgets('çıkışta varlıklar bellekten ve ekrandan kalkar', (tester) async {
    final auth = await twoAccounts();
    final store = UserScopedHoldings(auth)
      ..data['a@ornek.com'] = [
        const Holding(id: 'h1', kind: AssetKind.usd, amount: 100, note: ''),
      ];
    final h = await pumpApp(tester, authRepo: auth, holdingsRepo: store);
    await h.auth.signIn('a@ornek.com', '12345678');
    await tester.pumpAndSettle();

    await h.auth.signOut();
    await tester.pumpAndSettle();

    expect(h.portfolio.holdings, isEmpty);
    expect(find.text('Amerikan Doları'), findsNothing);
  });

  testWidgets('başka hesapla girince öncekinin varlıkları görünmez', (
    tester,
  ) async {
    final auth = await twoAccounts();
    final store = UserScopedHoldings(auth)
      ..data['a@ornek.com'] = [
        const Holding(id: 'h1', kind: AssetKind.usd, amount: 100, note: ''),
      ]
      ..data['b@ornek.com'] = [
        const Holding(id: 'h2', kind: AssetKind.eur, amount: 5, note: ''),
      ];
    final h = await pumpApp(tester, authRepo: auth, holdingsRepo: store);

    await h.auth.signIn('a@ornek.com', '12345678');
    await tester.pumpAndSettle();
    await h.auth.signOut();
    await tester.pumpAndSettle();
    await h.auth.signIn('b@ornek.com', '12345678');
    await tester.pumpAndSettle();

    expect(find.text('Euro'), findsOneWidget);
    expect(find.text('Amerikan Doları'), findsNothing);
  });

  testWidgets('yeni hesapta eklenen varlık o hesaba yazılır', (tester) async {
    final auth = await twoAccounts();
    final store = UserScopedHoldings(auth);
    final h = await pumpApp(tester, authRepo: auth, holdingsRepo: store);
    await h.auth.signIn('b@ornek.com', '12345678');
    await tester.pumpAndSettle();

    await h.portfolio.add(AssetKind.gbp, 3, '');

    expect(store.data['b@ornek.com'], hasLength(1));
    expect(store.data['a@ornek.com'], isNull);
  });
}
