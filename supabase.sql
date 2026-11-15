-- =====================================================================
-- ChatKu tahap 1: tabel, aturan keamanan (RLS), trigger, dan realtime
-- Cara pakai: Supabase > SQL Editor > New query > tempel semua isi file ini > Run
-- Aman dijalankan SATU kali. Kalau ingin mengulang dari awal, hapus dulu tabelnya.
-- =====================================================================

-- 1) TABEL ------------------------------------------------------------
create table public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  username   text not null unique check (username ~ '^[a-z0-9_]{3,20}$'),
  name       text not null default '' check (char_length(name) <= 30),
  about      text not null default 'Hai, saya pakai ChatKu' check (char_length(about) <= 80),
  created_at timestamptz not null default now()
);

create table public.contacts (
  owner      uuid not null references public.profiles(id) on delete cascade,
  contact    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (owner, contact),
  check (owner <> contact)
);

create table public.messages (
  id          bigint generated always as identity primary key,
  sender_id   uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  body        text not null check (char_length(body) between 1 and 2000),
  created_at  timestamptz not null default now(),
  check (sender_id <> receiver_id)
);

create index messages_sender_idx   on public.messages (sender_id, created_at);
create index messages_receiver_idx on public.messages (receiver_id, created_at);

-- 2) KEAMANAN: Row Level Security (WAJIB) ------------------------------
alter table public.profiles enable row level security;
alter table public.contacts enable row level security;
alter table public.messages enable row level security;

-- Profil: semua pengguna yang login boleh melihat (untuk cari username),
-- tetapi hanya pemiliknya yang boleh mengubah. Profil dibuat oleh trigger.
create policy "profiles_select" on public.profiles
  for select to authenticated using (true);
create policy "profiles_update_own" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Kontak: hanya milik sendiri.
create policy "contacts_select_own" on public.contacts
  for select to authenticated using (owner = auth.uid());
create policy "contacts_insert_own" on public.contacts
  for insert to authenticated with check (owner = auth.uid());
create policy "contacts_delete_own" on public.contacts
  for delete to authenticated using (owner = auth.uid());

-- Pesan: hanya pengirim atau penerima yang boleh membaca; kirim hanya atas nama sendiri.
create policy "messages_select_own" on public.messages
  for select to authenticated using (sender_id = auth.uid() or receiver_id = auth.uid());
create policy "messages_insert_own" on public.messages
  for insert to authenticated with check (sender_id = auth.uid());

-- 3) TRIGGER ----------------------------------------------------------
-- Saat akun baru dibuat, otomatis buat profilnya (username diambil dari data pendaftaran).
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, name)
  values (
    new.id,
    lower(new.raw_user_meta_data->>'username'),
    coalesce(nullif(new.raw_user_meta_data->>'name', ''), new.raw_user_meta_data->>'username')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Saat ada pesan baru, kedua orang otomatis saling muncul di daftar kontak.
create or replace function public.handle_new_message()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.contacts (owner, contact)
  values (new.sender_id, new.receiver_id), (new.receiver_id, new.sender_id)
  on conflict do nothing;
  return new;
end;
$$;

create trigger on_message_created
  after insert on public.messages
  for each row execute function public.handle_new_message();

-- 4) REALTIME ---------------------------------------------------------
alter publication supabase_realtime add table public.messages;
