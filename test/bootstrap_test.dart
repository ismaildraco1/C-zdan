import 'package:cuzdan/bootstrap.dart';
import 'package:cuzdan/core/config.dart';
import 'package:cuzdan/data/auth_repository.dart';
import 'package:cuzdan/data/holdings_repository.dart';
import 'package:cuzdan/data/price_feed.dart';
import 'package:cuzdan/data/supabase/supabase_auth_repository.dart';
import 'package:cuzdan/data/supabase/supabase_holdings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuzdan/data/harem/harem_price_feed.dart';

import 'support/fake_harem_connection.dart';
import 'support/fake_supabase.dart';

void main() {
  test(
    'ayar yoksa sahte servisler seçilir ve Supabase\'e bağlanılmaz',
    () async {
      var connected = false;
      final s = await createServices(
        const AppConfig(url: '', anonKey: ''),
        connect: (_) async {
          connected = true;
          return FakeSupabase().client;
        },
      );
      expect(s.auth, isA<FakeAuthRepository>());
      expect(s.holdings, isA<LocalHoldingsRepository>());
      expect(s.feed, isA<FakePriceFeed>());
      expect(s.usingSupabase, isFalse);
      expect(connected, isFalse);
      s.feed.dispose();
    },
  );

  test('ayar varsa Supabase uygulamaları seçilir, fiyat sahte kalır', () async {
    AppConfig? seen;
    final s = await createServices(
      const AppConfig(url: 'https://a.supabase.co', anonKey: 'k'),
      connect: (c) async {
        seen = c;
        return FakeSupabase().client;
      },
    );
    expect(s.auth, isA<SupabaseAuthRepository>());
    expect(s.holdings, isA<SupabaseHoldingsRepository>());
    expect(s.feed, isA<FakePriceFeed>());
    expect(s.usingSupabase, isTrue);
    expect(seen?.url, 'https://a.supabase.co');
    s.feed.dispose();
  });

  test('PRICE_SOURCE=harem Harem akışını kurar ve hemen bağlanmaz', () async {
    final conn = FakeHaremConnection();
    final s = await createServices(
      const AppConfig(url: '', anonKey: '', priceSource: 'harem'),
      haremConnection: () => conn,
    );
    expect(s.feed, isA<HaremPriceFeed>());
    expect(s.feed.sourceName, 'Harem Altın');
    expect(conn.connectCalls, 0); // ilk dinleyiciye kadar bağlanmaz
    s.feed.dispose();
  });

  test('Harem seçili değilse sahte akış kurulur', () async {
    final s = await createServices(
      const AppConfig(url: '', anonKey: ''),
      haremConnection: () => throw StateError('çağrılmamalı'),
    );
    expect(s.feed, isA<FakePriceFeed>());
    s.feed.dispose();
  });
}
