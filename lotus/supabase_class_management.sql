-- Class-driven ERP segmentation for LOTUS.
-- Run this in Supabase SQL editor, then enable Realtime for profiles,
-- homework, notifications, notices, assignments, and announcements as needed.

create table if not exists public.class_rooms (
  id uuid primary key default gen_random_uuid(),
  class_number integer not null check (class_number between 1 and 12),
  section text not null default '',
  academic_year text not null default '',
  schedule jsonb not null default '{}'::jsonb,
  resources jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (class_number, section, academic_year)
);

alter table public.class_rooms
  add column if not exists class_number integer;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'class_rooms'
      and column_name = 'name'
  ) then
    execute $sql$
      update public.class_rooms
      set class_number = case
        when class_number is not null then class_number
        when name::text ~ '^\d+$' then name::text::integer
        else null
      end
      where class_number is null
    $sql$;
  end if;
end $$;

alter table public.profiles
  add column if not exists class_id uuid references public.class_rooms(id),
  add column if not exists class integer,
  add column if not exists section text,
  add column if not exists updated_at timestamptz default now();

alter table public.profiles
  alter column class type integer using (
    case
      when class::text ~ '^\d+$' and class::text::integer between 1 and 12
        then class::text::integer
      else null
    end
  );

alter table public.homework
  add column if not exists class_number integer,
  add column if not exists section text not null default '';

alter table public.notifications
  add column if not exists class_number integer,
  add column if not exists section text not null default '';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_class_between_1_12'
  ) then
    alter table public.profiles
      add constraint profiles_class_between_1_12
      check (class is null or class between 1 and 12);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'homework_class_between_1_12'
  ) then
    alter table public.homework
      add constraint homework_class_between_1_12
      check (class_number is null or class_number between 1 and 12);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'notifications_class_between_1_12'
  ) then
    alter table public.notifications
      add constraint notifications_class_between_1_12
      check (class_number is null or class_number between 1 and 12);
  end if;
end $$;

create index if not exists profiles_class_lookup_idx
  on public.profiles (class, section);

create index if not exists homework_class_lookup_idx
  on public.homework (class_number, section, created_at desc);

create index if not exists notifications_class_lookup_idx
  on public.notifications (class_number, section, created_at desc);

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'profiles'
  ) then
    alter publication supabase_realtime add table public.profiles;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'homework'
  ) then
    alter publication supabase_realtime add table public.homework;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

-- Optional target tables for the same class-scoped pattern.
create table if not exists public.notices (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null default '',
  class_number integer not null check (class_number between 1 and 12),
  section text not null default '',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  due_at timestamptz,
  class_number integer not null check (class_number between 1 and 12),
  section text not null default '',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null default '',
  class_number integer not null check (class_number between 1 and 12),
  section text not null default '',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index if not exists notices_class_lookup_idx
  on public.notices (class_number, section, created_at desc);

create index if not exists assignments_class_lookup_idx
  on public.assignments (class_number, section, created_at desc);

create index if not exists announcements_class_lookup_idx
  on public.announcements (class_number, section, created_at desc);

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notices'
  ) then
    alter publication supabase_realtime add table public.notices;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'assignments'
  ) then
    alter publication supabase_realtime add table public.assignments;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'announcements'
  ) then
    alter publication supabase_realtime add table public.announcements;
  end if;
end $$;
