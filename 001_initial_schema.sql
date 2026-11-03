-- Global Sound Platform initial schema.
-- Run in the Supabase SQL Editor. RLS is enabled on every user-facing table.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text,
  avatar_url text,
  bio text,
  role text not null default 'listener' check (role in ('listener','artist','admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.artists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  stage_name text not null,
  verification_status text not null default 'pending'
    check (verification_status in ('pending','verified','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.tracks (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid references public.artists(id) on delete set null,
  title text not null,
  description text,
  genre text,
  audio_path text,
  artwork_path text,
  visibility text not null default 'private'
    check (visibility in ('private','unlisted','public')),
  rights_confirmed boolean not null default false,
  moderation_status text not null default 'pending'
    check (moderation_status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.playlists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  is_public boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.playlist_tracks (
  playlist_id uuid not null references public.playlists(id) on delete cascade,
  track_id uuid not null references public.tracks(id) on delete cascade,
  position integer not null default 0,
  primary key (playlist_id, track_id)
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) <= 5000),
  created_at timestamptz not null default now()
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) <= 2000),
  created_at timestamptz not null default now()
);

-- Append-only wallet ledger: never store a mutable client-controlled coin balance.
create table if not exists public.coin_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount bigint not null check (amount <> 0),
  entry_type text not null check (entry_type in ('credit','debit','refund','adjustment')),
  reference text,
  created_at timestamptz not null default now()
);

create index if not exists tracks_public_created_idx
  on public.tracks (created_at desc) where visibility = 'public' and moderation_status = 'approved';
create index if not exists posts_created_idx on public.posts (created_at desc);
create index if not exists coin_ledger_user_created_idx on public.coin_ledger (user_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.artists enable row level security;
alter table public.tracks enable row level security;
alter table public.playlists enable row level security;
alter table public.playlist_tracks enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.coin_ledger enable row level security;

create policy "Profiles are viewable by everyone"
  on public.profiles for select using (true);
create policy "Users update own profile"
  on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "Users create own profile"
  on public.profiles for insert with check (auth.uid() = id);

create policy "Verified artist profiles visible"
  on public.artists for select using (verification_status = 'verified' or user_id = auth.uid());
create policy "Users create own artist profile"
  on public.artists for insert with check (user_id = auth.uid());
create policy "Users update own artist profile"
  on public.artists for update using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "Approved public tracks visible"
  on public.tracks for select using (
    (visibility = 'public' and moderation_status = 'approved')
    or exists (select 1 from public.artists a where a.id = artist_id and a.user_id = auth.uid())
  );
create policy "Artists create tracks for own artist profile"
  on public.tracks for insert with check (
    exists (select 1 from public.artists a where a.id = artist_id and a.user_id = auth.uid())
    and rights_confirmed = true
  );
create policy "Artists update own tracks"
  on public.tracks for update using (
    exists (select 1 from public.artists a where a.id = artist_id and a.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.artists a where a.id = artist_id and a.user_id = auth.uid())
  );

create policy "Users view own playlists or public playlists"
  on public.playlists for select using (is_public = true or owner_id = auth.uid());
create policy "Users manage own playlists"
  on public.playlists for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy "Playlist tracks visible with playlist"
  on public.playlist_tracks for select using (
    exists (select 1 from public.playlists p where p.id = playlist_id and (p.is_public or p.owner_id = auth.uid()))
  );
create policy "Playlist owners manage tracks"
  on public.playlist_tracks for all using (
    exists (select 1 from public.playlists p where p.id = playlist_id and p.owner_id = auth.uid())
  ) with check (
    exists (select 1 from public.playlists p where p.id = playlist_id and p.owner_id = auth.uid())
  );

create policy "Posts are publicly readable"
  on public.posts for select using (true);
create policy "Users create own posts"
  on public.posts for insert with check (author_id = auth.uid());
create policy "Users update own posts"
  on public.posts for update using (author_id = auth.uid()) with check (author_id = auth.uid());
create policy "Users delete own posts"
  on public.posts for delete using (author_id = auth.uid());

create policy "Comments are publicly readable"
  on public.comments for select using (true);
create policy "Users create own comments"
  on public.comments for insert with check (author_id = auth.uid());
create policy "Users manage own comments"
  on public.comments for update using (author_id = auth.uid()) with check (author_id = auth.uid());

create policy "Users view own coin ledger"
  on public.coin_ledger for select using (user_id = auth.uid());
-- Intentionally no client INSERT/UPDATE/DELETE policy for coin_ledger.
-- Wallet changes must be performed by trusted server-side, verified workflows.
