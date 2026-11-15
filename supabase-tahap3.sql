-- =====================================================================
-- ChatKu TAHAP 3: reaksi, ubah pesan, teruskan, bintang, bisukan, centang baca.
-- Jalankan SETELAH supabase.sql (tahap 1) dan supabase-tahap2.sql.
-- Cara pakai: SQL Editor > New query > tempel semua > Run (cukup SATU kali).
-- =====================================================================

-- 1) Kolom baru
alter table public.messages add column edited    boolean not null default false;
alter table public.messages add column forwarded boolean not null default false;
alter table public.messages add column read_at   timestamptz;
alter table public.contacts add column muted     boolean not null default false;

-- 2) Reaksi pesan (satu reaksi per orang per pesan; emoji kosong = reaksi dilepas)
create table public.message_reactions (
  message_id bigint not null references public.messages(id) on delete cascade,
  user_id    uuid   not null references public.profiles(id) on delete cascade,
  emoji      text   not null check (char_length(emoji) <= 8),
  updated_at timestamptz not null default now(),
  primary key (message_id, user_id)
);
alter table public.message_reactions enable row level security;

create policy "reactions_select" on public.message_reactions
  for select to authenticated using (
    exists (select 1 from public.messages m
            where m.id = message_id and (m.sender_id = auth.uid() or m.receiver_id = auth.uid())));
create policy "reactions_insert" on public.message_reactions
  for insert to authenticated with check (
    user_id = auth.uid() and
    exists (select 1 from public.messages m
            where m.id = message_id and (m.sender_id = auth.uid() or m.receiver_id = auth.uid())));
create policy "reactions_update" on public.message_reactions
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 3) Pesan berbintang (pribadi, hanya terlihat oleh pemiliknya)
create table public.starred (
  user_id    uuid   not null references public.profiles(id) on delete cascade,
  message_id bigint not null references public.messages(id) on delete cascade,
  primary key (user_id, message_id)
);
alter table public.starred enable row level security;
create policy "starred_select" on public.starred for select to authenticated using (user_id = auth.uid());
create policy "starred_insert" on public.starred for insert to authenticated with check (user_id = auth.uid());
create policy "starred_delete" on public.starred for delete to authenticated using (user_id = auth.uid());

-- 4) Centang baca: penerima hanya boleh menandai "sudah dibaca" lewat fungsi ini
--    (tidak diberi izin mengubah isi pesan).
create or replace function public.mark_read(p_other uuid)
returns void language sql security definer set search_path = public as $$
  update public.messages set read_at = now()
  where sender_id = p_other and receiver_id = auth.uid() and read_at is null;
$$;
revoke execute on function public.mark_read(uuid) from public, anon;
grant  execute on function public.mark_read(uuid) to authenticated;

-- 5) Realtime untuk reaksi
alter publication supabase_realtime add table public.message_reactions;
