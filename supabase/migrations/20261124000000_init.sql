-- Cüzdan: varlıklar tablosu ve hesap silme fonksiyonu.
-- Supabase SQL editöründe bir kez çalıştırın.

create table public.holdings (
  id         uuid primary key,
  user_id    uuid not null default auth.uid()
             references auth.users (id) on delete cascade,
  kind       text not null check (kind in (
               'gramGold', 'quarterGold', 'halfGold', 'fullGold',
               'usd', 'eur', 'gbp')),
  amount     numeric not null check (amount > 0),
  note       text not null default '',
  created_at timestamptz not null default now()
);

create index holdings_user_id_idx on public.holdings (user_id);

-- Satır düzeyinde güvenlik: herkes yalnızca kendi satırlarını görür ve değiştirir.
alter table public.holdings enable row level security;

create policy "holdings_select_own" on public.holdings
  for select to authenticated
  using (auth.uid() = user_id);

create policy "holdings_insert_own" on public.holdings
  for insert to authenticated
  with check (auth.uid() = user_id);

create policy "holdings_update_own" on public.holdings
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "holdings_delete_own" on public.holdings
  for delete to authenticated
  using (auth.uid() = user_id);

-- Hesap silme: istemci kendi auth kaydını silemez, bu fonksiyon silebilir.
-- Yalnızca giriş yapmış kullanıcı çağırabilir ve yalnızca kendi hesabını siler.
-- holdings satırları "on delete cascade" ile birlikte gider.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Oturum açık değil' using errcode = '28000';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
