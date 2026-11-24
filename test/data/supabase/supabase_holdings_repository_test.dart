import 'package:cuzdan/data/supabase/supabase_holdings_repository.dart';
import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_supabase.dart';

const _id1 = '11111111-1111-4111-8111-111111111111';
const _id2 = '22222222-2222-4222-8222-222222222222';

void main() {
  late FakeSupabase fake;
  late SupabaseHoldingsRepository repo;

  setUp(() {
    fake = FakeSupabase();
    repo = SupabaseHoldingsRepository(fake.client);
  });

  group('load', () {
    test(
      'satırları Holding listesine çevirir (sayı ya da metin miktar)',
      () async {
        fake.on(
          'GET /rest/v1/holdings',
          (_) => json([
            {'id': _id1, 'kind': 'usd', 'amount': 2500, 'note': 'Tatil'},
            {'id': _id2, 'kind': 'gramGold', 'amount': '40.5', 'note': ''},
          ]),
        );

        final list = await repo.load();

        expect(list.map((h) => h.id), [_id1, _id2]);
        expect(list[0].kind, AssetKind.usd);
        expect(list[0].amount, 2500);
        expect(list[0].note, 'Tatil');
        expect(list[1].amount, 40.5);
        final q = fake
            .to('GET', '/rest/v1/holdings')
            .single
            .url
            .queryParameters;
        expect(q['select'], 'id,kind,amount,note');
        expect(q['order'], 'created_at.asc.nullslast,id.asc.nullslast');
      },
    );

    test('bilinmeyen türdeki satır atlanır, çökme olmaz', () async {
      fake.on(
        'GET /rest/v1/holdings',
        (_) => json([
          {'id': _id1, 'kind': 'bitcoin', 'amount': 1, 'note': ''},
          {'id': _id2, 'kind': 'eur', 'amount': 10, 'note': null},
        ]),
      );
      final list = await repo.load();
      expect(list.single.kind, AssetKind.eur);
      expect(list.single.note, '');
    });

    test('boş tablo boş liste verir', () async {
      fake.on('GET /rest/v1/holdings', (_) => json([]));
      expect(await repo.load(), isEmpty);
    });
  });

  group('save', () {
    test('önce hepsini upsert eder, sonra listede olmayanları siler', () async {
      fake.on('POST /rest/v1/holdings', (_) => http.Response('', 201));
      fake.on('DELETE /rest/v1/holdings', (_) => http.Response('', 204));

      await repo.save(const [
        Holding(id: _id1, kind: AssetKind.usd, amount: 2500, note: 'Tatil'),
        Holding(id: _id2, kind: AssetKind.gramGold, amount: 40.5, note: ''),
      ]);

      final up = fake.to('POST', '/rest/v1/holdings').single;
      expect(up.url.queryParameters['on_conflict'], 'id');
      expect(up.headers['prefer'], contains('resolution=merge-duplicates'));
      expect(
        up.body,
        isNull,
      ); // gövde liste; Call yalnızca nesne gövdesini tutar
      final del = fake.to('DELETE', '/rest/v1/holdings').single;
      expect(del.url.queryParameters['id'], 'not.in.("$_id1","$_id2")');
      expect(fake.calls.indexOf(up) < fake.calls.indexOf(del), isTrue);
    });

    test('upsert gövdesi kimlik, tür adı, miktar ve notu taşır', () async {
      String? sent;
      fake.on('POST /rest/v1/holdings', (r) {
        sent = r.body;
        return http.Response('', 201);
      });
      fake.on('DELETE /rest/v1/holdings', (_) => http.Response('', 204));

      await repo.save(const [
        Holding(id: _id1, kind: AssetKind.quarterGold, amount: 8, note: 'x'),
      ]);

      expect(sent, contains('"id":"$_id1"'));
      expect(sent, contains('"kind":"quarterGold"'));
      expect(sent, contains('"amount":8'));
      expect(sent, contains('"note":"x"'));
      expect(
        sent,
        isNot(contains('user_id')),
      ); // sunucu auth.uid() ile doldurur
    });

    test(
      'boş liste upsert yapmaz ve kullanıcının tüm satırlarını siler',
      () async {
        fake.on('DELETE /rest/v1/holdings', (_) => http.Response('', 204));

        await repo.save(const []);

        expect(fake.to('POST', '/rest/v1/holdings'), isEmpty);
        final del = fake.to('DELETE', '/rest/v1/holdings').single;
        expect(del.url.queryParameters.containsKey('id'), isTrue);
      },
    );

    test('ağ hatasında fırlatır', () async {
      fake.on(
        'POST /rest/v1/holdings',
        (_) => throw http.ClientException('yok'),
      );
      await expectLater(
        repo.save(const [
          Holding(id: _id1, kind: AssetKind.usd, amount: 1, note: ''),
        ]),
        throwsA(anything),
      );
    });

    test('sunucu reddederse fırlatır', () async {
      fake.on(
        'POST /rest/v1/holdings',
        (_) => json({'code': '42501', 'message': 'RLS reddetti'}, 403),
      );
      await expectLater(
        repo.save(const [
          Holding(id: _id1, kind: AssetKind.usd, amount: 1, note: ''),
        ]),
        throwsA(anything),
      );
      expect(fake.to('DELETE', '/rest/v1/holdings'), isEmpty);
    });
  });
}
