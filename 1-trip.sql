-- Beijing x Chongli trip page — run this once in Supabase SQL Editor
-- Project: pjcxokexcoigqbobyhmv  (the same project as couple-dashboard)
-- Safe to run twice: everything is guarded. Re-running does not wipe votes.

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
  img         text[] not null default '{}',
  cap         text check (char_length(cap) <= 300),
  created_by  text check (char_length(created_by) <= 40),
  created_at  timestamptz not null default now()
);

-- in case an earlier version of this script already ran
alter table public.trip_places add column if not exists img text[] not null default '{}';
alter table public.trip_places add column if not exists cap text;

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

-- ─── access: anyone can read and add, nothing can be wiped ─────────────────
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

-- ─── the 26 places already in the plan (with their photos) ────────────────
insert into public.trip_places (slug, day, name, name_cn, area, why, img, cap)
values
  ('taikooli', 2, 'Taikoo Li Sanlitun', '三里屯太古里', '北京 · 朝阳', '落地第一站：露天街区逛店拍照，晚上就在隔壁喝酒。', '{sanlitun-1.jpg,sanlitun-3.jpg}'::text[], '太古里的露天街区，和天黑后的三里屯广场——这个团最顺的落脚点。'),
  ('skp-s', 2, 'SKP-S', '北京SKP-S', '北京 · 朝阳', '把商场做成火星艺术装置，拍照很好看，就在太古里旁边。', '{sanlitun-2.jpg}'::text[], '三里屯街口。'),
  ('duck', 2, 'Peking duck dinner', '北京烤鸭', '北京 · 朝阳', '第一晚正式吃一顿，8 人提前订位。', '{}'::text[], null),
  ('sanlitun-bars', 2, 'Sanlitun bars', '三里屯酒吧街', '北京 · 朝阳', '走回酒店路上随便挑，不用订。', '{}'::text[], null),
  ('universal', 3, 'Universal Beijing Resort', '北京环球影城', '北京 · 通州', '哈利波特、侏罗纪、霸天虎过山车，一整天。', '{universal-1.jpg,universal-3.jpg}'::text[], '通州的大门，和闭园前城堡灯光秀的霍格沃茨。'),
  ('guijie', 3, 'Guijie late supper', '簋街', '北京 · 东城', '环球影城回来后的深夜宵夜一条街，小龙虾和烤鱼。', '{}'::text[], null),
  ('gugong', 4, 'Forbidden City', '故宫博物院', '北京 · 东城', '周五去，人比周末少一半；门票 7 天前早上 7 点放，要抢。', '{gugong-1.jpg,gugong-3.jpg}'::text[], '太和殿，和雪后的故宫——值得为一场寒流去追的画面。'),
  ('jingshan', 4, 'Jingshan Park', '景山公园', '北京 · 东城', '从故宫北门出来，爬 15 分钟拍屋顶全景。', '{gugong-2.jpg}'::text[], '从景山往下看的中轴线。'),
  ('shichahai', 4, 'Shichahai', '什刹海', '北京 · 西城', '湖 + 胡同，没有车，走走拍拍。', '{hutong-1.jpg,hutong-3.jpg}'::text[], '什刹海 / 后海——湖面结冰、没有车。溜冰一般 12 月底才开，当个「可以的话」就好。'),
  ('nanluoguxiang', 4, 'Nanluoguxiang', '南锣鼓巷', '北京 · 东城', '小吃和手作小店，顺路逛。', '{hutong-2.jpg}'::text[], '胡同里的巷子，随便走都是景。'),
  ('hotpot', 4, 'Copper-pot lamb hotpot', '铜锅涮肉', '北京 · 西城', '北京冬天该吃的东西，8 人要包间。', '{}'::text[], null),
  ('escape', 4, 'Script murder / escape room', '剧本杀', '北京 · 东城', '8 人刚好一局，提前预约主题。', '{}'::text[], null),
  ('mutianyu', 5, 'Mutianyu Great Wall', '慕田峪长城', '北京 · 怀柔', '缆车上、滑道下；7 点出发避开大巴团。', '{mutianyu-1.jpg,mutianyu-3.jpg,mutianyu-2.jpg}'::text[], '慕田峪的城墙和上山步道。7 点出发——大巴团 10 点才到。'),
  ('798', 5, '798 Art District', '798艺术区', '北京 · 朝阳', '回程顺路，画廊 18:00 关门。', '{798-1.jpg,798-2.jpg}'::text[], '798 的旧厂房和画廊内部，18:00 关门。'),
  ('qinghe', 6, 'Beijing Qinghe Station', '北京清河站', '北京 · 海淀', '08:00 高铁去崇礼，提前 30 分钟到。', '{ski-5.jpg}'::text[], '清河开往崇礼的高铁。'),
  ('taizicheng', 6, 'Taizicheng Station', '太子城站', '崇礼', '下车有免费接驳车到雪场。', '{}'::text[], null),
  ('thaiwoo', 6, 'Thaiwoo Ski Resort', '太舞滑雪小镇', '崇礼', '住这里：初级道最宽、小镇能走，ski-in / ski-out。', '{ski-3.jpg,ski-6.jpg}'::text[], '雪道下面的度假楼群，和雪道边的酒店。'),
  ('ski1', 6, 'Ski session 1 (4 h)', '第一天滑雪', '崇礼 · 太舞', '下午 4 小时先熟雪，装备现场租（滑雪包不能上高铁）。', '{ski-2.jpg}'::text[], '2022 冬奥的雪道。装备现场租——滑雪包不能上高铁。'),
  ('ski2', 7, 'Ski day + lesson', '全天滑雪 + 教练', '崇礼 · 太舞', '第一天跟 2 小时团课，剩下自己滑。', '{}'::text[], null),
  ('genting', 7, 'Genting night ski', '密苑云顶夜场', '崇礼 · 云顶', '这里唯一开夜场、雪道有灯，晚上去滑一趟。', '{genting-1.jpg,genting-2.jpg}'::text[], '云顶的雪道和夜场灯光。'),
  ('ski3', 8, 'Ski session 3 (4 h)', '第三天滑雪', '崇礼 · 太舞', '早上滑半天，中午退房坐高铁回北京。', '{}'::text[], null),
  ('wangfujing', 8, 'Wangfujing', '王府井', '北京 · 东城', '回北京当晚逛街吃饭，离第二间酒店近。', '{}'::text[], null),
  ('yonghegong', 9, 'Lama Temple', '雍和宫', '北京 · 东城', '藏传佛教寺院，冬天香火和雪景都好拍。', '{}'::text[], null),
  ('wudaoying', 9, 'Wudaoying Hutong', '五道营胡同', '北京 · 东城', '雍和宫对面，咖啡馆和小店，最后一天慢慢走。', '{}'::text[], null),
  ('farewell', 9, 'Farewell dinner', '散伙饭', '北京 · 东城', '最后一晚好好吃一顿，订包间。', '{}'::text[], null),
  ('tiantan', 10, 'Temple of Heaven', '天坛', '北京 · 东城', '早上逛完，13:00 前到机场。', '{}'::text[], null)
on conflict (slug) do nothing;

notify pgrst, 'reload schema';
