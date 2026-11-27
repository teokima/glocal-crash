-- 글로컬 크래시 · Supabase 한 번에 설정 (SQL Editor에 통째로 붙여 넣고 Run)

-- 1) 온라인 랭킹
create table glocal_rank (
  sid text primary key,
  nick text not null check (char_length(nick) between 1 and 12),
  dept text check (char_length(dept) <= 16),
  score integer not null check (score between 0 and 100000000),
  pct real, theme text, updated_at timestamptz default now()
);
alter table glocal_rank enable row level security;
create policy rank_read on glocal_rank for select using (true);
create policy rank_insert on glocal_rank for insert with check (true);
create policy rank_update on glocal_rank for update using (true) with check (true);
revoke select (sid) on glocal_rank from anon;   -- 남의 sid를 못 읽게

-- 2) 계정(로그인) 커리어 저장
create table glocal_players (
  user_id uuid primary key default auth.uid() references auth.users on delete cascade,
  login text, nick text check (char_length(nick) <= 12), dept text check (char_length(dept) <= 16),
  best integer, total bigint, data jsonb, updated_at timestamptz default now()
);
alter table glocal_players enable row level security;
create policy own_select on glocal_players for select using (auth.uid() = user_id);
create policy own_insert on glocal_players for insert with check (auth.uid() = user_id);
create policy own_update on glocal_players for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 3) 익명 방문·플레이 시간 (관리자 모드 ?admin)
create table if not exists glocal_visits (
  sid text primary key, vid text not null,
  started timestamptz not null default now(), last timestamptz not null default now(),
  secs int not null default 0 check (secs between 0 and 86400),
  device text, theme text, diff text, week int, score bigint, mg int default 0, fp boolean default false
);
alter table glocal_visits enable row level security;
create policy "visits insert" on glocal_visits for insert to anon with check (true);
create policy "visits update" on glocal_visits for update to anon using (true) with check (true);
create policy "visits read" on glocal_visits for select to anon using (true);

-- 4) 권한 주기 (새 Supabase 프로젝트는 이게 없으면 "permission denied")
grant usage on schema public to anon, authenticated;
grant select, insert, update on glocal_rank to anon, authenticated;
grant select, insert, update on glocal_visits to anon, authenticated;
grant select, insert, update on glocal_players to authenticated;
