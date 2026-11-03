-- Live MVP hardening and private audio storage.
-- Apply after 001_initial_schema.sql in the Supabase SQL Editor.

-- Do not allow users to grant themselves privileged profile roles.
drop policy if exists "Users create own profile" on public.profiles;
create policy "Users create own listener profile"
  on public.profiles for insert
  with check (id = auth.uid() and role = 'listener');

create or replace function public.prevent_self_role_change()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.role() <> 'service_role' and new.role is distinct from old.role then
    raise exception 'Profile roles can only be changed by a trusted administrator';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_self_role_change on public.profiles;
create trigger profiles_prevent_self_role_change
  before update of role on public.profiles
  for each row execute function public.prevent_self_role_change();

-- Artist verification is a moderation decision, never a client-controlled field.
drop policy if exists "Users create own artist profile" on public.artists;
create policy "Users create pending artist profile"
  on public.artists for insert
  with check (user_id = auth.uid() and verification_status = 'pending');
drop policy if exists "Users update own artist profile" on public.artists;
create policy "Users update pending artist profile"
  on public.artists for update
  using (user_id = auth.uid() and verification_status = 'pending')
  with check (user_id = auth.uid() and verification_status = 'pending');

-- An artist may submit and edit pending tracks, but cannot self-approve a release.
drop policy if exists "Artists create tracks for own artist profile" on public.tracks;
create policy "Artists submit pending tracks"
  on public.tracks for insert
  with check (
    exists (select 1 from public.artists a where a.id = artist_id and a.user_id = auth.uid())
    and rights_confirmed = true
    and moderation_status = 'pending'
  );
drop policy if exists "Artists update own tracks" on public.tracks;
create policy "Artists update pending tracks"
  on public.tracks for update
  using (
    moderation_status = 'pending'
    and exists (select 1 from public.artists a where a.id = artist_id and a.user_id = auth.uid())
  )
  with check (
    moderation_status = 'pending'
    and rights_confirmed = true
    and exists (select 1 from public.artists a where a.id = artist_id and a.user_id = auth.uid())
  );

-- Keep recordings private in storage. Signed playback URLs are only issued to users
-- permitted to read the corresponding approved public track or their own submission.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('music', 'music', false, 31457280, array['audio/mpeg','audio/mp3','audio/wav','audio/x-wav','audio/mp4','audio/aac','audio/ogg','audio/webm','audio/flac'])
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Music audio readable by owner or approved public track" on storage.objects;
create policy "Music audio readable by owner or approved public track"
  on storage.objects for select
  using (
    bucket_id = 'music'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or exists (
        select 1 from public.tracks t
        where t.audio_path = storage.objects.name
          and t.visibility = 'public'
          and t.moderation_status = 'approved'
      )
    )
  );
drop policy if exists "Users upload music to own folder" on storage.objects;
create policy "Users upload music to own folder"
  on storage.objects for insert
  with check (bucket_id = 'music' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "Users delete music from own folder" on storage.objects;
create policy "Users delete music from own folder"
  on storage.objects for delete
  using (bucket_id = 'music' and (storage.foldername(name))[1] = auth.uid()::text);

create index if not exists tracks_artist_created_idx on public.tracks (artist_id, created_at desc);
create index if not exists posts_author_created_idx on public.posts (author_id, created_at desc);
