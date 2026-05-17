-- ==============================================================================
-- DATABASE REFACTORING AND NORMALIZATION MIGRATION
-- ==============================================================================
-- IMPORTANT: This script is wrapped in a transaction block. 
-- It is designed to be executed against a Supabase/PostgreSQL instance.
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. TIMESTAMPS AND TRIGGERS
-- ------------------------------------------------------------------------------
-- Create standard updated_at trigger function
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;+

-- Add updated_at columns where missing
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='updated_at') THEN ALTER TABLE public.profiles ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW(); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='notices' AND column_name='updated_at') THEN ALTER TABLE public.notices ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW(); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='assignments' AND column_name='updated_at') THEN ALTER TABLE public.assignments ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW(); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='alerts' AND column_name='updated_at') THEN ALTER TABLE public.alerts ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW(); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='todos' AND column_name='updated_at') THEN ALTER TABLE public.todos ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW(); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='updated_at') THEN ALTER TABLE public.notifications ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW(); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='channels' AND column_name='updated_at') THEN ALTER TABLE public.channels ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW(); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='servers' AND column_name='updated_at') THEN ALTER TABLE public.servers ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW(); END IF; END $$;

-- Apply triggers
DO $$ 
DECLARE
  t text;
BEGIN
  FOR t IN SELECT unnest(ARRAY['profiles', 'class_rooms', 'homework', 'notices', 'assignments', 'alerts', 'todos', 'calendar_events', 'servers', 'channels', 'notifications']) LOOP
    EXECUTE format('
      DROP TRIGGER IF EXISTS set_%1$s_updated_at ON public.%1$s;
      CREATE TRIGGER set_%1$s_updated_at
      BEFORE UPDATE ON public.%1$s
      FOR EACH ROW
      EXECUTE FUNCTION set_updated_at();
    ', t);
  END LOOP;
END $$;


-- ------------------------------------------------------------------------------
-- 2. DATA PRESERVATION (CLASS MIGRATION)
-- ------------------------------------------------------------------------------
-- Ensure all unique class_name and section combinations exist in class_rooms
INSERT INTO public.class_rooms (name, section)
SELECT sub.name, sub.section FROM (
  SELECT DISTINCT class_name as name, section
  FROM (
    SELECT class_name, section FROM public.homework WHERE class_name IS NOT NULL AND class_name != ''
    UNION SELECT class_name, section FROM public.notices WHERE class_name IS NOT NULL AND class_name != ''
    UNION SELECT class_name, section FROM public.assignments WHERE class_name IS NOT NULL AND class_name != ''
    UNION SELECT class as class_name, section FROM public.profiles WHERE class IS NOT NULL AND class != ''
    UNION SELECT class_name, section FROM public.calendar_events WHERE class_name IS NOT NULL AND class_name != ''
    UNION SELECT class_name, section FROM public.notifications WHERE class_name IS NOT NULL AND class_name != ''
  ) t
) sub
WHERE NOT EXISTS (
  SELECT 1 FROM public.class_rooms cr WHERE cr.name = sub.name AND cr.section = sub.section
);

-- Update class_id on tables where it's missing based on class_name/section
UPDATE public.homework h SET class_id = cr.id FROM public.class_rooms cr WHERE h.class_id IS NULL AND h.class_name = cr.name AND h.section = cr.section;
UPDATE public.notices n SET class_id = cr.id FROM public.class_rooms cr WHERE n.class_id IS NULL AND n.class_name = cr.name AND n.section = cr.section;
UPDATE public.assignments a SET class_id = cr.id FROM public.class_rooms cr WHERE a.class_id IS NULL AND a.class_name = cr.name AND a.section = cr.section;
UPDATE public.profiles p SET class_id = cr.id FROM public.class_rooms cr WHERE p.class_id IS NULL AND p.class = cr.name AND p.section = cr.section;
UPDATE public.calendar_events ce SET class_id = cr.id FROM public.class_rooms cr WHERE ce.class_id IS NULL AND ce.class_name = cr.name AND ce.section = cr.section;


-- ------------------------------------------------------------------------------
-- 3. ALERTS MIGRATION
-- ------------------------------------------------------------------------------
INSERT INTO public.alert_targets (alert_id, class_room_id)
SELECT a.id, unnest(a.target_class_ids)
FROM public.alerts a
WHERE a.target_class_ids IS NOT NULL AND array_length(a.target_class_ids, 1) > 0
ON CONFLICT DO NOTHING;


-- ------------------------------------------------------------------------------
-- 4. NOTIFICATIONS POLYMORPHISM
-- ------------------------------------------------------------------------------
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS entity_type TEXT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS entity_id UUID;

UPDATE public.notifications
SET entity_type = 'homework', entity_id = homework_id
WHERE homework_id IS NOT NULL;


-- ------------------------------------------------------------------------------
-- 5. STANDARDIZE USER IDENTITY & CASCADING DELETES
-- ------------------------------------------------------------------------------
-- Move user relationships from auth.users to public.profiles and add ON DELETE constraints
ALTER TABLE public.homework DROP CONSTRAINT IF EXISTS homework_uploaded_by_fkey;
ALTER TABLE public.homework ADD CONSTRAINT homework_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_created_by_fkey;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.notices DROP CONSTRAINT IF EXISTS notices_created_by_fkey;
ALTER TABLE public.notices ADD CONSTRAINT notices_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.assignments DROP CONSTRAINT IF EXISTS assignments_created_by_fkey;
ALTER TABLE public.assignments ADD CONSTRAINT assignments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.calendar_events DROP CONSTRAINT IF EXISTS calendar_events_created_by_fkey;
ALTER TABLE public.calendar_events ADD CONSTRAINT calendar_events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.todos DROP CONSTRAINT IF EXISTS todos_user_id_fkey;
ALTER TABLE public.todos ADD CONSTRAINT todos_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- Messenger system cascading deletes
ALTER TABLE public.channels DROP CONSTRAINT IF EXISTS channels_server_id_fkey;
ALTER TABLE public.channels ADD CONSTRAINT channels_server_id_fkey FOREIGN KEY (server_id) REFERENCES public.servers(id) ON DELETE CASCADE;

ALTER TABLE public.server_members DROP CONSTRAINT IF EXISTS server_members_server_id_fkey;
ALTER TABLE public.server_members ADD CONSTRAINT server_members_server_id_fkey FOREIGN KEY (server_id) REFERENCES public.servers(id) ON DELETE CASCADE;

ALTER TABLE public.channel_messages DROP CONSTRAINT IF EXISTS channel_messages_channel_id_fkey;
ALTER TABLE public.channel_messages ADD CONSTRAINT channel_messages_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.channels(id) ON DELETE CASCADE;

ALTER TABLE public.direct_messages DROP CONSTRAINT IF EXISTS direct_messages_sender_id_fkey;
ALTER TABLE public.direct_messages DROP CONSTRAINT IF EXISTS direct_messages_receiver_id_fkey;
ALTER TABLE public.direct_messages ADD CONSTRAINT direct_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.direct_messages ADD CONSTRAINT direct_messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- Alerts targets cascading
ALTER TABLE public.alert_targets DROP CONSTRAINT IF EXISTS alert_targets_alert_id_fkey;
ALTER TABLE public.alert_targets ADD CONSTRAINT alert_targets_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


-- ------------------------------------------------------------------------------
-- 6. DROP REDUNDANT COLUMNS
-- ------------------------------------------------------------------------------
-- Drop dependent policies first
DROP POLICY IF EXISTS "Students can read visible calendar events" ON public.calendar_events;

-- Profiles
ALTER TABLE public.profiles DROP COLUMN IF EXISTS class;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS section;
-- Homework
ALTER TABLE public.homework DROP COLUMN IF EXISTS class_name;
ALTER TABLE public.homework DROP COLUMN IF EXISTS section;
-- Notices
ALTER TABLE public.notices DROP COLUMN IF EXISTS class_name;
ALTER TABLE public.notices DROP COLUMN IF EXISTS section;
-- Assignments
ALTER TABLE public.assignments DROP COLUMN IF EXISTS class_name;
ALTER TABLE public.assignments DROP COLUMN IF EXISTS section;
-- Calendar Events
ALTER TABLE public.calendar_events DROP COLUMN IF EXISTS class_name;
ALTER TABLE public.calendar_events DROP COLUMN IF EXISTS section;
-- Notifications
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_homework_id_fkey;
ALTER TABLE public.notifications DROP COLUMN IF EXISTS homework_id;
ALTER TABLE public.notifications DROP COLUMN IF EXISTS class_name;
ALTER TABLE public.notifications DROP COLUMN IF EXISTS section;
-- Alerts
ALTER TABLE public.alerts DROP COLUMN IF EXISTS target_class_ids;


-- ------------------------------------------------------------------------------
-- 7. INDEX CREATION FOR PERFORMANCE
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_homework_class_id ON public.homework(class_id);
CREATE INDEX IF NOT EXISTS idx_homework_uploaded_by ON public.homework(uploaded_by);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_by ON public.notifications(created_by);
CREATE INDEX IF NOT EXISTS idx_notifications_entity ON public.notifications(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notices_class_id ON public.notices(class_id);
CREATE INDEX IF NOT EXISTS idx_notices_created_by ON public.notices(created_by);

CREATE INDEX IF NOT EXISTS idx_assignments_class_id ON public.assignments(class_id);
CREATE INDEX IF NOT EXISTS idx_assignments_created_by ON public.assignments(created_by);

CREATE INDEX IF NOT EXISTS idx_calendar_events_class_id ON public.calendar_events(class_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_created_by ON public.calendar_events(created_by);

CREATE INDEX IF NOT EXISTS idx_alert_targets_alert_id ON public.alert_targets(alert_id);
CREATE INDEX IF NOT EXISTS idx_alert_targets_class_room_id ON public.alert_targets(class_room_id);

CREATE INDEX IF NOT EXISTS idx_todos_user_id ON public.todos(user_id);

CREATE INDEX IF NOT EXISTS idx_channels_server_id ON public.channels(server_id);
CREATE INDEX IF NOT EXISTS idx_channel_messages_channel_id ON public.channel_messages(channel_id);
CREATE INDEX IF NOT EXISTS idx_channel_messages_created_at ON public.channel_messages(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_direct_messages_sender_id ON public.direct_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_direct_messages_receiver_id ON public.direct_messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_direct_messages_created_at ON public.direct_messages(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_friendships_sender_receiver ON public.friendships(sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_server_members_user_id ON public.server_members(user_id);

-- ------------------------------------------------------------------------------
-- 8. RECREATE POLICIES
-- ------------------------------------------------------------------------------
CREATE POLICY "Students can read visible calendar events" ON public.calendar_events FOR SELECT USING (
  auth.uid() IS NOT NULL AND (
    (COALESCE(cardinality(target_student_ids), 0) > 0 AND auth.uid() = ANY(target_student_ids)) OR
    (COALESCE(cardinality(target_student_ids), 0) = 0 AND class_id IS NULL) OR
    (COALESCE(cardinality(target_student_ids), 0) = 0 AND EXISTS (
      SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.class_id = calendar_events.class_id
    ))
  )
);

COMMIT;
