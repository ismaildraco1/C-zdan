-- 22 ayar altın ve gümüş türlerini ekler.
-- Supabase SQL editöründe, ilk dosyadan (init) sonra bir kez çalıştırın.

alter table public.holdings drop constraint holdings_kind_check;

alter table public.holdings add constraint holdings_kind_check check (kind in (
  'gramGold', 'gold22', 'quarterGold', 'halfGold', 'fullGold', 'silver',
  'usd', 'eur', 'gbp'));
