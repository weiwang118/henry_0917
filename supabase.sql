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


-- torn 的结构（每张票各自带一个修改时间，毫秒）：
--   { "0": {"torn": "2026-10-08", "at": 1760...},   撕了
--     "3": {"torn": null,         "at": 1761...} }  还原过
-- 合并时同一张票比 at，晚的赢。所以你在这里改，他手机下次打开会接受。


-- ── 看他撕到第几张 ────────────────────────────────
-- select
--   (k::int) + 1                                   as 第几张,
--   v ->> 'torn'                                   as 撕票日期,
--   to_timestamp(((v ->> 'at')::bigint) / 1000)
--     at time zone 'Asia/Shanghai'                 as 改动时间
-- from public.progress, jsonb_each(torn) as e(k, v)
-- where id = 'henry' and v ->> 'torn' is not null
-- order by 1;


-- ── 远程把某一张改回未撕（把 '0' 换成票的序号减一）────
-- update public.progress
-- set torn = torn || jsonb_build_object(
--       '0', jsonb_build_object('torn', null,
--            'at', (extract(epoch from now()) * 1000)::bigint)),
--     updated_at = now()
-- where id = 'henry';


-- ── 全部清空（交付前跑一次，把测试数据扫干净）──────────
-- update public.progress set torn = '{}'::jsonb, updated_at = now()
-- where id = 'henry';
