-- =====================================================================
-- ChatKu TAHAP 2: balas pesan, hapus pesan, sematkan chat, hapus chat,
-- dan foto profil. Jalankan SETELAH supabase.sql tahap 1.
-- Cara pakai: SQL Editor > New query > tempel semua > Run (cukup SATU kali).
-- =====================================================================

-- 1) Kolom baru
alter table public.profiles add column photo_url text
  check (photo_url is null or photo_url ~ '^https://[a-z0-9.-]+\.supabase\.co/storage/v1/object/public/avatars/[A-Za-z0-9/_.?=&-]+$');

alter table public.messages add column reply_to bigint references public.messages(id) on delete set null;
alter table public.messages add column deleted boolean not null default false;
alter table public.messages drop constraint messages_body_check;
alter table public.messages add constraint messages_body_check
  check (char_length(body) <= 2000 and (deleted or char_length(body) >= 1));

alter table public.contacts add column pinned boolean not null default false;
alter table public.contacts add column hidden boolean not null default false;
alter table public.contacts add column cleared_at timestamptz;

-- 2) Aturan keamanan tambahan
create policy "contacts_update_own" on public.contacts
  for update to authenticated using (owner = auth.uid()) with check (owner = auth.uid());

-- Pengirim boleh mengubah pesannya sendiri (dipakai untuk "hapus untuk semua").
create policy "messages_update_own" on public.messages
  for update to authenticated using (sender_id = auth.uid()) with check (sender_id = auth.uid());

-- 3) Pesan baru memunculkan lagi chat yang sebelumnya dihapus
create or replace function public.handle_new_message()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.contacts (owner, contact)
  values (new.sender_id, new.receiver_id), (new.receiver_id, new.sender_id)
  on conflict (owner, contact) do update set hidden = false;
  return new;
end;
$$;

-- 4) Penyimpanan foto profil (bucket publik "avatars", tiap orang hanya boleh folder sendiri)
insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true)
  on conflict (id) do nothing;

create policy "avatars_read" on storage.objects
  for select using (bucket_id = 'avatars');
create policy "avatars_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
