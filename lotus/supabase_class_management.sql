-- LOTUS ERP class management baseline for Supabase.
-- Run this in Supabase SQL Editor.
-- It is designed to be safe to re-run.

begin;

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.class_rooms (
  id uuid primary key default gen_random_uuid(),
  class_number integer not null check (class_number between 1 and 12),
  section text not null default '',
  academic_year text not null default '',
  class_teacher_id uuid references auth.users(id) on delete set null,
  schedule jsonb not null default '{}'::jsonb,
  resources jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (class_number, section, academic_year)
);

alter table public.profiles
  add column if not exists role text not null default 'student',
  add column if not exists is_admin boolean not null default false,
  add column if not exists class_id uuid references public.class_rooms(id) on delete set null,
  add column if not exists class integer,
  add column if not exists section text not null default '',
  add column if not exists updated_at timestamptz not null default now();

alter table public.profiles
  alter column class type integer using (
    case
      when class::text ~ '^\d+$' and class::text::integer between 1 and 12
        then class::text::integer
      else null
    end
  );

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_role_valid'
  ) then
    alter table public.profiles
      add constraint profiles_role_valid
      check (role in ('student', 'teacher', 'admin'));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'profiles_class_between_1_12'
  ) then
    alter table public.profiles
      add constraint profiles_class_between_1_12
      check (class is null or class between 1 and 12);
  end if;
end $$;

create table if not exists public.homework (
  id uuid primary key default gen_random_uuid(),
  subject text not null,
  file_type text not null,
  file_name text not null,
  storage_path text not null unique,
  class_number integer not null check (class_number between 1 and 12),
  section text not null default '',
  uploaded_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.homework
  add column if not exists class_number integer,
  add column if not exists section text not null default '',
  add column if not exists updated_at timestamptz not null default now();

alter table public.homework
  alter column class_number type integer using (
    case
      when class_number::text ~ '^\d+$' and class_number::text::integer between 1 and 12
        then class_number::text::integer
      else null
    end
  );

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'homework_class_between_1_12'
  ) then
    alter table public.homework
      add constraint homework_class_between_1_12
      check (class_number is null or class_number between 1 and 12);
  end if;
end $$;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  subtitle text not null default '',
  type text not null default 'general',
  homework_id uuid references public.homework(id) on delete cascade,
  class_number integer check (class_number between 1 and 12),
  section text not null default '',
  read_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.notifications
  add column if not exists class_number integer,
  add column if not exists section text not null default '',
  add column if not exists read_at timestamptz;

create table if not exists public.notices (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null default '',
  class_number integer not null check (class_number between 1 and 12),
  section text not null default '',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  subject text not null default '',
  due_at timestamptz,
  class_number integer not null check (class_number between 1 and 12),
  section text not null default '',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null default '',
  class_number integer not null check (class_number between 1 and 12),
  section text not null default '',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists class_rooms_lookup_idx
  on public.class_rooms (class_number, section, academic_year)
  where is_active = true;

create index if not exists profiles_class_lookup_idx
  on public.profiles (class, section);

create index if not exists profiles_role_lookup_idx
  on public.profiles (role, is_admin);

create index if not exists homework_class_lookup_idx
  on public.homework (class_number, section, created_at desc);

create index if not exists notifications_user_lookup_idx
  on public.notifications (user_id, created_at desc);

create index if not exists notifications_class_lookup_idx
  on public.notifications (class_number, section, created_at desc);

create index if not exists notices_class_lookup_idx
  on public.notices (class_number, section, created_at desc);

create index if not exists assignments_class_lookup_idx
  on public.assignments (class_number, section, due_at, created_at desc);

create index if not exists announcements_class_lookup_idx
  on public.announcements (class_number, section, created_at desc);

drop trigger if exists set_class_rooms_updated_at on public.class_rooms;
create trigger set_class_rooms_updated_at
before update on public.class_rooms
for each row execute function public.set_updated_at();

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_homework_updated_at on public.homework;
create trigger set_homework_updated_at
before update on public.homework
for each row execute function public.set_updated_at();

drop trigger if exists set_notices_updated_at on public.notices;
create trigger set_notices_updated_at
before update on public.notices
for each row execute function public.set_updated_at();

drop trigger if exists set_assignments_updated_at on public.assignments;
create trigger set_assignments_updated_at
before update on public.assignments
for each row execute function public.set_updated_at();

drop trigger if exists set_announcements_updated_at on public.announcements;
create trigger set_announcements_updated_at
before update on public.announcements
for each row execute function public.set_updated_at();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select p.is_admin or p.role = 'admin'
    from public.profiles p
    where p.id = auth.uid()
  ), false);
$$;

create or replace function public.is_same_class(
  target_class integer,
  target_section text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.class = target_class
      and (
        coalesce(target_section, '') = ''
        or coalesce(p.section, '') = ''
        or coalesce(p.section, '') = coalesce(target_section, '')
      )
  );
$$;

alter table public.profiles enable row level security;
alter table public.class_rooms enable row level security;
alter table public.homework enable row level security;
alter table public.notifications enable row level security;
alter table public.notices enable row level security;
alter table public.assignments enable row level security;
alter table public.announcements enable row level security;

drop policy if exists "profiles_select_self_or_admin" on public.profiles;
create policy "profiles_select_self_or_admin"
on public.profiles for select
to authenticated
using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_self_or_admin" on public.profiles;
create policy "profiles_update_self_or_admin"
on public.profiles for update
to authenticated
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

drop policy if exists "class_rooms_select_assigned_or_admin" on public.class_rooms;
create policy "class_rooms_select_assigned_or_admin"
on public.class_rooms for select
to authenticated
using (
  public.is_admin()
  or public.is_same_class(class_number, section)
);

drop policy if exists "class_rooms_admin_write" on public.class_rooms;
create policy "class_rooms_admin_write"
on public.class_rooms for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "homework_select_same_class_or_admin" on public.homework;
create policy "homework_select_same_class_or_admin"
on public.homework for select
to authenticated
using (
  public.is_admin()
  or public.is_same_class(class_number, section)
);

drop policy if exists "homework_admin_write" on public.homework;
create policy "homework_admin_write"
on public.homework for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
on public.notifications for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists "notifications_admin_insert" on public.notifications;
create policy "notifications_admin_insert"
on public.notifications for insert
to authenticated
with check (public.is_admin());

drop policy if exists "notifications_update_own_read_state" on public.notifications;
create policy "notifications_update_own_read_state"
on public.notifications for update
to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "notices_select_same_class_or_admin" on public.notices;
create policy "notices_select_same_class_or_admin"
on public.notices for select
to authenticated
using (public.is_admin() or public.is_same_class(class_number, section));

drop policy if exists "notices_admin_write" on public.notices;
create policy "notices_admin_write"
on public.notices for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "assignments_select_same_class_or_admin" on public.assignments;
create policy "assignments_select_same_class_or_admin"
on public.assignments for select
to authenticated
using (public.is_admin() or public.is_same_class(class_number, section));

drop policy if exists "assignments_admin_write" on public.assignments;
create policy "assignments_admin_write"
on public.assignments for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "announcements_select_same_class_or_admin" on public.announcements;
create policy "announcements_select_same_class_or_admin"
on public.announcements for select
to authenticated
using (public.is_admin() or public.is_same_class(class_number, section));

drop policy if exists "announcements_admin_write" on public.announcements;
create policy "announcements_admin_write"
on public.announcements for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'profiles'
  ) then
    alter publication supabase_realtime add table public.profiles;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'homework'
  ) then
    alter publication supabase_realtime add table public.homework;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notices'
  ) then
    alter publication supabase_realtime add table public.notices;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'assignments'
  ) then
    alter publication supabase_realtime add table public.assignments;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'announcements'
  ) then
    alter publication supabase_realtime add table public.announcements;
  end if;
end $$;

insert into storage.buckets (id, name, public)
values ('homework', 'homework', false)
on conflict (id) do nothing;

drop policy if exists "homework_storage_read_same_class_or_admin" on storage.objects;
create policy "homework_storage_read_same_class_or_admin"
on storage.objects for select
to authenticated
using (
  bucket_id = 'homework'
  and (
    public.is_admin()
    or exists (
      select 1
      from public.homework h
      where h.storage_path = storage.objects.name
        and public.is_same_class(h.class_number, h.section)
    )
  )
);

drop policy if exists "homework_storage_admin_write" on storage.objects;
create policy "homework_storage_admin_write"
on storage.objects for all
to authenticated
using (bucket_id = 'homework' and public.is_admin())
with check (bucket_id = 'homework' and public.is_admin());

commit;
