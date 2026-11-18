-- Beijing x Chongli trip page — run this once in Supabase SQL Editor
-- Project: pjcxokexcoigqbobyhmv  (the same project as couple-dashboard)
-- Safe to run twice: everything is guarded.

create extension if not exists pgcrypto;

-- ─── tables ────────────────────────────────────────────────────────────────
create table if not exists public.trip_places (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique,
  name        text not null check (char_length(name) between 1 and 80),
  name_cn     text check (char_length(name_cn) <= 60),
  area        text check (char_length(area) <= 40),
  why         text check (char_length(why) <= 400),
  day         smallint check (day between 2 and 10),
  kind        text not null default 'place' check (kind in ('place','food','activity','transit')),
  cost        text check (char_length(cost) <= 40),
  created_by  text check (char_length(created_by) <= 40),
  created_at  timestamptz not null default now()
);

create table if not exists public.trip_votes (
  id         uuid primary key default gen_random_uuid(),
  place_id   uuid not null references public.trip_places(id) on delete cascade,
  voter_id   text not null check (char_length(voter_id) between 6 and 64),
  value      smallint not null check (value in (-1, 0, 1)),
  created_at timestamptz not null default now(),
  unique (place_id, voter_id)
);

create table if not exists public.trip_comments (
  id         uuid primary key default gen_random_uuid(),
  place_id   uuid not null references public.trip_places(id) on delete cascade,
  voter_id   text check (char_length(voter_id) <= 64),
  author     text check (char_length(author) <= 40),
  body       text not null check (char_length(body) between 1 and 600),
  created_at timestamptz not null default now()
);

create index if not exists trip_votes_place_idx    on public.trip_votes (place_id);
create index if not exists trip_comments_place_idx on public.trip_comments (place_id);

-- ─── access: anyone can read and contribute, nobody can wipe ───────────────
alter table public.trip_places   enable row level security;
alter table public.trip_votes    enable row level security;
alter table public.trip_comments enable row level security;

grant select, insert, update on public.trip_places   to anon, authenticated;
grant select, insert, update on public.trip_votes    to anon, authenticated;
grant select, insert         on public.trip_comments to anon, authenticated;

drop policy if exists trip_places_read   on public.trip_places;
drop policy if exists trip_places_add    on public.trip_places;
drop policy if exists trip_places_update on public.trip_places;
create policy trip_places_read   on public.trip_places for select using (true);
create policy trip_places_add    on public.trip_places for insert with check (true);
create policy trip_places_update on public.trip_places for update using (true) with check (true);

drop policy if exists trip_votes_read   on public.trip_votes;
drop policy if exists trip_votes_write  on public.trip_votes;
drop policy if exists trip_votes_update on public.trip_votes;
create policy trip_votes_read   on public.trip_votes for select using (true);
create policy trip_votes_write  on public.trip_votes for insert with check (true);
create policy trip_votes_update on public.trip_votes for update using (true) with check (true);

drop policy if exists trip_comments_read  on public.trip_comments;
drop policy if exists trip_comments_write on public.trip_comments;
create policy trip_comments_read  on public.trip_comments for select using (true);
create policy trip_comments_write on public.trip_comments for insert with check (true);

-- ─── the 26 places already in the plan ─────────────────────────────────────
insert into public.trip_places (slug, day, name, name_cn, area, why)
values
  ('taikooli', 2, 'Taikoo Li Sanlitun', '三里屯太古里', '北京 · 朝阳', '落地第一站：露天街区逛店拍照，晚上就在隔壁喝酒。'),
  ('skp-s', 2, 'SKP-S', '北京SKP-S', '北京 · 朝阳', '把商场做成火星艺术装置，拍照很好看，就在太古里旁边。'),
  ('duck', 2, 'Peking duck dinner', '北京烤鸭', '北京 · 朝阳', '第一晚正式吃一顿，8 人提前订位。'),
  ('sanlitun-bars', 2, 'Sanlitun bars', '三里屯酒吧街', '北京 · 朝阳', '走回酒店路上随便挑，不用订。'),
  ('universal', 3, 'Universal Beijing Resort', '北京环球影城', '北京 · 通州', '哈利波特、侏罗纪、霸天虎过山车，一整天。'),
  ('guijie', 3, 'Guijie late supper', '簋街', '北京 · 东城', '环球影城回来后的深夜宵夜一条街，小龙虾和烤鱼。'),
  ('gugong', 4, 'Forbidden City', '故宫博物院', '北京 · 东城', '周五去，人比周末少一半；门票 7 天前早上 7 点放，要抢。'),
  ('jingshan', 4, 'Jingshan Park', '景山公园', '北京 · 东城', '从故宫北门出来，爬 15 分钟拍屋顶全景。'),
  ('shichahai', 4, 'Shichahai', '什刹海', '北京 · 西城', '湖 + 胡同，没有车，走走拍拍。'),
  ('nanluoguxiang', 4, 'Nanluoguxiang', '南锣鼓巷', '北京 · 东城', '小吃和手作小店，顺路逛。'),
  ('hotpot', 4, 'Copper-pot lamb hotpot', '铜锅涮肉', '北京 · 西城', '北京冬天该吃的东西，8 人要包间。'),
  ('escape', 4, 'Script murder / escape room', '剧本杀', '北京 · 东城', '8 人刚好一局，提前预约主题。'),
  ('mutianyu', 5, 'Mutianyu Great Wall', '慕田峪长城', '北京 · 怀柔', '缆车上、滑道下；7 点出发避开大巴团。'),
  ('798', 5, '798 Art District', '798艺术区', '北京 · 朝阳', '回程顺路，画廊 18:00 关门。'),
  ('qinghe', 6, 'Beijing Qinghe Station', '北京清河站', '北京 · 海淀', '08:00 高铁去崇礼，提前 30 分钟到。'),
  ('taizicheng', 6, 'Taizicheng Station', '太子城站', '崇礼', '下车有免费接驳车到雪场。'),
  ('thaiwoo', 6, 'Thaiwoo Ski Resort', '太舞滑雪小镇', '崇礼', '住这里：初级道最宽、小镇能走，ski-in / ski-out。'),
  ('ski1', 6, 'Ski session 1 (4 h)', '第一天滑雪', '崇礼 · 太舞', '下午 4 小时先熟雪，装备现场租（滑雪包不能上高铁）。'),
  ('ski2', 7, 'Ski day + lesson', '全天滑雪 + 教练', '崇礼 · 太舞', '第一天跟 2 小时团课，剩下自己滑。'),
  ('genting', 7, 'Genting night ski', '密苑云顶夜场', '崇礼 · 云顶', '这里唯一开夜场、雪道有灯，晚上去滑一趟。'),
  ('ski3', 8, 'Ski session 3 (4 h)', '第三天滑雪', '崇礼 · 太舞', '早上滑半天，中午退房坐高铁回北京。'),
  ('wangfujing', 8, 'Wangfujing', '王府井', '北京 · 东城', '回北京当晚逛街吃饭，离第二间酒店近。'),
  ('yonghegong', 9, 'Lama Temple', '雍和宫', '北京 · 东城', '藏传佛教寺院，冬天香火和雪景都好拍。'),
  ('wudaoying', 9, 'Wudaoying Hutong', '五道营胡同', '北京 · 东城', '雍和宫对面，咖啡馆和小店，最后一天慢慢走。'),
  ('farewell', 9, 'Farewell dinner', '散伙饭', '北京 · 东城', '最后一晚好好吃一顿，订包间。'),
  ('tiantan', 10, 'Temple of Heaven', '天坛', '北京 · 东城', '早上逛完，13:00 前到机场。')
on conflict (slug) do nothing;

notify pgrst, 'reload schema';
