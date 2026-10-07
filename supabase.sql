-- 在 Supabase 后台 → SQL Editor → New query，整段粘进去跑一次就行。

create table if not exists public.progress (
  id          text primary key,
  torn        jsonb       not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

-- 开行级权限。不开的话 anon key 能读写整张表，必须开。
alter table public.progress enable row level security;

-- 只放行 id = 'henry' 这一行，而且只给读、插、改。
-- 没有 delete 策略 = 任何人都删不掉这行记录。
drop policy if exists "read henry"   on public.progress;
drop policy if exists "insert henry" on public.progress;
drop policy if exists "update henry" on public.progress;

create policy "read henry"   on public.progress
  for select to anon using (id = 'henry');

create policy "insert henry" on public.progress
  for insert to anon with check (id = 'henry');

create policy "update henry" on public.progress
  for update to anon using (id = 'henry') with check (id = 'henry');

-- 先占个空位，省得第一次打开页面时读到空结果。
insert into public.progress (id, torn) values ('henry', '{}'::jsonb)
  on conflict (id) do nothing;


-- ── 以后你想看他撕到第几张，跑这个 ──────────────────
-- select
--   id,
--   jsonb_object_keys(torn) as 第几张,
--   torn,
--   updated_at at time zone 'Asia/Shanghai' as 最后更新
-- from public.progress where id = 'henry';
