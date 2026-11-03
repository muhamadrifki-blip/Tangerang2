-- Sales Daily Performance Management System
-- Jalankan seluruh file ini di Supabase Dashboard > SQL Editor.
-- Aman untuk frontend: otorisasi data dilakukan oleh RLS.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default 'Sales',
  role text not null default 'sales' check (role in ('sales','manager')),
  profil text not null default 'cs' check (profil in ('nj','jr','sr','cs')),
  area text not null default '',
  active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.signup_requests (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  created_at timestamptz not null default now()
);

-- Menyimpan dokumen JSON aplikasi lama dengan struktur path yang sama.
-- Contoh path: plans/<user-id>/months/2026-11
create table if not exists public.app_documents (
  path text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create index if not exists app_documents_path_prefix_idx on public.app_documents (path text_pattern_ops);

create or replace function public.is_manager()
returns boolean
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'manager' and p.active = true
  );
$$;

-- Profil dan request dibuat otomatis saat user mendaftar Auth.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_name text;
begin
  v_name := coalesce(nullif(new.raw_user_meta_data->>'name',''), split_part(new.email,'@',1), 'Sales');
  insert into public.profiles (id, name, role, profil, area, active)
  values (new.id, v_name, 'sales', 'cs', '', false)
  on conflict (id) do nothing;

  insert into public.signup_requests (user_id, email, name)
  values (new.id, new.email, v_name)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_sales_dpms on auth.users;
create trigger on_auth_user_created_sales_dpms
after insert on auth.users
for each row execute procedure public.handle_new_auth_user();

alter table public.profiles enable row level security;
alter table public.signup_requests enable row level security;
alter table public.app_documents enable row level security;

drop policy if exists profiles_read_self_or_manager on public.profiles;
create policy profiles_read_self_or_manager on public.profiles
for select to authenticated
using (id = auth.uid() or public.is_manager());

drop policy if exists profiles_manager_update on public.profiles;
create policy profiles_manager_update on public.profiles
for update to authenticated
using (public.is_manager())
with check (public.is_manager());

-- Tidak ada INSERT/UPDATE profil langsung oleh Sales. Profil dibuat oleh trigger.

drop policy if exists signup_read_self_or_manager on public.signup_requests;
create policy signup_read_self_or_manager on public.signup_requests
for select to authenticated
using (user_id = auth.uid() or public.is_manager());

drop policy if exists signup_insert_self on public.signup_requests;
create policy signup_insert_self on public.signup_requests
for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists documents_read_own_or_manager on public.app_documents;
create policy documents_read_own_or_manager on public.app_documents
for select to authenticated
using (
  public.is_manager()
  or split_part(path, '/', 2) = auth.uid()::text
);

drop policy if exists documents_insert_own_or_manager on public.app_documents;
create policy documents_insert_own_or_manager on public.app_documents
for insert to authenticated
with check (
  public.is_manager()
  or split_part(path, '/', 2) = auth.uid()::text
);

drop policy if exists documents_update_own_or_manager on public.app_documents;
create policy documents_update_own_or_manager on public.app_documents
for update to authenticated
using (
  public.is_manager()
  or split_part(path, '/', 2) = auth.uid()::text
)
with check (
  public.is_manager()
  or split_part(path, '/', 2) = auth.uid()::text
);

drop policy if exists documents_delete_own_or_manager on public.app_documents;
create policy documents_delete_own_or_manager on public.app_documents
for delete to authenticated
using (
  public.is_manager()
  or split_part(path, '/', 2) = auth.uid()::text
);

grant usage on schema public to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert on public.signup_requests to authenticated;
grant select, insert, update, delete on public.app_documents to authenticated;
grant execute on function public.is_manager() to authenticated;

-- PENTING: Setelah akun Manager pertama dibuat melalui form Daftar di aplikasi,
-- jalankan query promosi di bawah ini dengan mengganti alamat email.
-- Setelah itu logout lalu login kembali.
-- update public.profiles p
-- set role = 'manager', active = true, updated_at = now()
-- from auth.users u
-- where p.id = u.id and lower(u.email) = lower('email-manager@perusahaan.com');
-- delete from public.signup_requests r using auth.users u
-- where r.user_id = u.id and lower(u.email) = lower('email-manager@perusahaan.com');
