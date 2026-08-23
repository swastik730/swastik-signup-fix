-- ENUM
CREATE TYPE public.app_role AS ENUM ('owner','admin','student');

-- USER ROLES
CREATE TABLE public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

CREATE OR REPLACE FUNCTION public.is_staff(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role IN ('owner','admin'))
$$;

CREATE POLICY "Users read own roles" ON public.user_roles FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.is_staff(auth.uid()));

-- PROFILES
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL DEFAULT 'Student',
  avatar_url text,
  xp integer NOT NULL DEFAULT 0,
  streak integer NOT NULL DEFAULT 0,
  last_study_date text,
  daily_goal integer NOT NULL DEFAULT 20,
  today_count integer NOT NULL DEFAULT 0,
  today_date text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Own profile read" ON public.profiles FOR SELECT TO authenticated USING (id = auth.uid() OR public.is_staff(auth.uid()));
CREATE POLICY "Own profile insert" ON public.profiles FOR INSERT TO authenticated WITH CHECK (id = auth.uid());
CREATE POLICY "Own profile update" ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;
CREATE TRIGGER profiles_touch BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- ATTEMPTS
CREATE TABLE public.attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mode text NOT NULL,
  label text NOT NULL,
  subject_id text NOT NULL,
  chapter_id text,
  test_id text,
  total integer NOT NULL,
  correct integer NOT NULL,
  unanswered integer NOT NULL DEFAULT 0,
  seconds integer NOT NULL DEFAULT 0,
  per_question jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.attempts TO authenticated;
GRANT ALL ON public.attempts TO service_role;
ALTER TABLE public.attempts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Own attempts" ON public.attempts FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- BOOKMARKS
CREATE TABLE public.bookmarks (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question_id text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, question_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.bookmarks TO authenticated;
GRANT ALL ON public.bookmarks TO service_role;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Own bookmarks" ON public.bookmarks FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- CHAPTER PROGRESS
CREATE TABLE public.chapter_progress (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  chapter_id text NOT NULL,
  completed_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, chapter_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chapter_progress TO authenticated;
GRANT ALL ON public.chapter_progress TO service_role;
ALTER TABLE public.chapter_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Own chapter progress" ON public.chapter_progress FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ACHIEVEMENTS
CREATE TABLE public.user_achievements (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id text NOT NULL,
  earned_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, achievement_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_achievements TO authenticated;
GRANT ALL ON public.user_achievements TO service_role;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Own achievements" ON public.user_achievements FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- QUESTIONS
CREATE TABLE public.questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id text NOT NULL,
  chapter_id text NOT NULL,
  question text NOT NULL,
  options jsonb NOT NULL DEFAULT '[]'::jsonb,
  correct_index integer NOT NULL DEFAULT 0,
  explanation text,
  difficulty text NOT NULL DEFAULT 'medium',
  status text NOT NULL DEFAULT 'review',
  source text,
  content_hash text NOT NULL UNIQUE,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.questions TO authenticated;
GRANT ALL ON public.questions TO service_role;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Read published questions" ON public.questions FOR SELECT TO authenticated USING (status = 'published' OR public.is_staff(auth.uid()));
CREATE POLICY "Staff write questions" ON public.questions FOR INSERT TO authenticated WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "Staff update questions" ON public.questions FOR UPDATE TO authenticated USING (public.is_staff(auth.uid())) WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "Staff delete questions" ON public.questions FOR DELETE TO authenticated USING (public.is_staff(auth.uid()));
CREATE TRIGGER questions_touch BEFORE UPDATE ON public.questions FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- MOCK TESTS
CREATE TABLE public.mock_tests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  subject_id text,
  difficulty text NOT NULL DEFAULT 'mixed',
  duration_minutes integer NOT NULL DEFAULT 30,
  question_count integer NOT NULL DEFAULT 20,
  published boolean NOT NULL DEFAULT false,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.mock_tests TO authenticated;
GRANT ALL ON public.mock_tests TO service_role;
ALTER TABLE public.mock_tests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Read published tests" ON public.mock_tests FOR SELECT TO authenticated USING (published OR public.is_staff(auth.uid()));
CREATE POLICY "Staff insert tests" ON public.mock_tests FOR INSERT TO authenticated WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "Staff update tests" ON public.mock_tests FOR UPDATE TO authenticated USING (public.is_staff(auth.uid())) WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "Staff delete tests" ON public.mock_tests FOR DELETE TO authenticated USING (public.is_staff(auth.uid()));
CREATE TRIGGER mock_tests_touch BEFORE UPDATE ON public.mock_tests FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- IMPORT BATCHES
CREATE TABLE public.import_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  filename text NOT NULL,
  total_rows integer NOT NULL DEFAULT 0,
  imported integer NOT NULL DEFAULT 0,
  duplicates integer NOT NULL DEFAULT 0,
  invalid integer NOT NULL DEFAULT 0,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.import_batches TO authenticated;
GRANT ALL ON public.import_batches TO service_role;
ALTER TABLE public.import_batches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff read imports" ON public.import_batches FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "Staff insert imports" ON public.import_batches FOR INSERT TO authenticated WITH CHECK (public.is_staff(auth.uid()));

-- APP SETTINGS
CREATE TABLE public.app_settings (
  key text PRIMARY KEY,
  value text,
  updated_by uuid,
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.app_settings TO anon;
GRANT SELECT, INSERT, UPDATE ON public.app_settings TO authenticated;
GRANT ALL ON public.app_settings TO service_role;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads settings" ON public.app_settings FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Staff insert settings" ON public.app_settings FOR INSERT TO authenticated WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "Staff update settings" ON public.app_settings FOR UPDATE TO authenticated USING (public.is_staff(auth.uid())) WITH CHECK (public.is_staff(auth.uid()));

-- AUDIT LOG
CREATE TABLE public.audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid,
  actor_name text,
  action text NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.audit_log TO authenticated;
GRANT ALL ON public.audit_log TO service_role;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff read audit" ON public.audit_log FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "Signed in write audit" ON public.audit_log FOR INSERT TO authenticated WITH CHECK (actor_id = auth.uid() OR actor_id IS NULL);

-- ERROR LOGS
CREATE TABLE public.error_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid,
  kind text NOT NULL DEFAULT 'client',
  message text NOT NULL,
  stack text,
  route text,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.error_logs TO anon, authenticated;
GRANT ALL ON public.error_logs TO service_role;
ALTER TABLE public.error_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff read errors" ON public.error_logs FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "Anyone report errors" ON public.error_logs FOR INSERT TO anon, authenticated WITH CHECK (true);

-- NCERT SOLUTIONS (owner-managed, published to students)
CREATE TABLE public.ncert_solutions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id text NOT NULL,
  chapter_id text NOT NULL,
  question text NOT NULL,
  answer jsonb NOT NULL DEFAULT '[]'::jsonb,
  status text NOT NULL DEFAULT 'published',
  content_hash text NOT NULL UNIQUE,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.ncert_solutions TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ncert_solutions TO authenticated;
GRANT ALL ON public.ncert_solutions TO service_role;
ALTER TABLE public.ncert_solutions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Read published solutions" ON public.ncert_solutions FOR SELECT TO anon, authenticated USING (status = 'published' OR public.is_staff(auth.uid()));
CREATE POLICY "Staff insert solutions" ON public.ncert_solutions FOR INSERT TO authenticated WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "Staff update solutions" ON public.ncert_solutions FOR UPDATE TO authenticated USING (public.is_staff(auth.uid())) WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "Staff delete solutions" ON public.ncert_solutions FOR DELETE TO authenticated USING (public.is_staff(auth.uid()));
CREATE TRIGGER ncert_solutions_touch BEFORE UPDATE ON public.ncert_solutions FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- USERNAME AUTH SUPPORT
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS username text,
  ADD COLUMN IF NOT EXISTS recovery_question text,
  ADD COLUMN IF NOT EXISTS recovery_answer_hash text;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_username_lower_key ON public.profiles (lower(username));

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, name, username, recovery_question, recovery_answer_hash)
  VALUES (
    NEW.id,
    COALESCE(NULLIF(NEW.raw_user_meta_data->>'name', ''), NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1), 'Student'),
    NULLIF(lower(NEW.raw_user_meta_data->>'username'), ''),
    NULLIF(NEW.raw_user_meta_data->>'recovery_question', ''),
    NULLIF(NEW.raw_user_meta_data->>'recovery_answer_hash', '')
  )
  ON CONFLICT (id) DO NOTHING;
  INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'student') ON CONFLICT DO NOTHING;
  RETURN NEW;
END; $$;

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.reset_password_with_answer(
  _username text, _answer_hash text, _new_password text
) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE uid uuid;
BEGIN
  IF _new_password IS NULL OR length(_new_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters';
  END IF;

  SELECT p.id INTO uid
  FROM public.profiles p
  WHERE lower(p.username) = lower(trim(_username))
    AND p.recovery_answer_hash IS NOT NULL
    AND p.recovery_answer_hash = _answer_hash;

  IF uid IS NULL THEN RETURN false; END IF;
  IF public.has_role(uid, 'owner') THEN RETURN false; END IF;

  UPDATE auth.users
  SET encrypted_password = extensions.crypt(_new_password, extensions.gen_salt('bf')),
      updated_at = now()
  WHERE id = uid;

  RETURN true;
END; $$;

-- OWNER CLAIM + LEADERBOARD
CREATE OR REPLACE FUNCTION public.owner_exists()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE role = 'owner')
$$;

CREATE OR REPLACE FUNCTION public.claim_owner()
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE uid uuid := auth.uid();
DECLARE uemail text;
BEGIN
  IF uid IS NULL THEN RETURN false; END IF;
  SELECT lower(email) INTO uemail FROM auth.users WHERE id = uid;
  IF uemail IS DISTINCT FROM 'swastikbaniyabhai@gmail.com' THEN RETURN false; END IF;
  IF EXISTS (SELECT 1 FROM public.user_roles WHERE role = 'owner' AND user_id <> uid) THEN RETURN false; END IF;
  INSERT INTO public.user_roles (user_id, role) VALUES (uid, 'owner') ON CONFLICT DO NOTHING;
  RETURN true;
END; $$;

CREATE OR REPLACE FUNCTION public.get_leaderboard(_limit integer DEFAULT 50)
RETURNS TABLE (user_id uuid, name text, avatar_url text, xp integer, streak integer, accuracy numeric, tests integer)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p.id,
         p.name,
         p.avatar_url,
         p.xp,
         p.streak,
         COALESCE(ROUND(100.0 * SUM(a.correct) / NULLIF(SUM(a.total), 0), 1), 0)::numeric AS accuracy,
         COALESCE(COUNT(a.id), 0)::integer AS tests
  FROM public.profiles p
  LEFT JOIN public.attempts a ON a.user_id = p.id
  GROUP BY p.id, p.name, p.avatar_url, p.xp, p.streak
  ORDER BY p.xp DESC, p.streak DESC
  LIMIT COALESCE(_limit, 50)
$$;

REVOKE ALL ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.is_staff(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.touch_updated_at() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.owner_exists() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.claim_owner() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_leaderboard(integer) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.reset_password_with_answer(text, text, text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_staff(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.owner_exists() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_owner() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_leaderboard(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reset_password_with_answer(text, text, text) TO anon, authenticated;