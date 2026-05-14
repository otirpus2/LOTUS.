-- Calendar events for the LOTUS student app.
-- This script is intentionally additive: it does not change your existing
-- profiles, class_rooms, homework, notifications, notices, or todos columns.
--
-- Event types:
-- 1. Common event: class_name is null/blank and target_student_ids is empty.
-- 2. Class event: class_name is set, section is optional, target_student_ids is empty.
-- 3. Student event: target_student_ids contains one or more auth/profile ids.

create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  event_date date not null,
  color_hex text not null default '#4285F4',
  class_name text,
  section text not null default '',
  target_student_ids uuid[] not null default '{}'::uuid[],
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint calendar_events_color_hex_format
    check (color_hex ~ '^#[0-9A-Fa-f]{6}$')
);

alter table public.calendar_events
  add column if not exists title text not null default '',
  add column if not exists description text not null default '',
  add column if not exists event_date date,
  add column if not exists color_hex text not null default '#4285F4',
  add column if not exists class_name text,
  add column if not exists section text not null default '',
  add column if not exists target_student_ids uuid[] not null default '{}'::uuid[],
  add column if not exists created_by uuid references auth.users(id),
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.calendar_events
  drop column if exists target_group;

create index if not exists calendar_events_date_idx
  on public.calendar_events (event_date);

create index if not exists calendar_events_class_lookup_idx
  on public.calendar_events (lower(trim(class_name)), lower(trim(section)), event_date);

create index if not exists calendar_events_target_student_ids_idx
  on public.calendar_events using gin (target_student_ids);

alter table public.calendar_events enable row level security;

drop policy if exists "Admins can manage calendar events"
  on public.calendar_events;

drop policy if exists "Students can read targeted calendar events"
  on public.calendar_events;

drop policy if exists "Students can read visible calendar events"
  on public.calendar_events;

drop function if exists public.current_profile_is_admin();

create policy "Students can read visible calendar events"
  on public.calendar_events
  for select
  using (
    auth.uid() is not null
    and (
      (
        coalesce(cardinality(calendar_events.target_student_ids), 0) > 0
        and auth.uid() = any(calendar_events.target_student_ids)
      )
      or (
        coalesce(cardinality(calendar_events.target_student_ids), 0) = 0
        and nullif(trim(coalesce(calendar_events.class_name, '')), '') is null
      )
      or (
        coalesce(cardinality(calendar_events.target_student_ids), 0) = 0
        and exists (
          select 1
          from public.profiles p
          where p.id = auth.uid()
            and lower(trim(coalesce(p.class::text, ''))) =
                lower(trim(coalesce(calendar_events.class_name, '')))
            and (
              trim(coalesce(calendar_events.section, '')) = ''
              or lower(trim(coalesce(p.section, ''))) =
                 lower(trim(calendar_events.section))
            )
        )
      )
    )
  );

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'calendar_events'
  ) then
    alter publication supabase_realtime add table public.calendar_events;
  end if;
end $$;
