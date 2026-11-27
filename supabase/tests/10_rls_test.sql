-- Her adımın beklenen sonucu başlığında yazar. ERROR satırları BEKLENEN reddedilmelerdir.
\set ON_ERROR_STOP off
\pset pager off
insert into auth.users values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','a@x.com'),('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','b@x.com');

\echo '--- 1) A kendi satırını ekler (user_id sunucuda dolar)'
set role authenticated; set request.jwt.claim.sub = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
insert into public.holdings (id, kind, amount, note) values ('11111111-1111-4111-8111-111111111111','usd',100,'A-usd');
select kind, amount, user_id = auth.uid() as user_id_dogru from public.holdings;
reset role;

\echo '--- 2) B, A satırını GÖREMEZ / DEĞİŞTİREMEZ / SİLEMEZ'
set role authenticated; set request.jwt.claim.sub = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
select count(*) as b_gorur from public.holdings;
update public.holdings set amount = 999 where id = '11111111-1111-4111-8111-111111111111';
delete from public.holdings where id = '11111111-1111-4111-8111-111111111111';
reset role;
select amount as a_nin_miktari_degismedi from public.holdings;

\echo '--- 3) B, başkası adına satır ekleyemez'
set role authenticated; set request.jwt.claim.sub = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
insert into public.holdings (id, user_id, kind, amount) values ('22222222-2222-4222-8222-222222222222','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','eur',5);
reset role;

\echo '--- 4) B, A nın kimliğiyle upsert yapamaz (uygulamanın yaptığı gibi)'
set role authenticated; set request.jwt.claim.sub = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
insert into public.holdings (id, kind, amount, note) values ('11111111-1111-4111-8111-111111111111','usd',5,'ele-gecirme')
  on conflict (id) do update set amount = excluded.amount, note = excluded.note;
reset role;
select amount, note from public.holdings where id = '11111111-1111-4111-8111-111111111111';

\echo '--- 5) A kendi satırını upsert ile günceller'
set role authenticated; set request.jwt.claim.sub = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
insert into public.holdings (id, kind, amount, note) values ('11111111-1111-4111-8111-111111111111','usd',250,'A-usd-guncel')
  on conflict (id) do update set kind = excluded.kind, amount = excluded.amount, note = excluded.note;
select amount, note from public.holdings;
reset role;

\echo '--- 6) kısıtlar: miktar 0, bilinmeyen tür, anon erişimi'
set role authenticated; set request.jwt.claim.sub = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
insert into public.holdings (id, kind, amount) values ('33333333-3333-4333-8333-333333333333','usd',0);
insert into public.holdings (id, kind, amount) values ('44444444-4444-4444-8444-444444444444','bitcoin',1);
reset role;
set role anon; reset request.jwt.claim.sub;
select count(*) as anon_gorur from public.holdings;
insert into public.holdings (id, kind, amount) values ('55555555-5555-4555-8555-555555555555','usd',1);
reset role;

\echo '--- 7) hesap silme: anon çağıramaz, oturumsuz authenticated hata alır'
set role anon; select public.delete_my_account(); reset role;
set role authenticated; reset request.jwt.claim.sub; select public.delete_my_account(); reset role;

\echo '--- 8) B hesabını siler: yalnızca B gider, A ve satırı kalır, B nin satırları cascade ile gider'
set role authenticated; set request.jwt.claim.sub = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
insert into public.holdings (id, kind, amount) values ('66666666-6666-4666-8666-666666666666','gbp',7);
select count(*) as b_satiri_once from public.holdings;
select public.delete_my_account();
reset role;
select (select count(*) from auth.users) as kalan_kullanici, (select count(*) from public.holdings where user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb') as b_satiri_sonra, (select count(*) from public.holdings where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') as a_satiri;
