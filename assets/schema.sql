-- ============================================================
-- ClimbConnect — Supabase Database Schema
-- ============================================================
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor)
-- or via the Supabase CLI: supabase db push
-- ============================================================

-- Enable required extensions
create extension if not exists "uuid-ossp";

-- ────────────────────────────────────────────────────────────
-- 1. PROFILES
-- ────────────────────────────────────────────────────────────
-- Extends Supabase Auth users with app-specific profile data.
-- Automatically created on sign-up via trigger.
-- ────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id            uuid        primary key references auth.users(id) on delete cascade,
  username      text        unique not null,
  display_name  text,
  avatar_url    text,
  bio           text        default '',
  max_grade     text        default 'V0',
  total_sends   int         default 0,
  created_at    timestamptz default now() not null,
  updated_at    timestamptz default now() not null
);

comment on table public.profiles is 'User profiles extending Supabase Auth';

-- Auto-create a profile row when a new user signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, username, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', 'climber_' || left(new.id::text, 8)),
    coalesce(new.raw_user_meta_data ->> 'display_name', 'Climber'),
    coalesce(new.raw_user_meta_data ->> 'avatar_url', '')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Auto-update `updated_at` timestamp
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- RLS
alter table public.profiles enable row level security;

create policy "Profiles are viewable by everyone"
  on public.profiles for select
  using (true);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);


-- ────────────────────────────────────────────────────────────
-- 2. CLIMBING_ROUTES
-- ────────────────────────────────────────────────────────────
-- Each route stores its holds as a JSONB array:
-- [
--   { "row": 2, "col": 5, "holdType": "start",  "ledIndex": 27 },
--   { "row": 4, "col": 3, "holdType": "hand",   "ledIndex": 47 },
--   { "row": 6, "col": 7, "holdType": "foot",   "ledIndex": 73 },
--   { "row": 9, "col": 5, "holdType": "finish", "ledIndex": 99 }
-- ]
-- ────────────────────────────────────────────────────────────
create table if not exists public.climbing_routes (
  id            uuid        primary key default uuid_generate_v4(),
  name          text        not null,
  grade         text        not null,               -- V-scale: 'V0'..'V17'
  setter_id     uuid        references public.profiles(id) on delete set null,
  setter_name   text        not null default 'Anonymous',
  description   text        default '',
  holds         jsonb       not null default '[]'::jsonb,  -- array of hold objects
  angle         int         default 0,               -- board angle in degrees
  move_count    int         default 0,
  rating        numeric(3,2) default 0.00,           -- average rating 0.00–5.00
  rating_count  int         default 0,
  send_count    int         default 0,
  is_benchmark  boolean     default false,
  is_draft      boolean     default false,
  board_layout  text        default '11x18',         -- grid dimensions
  created_at    timestamptz default now() not null,
  updated_at    timestamptz default now() not null
);

comment on table  public.climbing_routes is 'Climbing problems with holds stored as JSONB';
comment on column public.climbing_routes.holds is 'JSONB array: [{row, col, holdType, ledIndex}]';

-- Indexes for common queries
create index if not exists idx_routes_grade      on public.climbing_routes (grade);
create index if not exists idx_routes_setter     on public.climbing_routes (setter_id);
create index if not exists idx_routes_rating     on public.climbing_routes (rating desc);
create index if not exists idx_routes_send_count on public.climbing_routes (send_count desc);
create index if not exists idx_routes_created_at on public.climbing_routes (created_at desc);
create index if not exists idx_routes_holds_gin  on public.climbing_routes using gin (holds);

create trigger climbing_routes_updated_at
  before update on public.climbing_routes
  for each row execute function public.set_updated_at();

-- RLS
alter table public.climbing_routes enable row level security;

create policy "Routes are viewable by everyone"
  on public.climbing_routes for select
  using (is_draft = false or auth.uid() = setter_id);

create policy "Authenticated users can create routes"
  on public.climbing_routes for insert
  to authenticated
  with check (auth.uid() = setter_id);

create policy "Setters can update own routes"
  on public.climbing_routes for update
  using (auth.uid() = setter_id)
  with check (auth.uid() = setter_id);

create policy "Setters can delete own routes"
  on public.climbing_routes for delete
  using (auth.uid() = setter_id);


-- ────────────────────────────────────────────────────────────
-- 3. USER_CLIMB_LOGS
-- ────────────────────────────────────────────────────────────
-- Personal logbook: sends, attempts, ratings, notes.
-- ────────────────────────────────────────────────────────────
create table if not exists public.user_climb_logs (
  id            uuid        primary key default uuid_generate_v4(),
  user_id       uuid        not null references public.profiles(id) on delete cascade,
  route_id      uuid        not null references public.climbing_routes(id) on delete cascade,
  is_sent       boolean     not null default false,
  attempts      int         not null default 1 check (attempts >= 1),
  rating        numeric(2,1) default 0.0,            -- user's personal rating 0.0–5.0
  notes         text        default '',
  climbed_at    timestamptz default now() not null,
  created_at    timestamptz default now() not null
);

comment on table public.user_climb_logs is 'Personal logbook entries for sends and attempts';

-- Indexes
create index if not exists idx_logs_user      on public.user_climb_logs (user_id);
create index if not exists idx_logs_route     on public.user_climb_logs (route_id);
create index if not exists idx_logs_climbed   on public.user_climb_logs (climbed_at desc);
create index if not exists idx_logs_user_sent on public.user_climb_logs (user_id, is_sent);

-- RLS
alter table public.user_climb_logs enable row level security;

create policy "Users can view own logs"
  on public.user_climb_logs for select
  using (auth.uid() = user_id);

create policy "Users can insert own logs"
  on public.user_climb_logs for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own logs"
  on public.user_climb_logs for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own logs"
  on public.user_climb_logs for delete
  using (auth.uid() = user_id);

-- Auto-increment send_count on the route when a send is logged
create or replace function public.increment_send_count()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.is_sent = true then
    update public.climbing_routes
    set send_count = send_count + 1
    where id = new.route_id;
  end if;
  return new;
end;
$$;

create trigger on_climb_log_inserted
  after insert on public.user_climb_logs
  for each row execute function public.increment_send_count();


-- ────────────────────────────────────────────────────────────
-- 4. ACTIVE_BOARD_ROUTE
-- ────────────────────────────────────────────────────────────
-- Shared, real-time state: which route is currently displayed
-- on the physical climbing board's LEDs.
-- One row per board (keyed by board_id).
--
-- ⚡ REALTIME REPLICATION is enabled on this table so all
-- connected clients receive live updates via Supabase Realtime.
-- ────────────────────────────────────────────────────────────
create table if not exists public.active_board_route (
  board_id      text        primary key default 'default',   -- physical board identifier
  route_id      uuid        references public.climbing_routes(id) on delete set null,
  route_name    text        default '',
  route_grade   text        default '',
  holds         jsonb       default '[]'::jsonb,             -- cached copy for fast LED render
  brightness    numeric(3,2) default 1.00 check (brightness >= 0 and brightness <= 1),
  leds_on       boolean     default false,
  activated_by  uuid        references public.profiles(id) on delete set null,
  activated_at  timestamptz default now() not null,
  updated_at    timestamptz default now() not null
);

comment on table  public.active_board_route is 'Real-time LED state for physical boards — replicated via Supabase Realtime';
comment on column public.active_board_route.holds is 'Cached JSONB holds for instant LED rendering without route join';

create trigger active_board_route_updated_at
  before update on public.active_board_route
  for each row execute function public.set_updated_at();

-- RLS
alter table public.active_board_route enable row level security;

create policy "Anyone can view active board state"
  on public.active_board_route for select
  using (true);

create policy "Authenticated users can activate routes"
  on public.active_board_route for insert
  to authenticated
  with check (auth.uid() = activated_by);

create policy "Authenticated users can update board state"
  on public.active_board_route for update
  to authenticated
  using (true)
  with check (auth.uid() = activated_by);

-- ────────────────────────────────────────────────────────────
-- ⚡ ENABLE REALTIME REPLICATION on active_board_route
-- ────────────────────────────────────────────────────────────
-- This adds the table to the supabase_realtime publication
-- so all INSERT / UPDATE / DELETE events are broadcast
-- to connected clients via WebSocket.
-- ────────────────────────────────────────────────────────────
alter publication supabase_realtime add table public.active_board_route;


-- ────────────────────────────────────────────────────────────
-- Seed: insert a default board row so upserts work immediately
-- ────────────────────────────────────────────────────────────
insert into public.active_board_route (board_id)
values ('default')
on conflict (board_id) do nothing;
