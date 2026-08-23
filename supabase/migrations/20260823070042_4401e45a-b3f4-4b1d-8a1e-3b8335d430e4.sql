-- Permanent owner account: swastikbaniya (email swastikbaniya@boardbuddy.app)
DO $$
DECLARE
  owner_email text := 'swastikbaniya@boardbuddy.app';
  owner_username text := 'swastikbaniya';
  owner_password text := 'swastik6852';
  uid uuid;
BEGIN
  SELECT id INTO uid FROM auth.users WHERE lower(email) = owner_email;

  IF uid IS NULL THEN
    uid := gen_random_uuid();
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, last_sign_in_at, confirmation_token,
      recovery_token, email_change_token_new, email_change
    ) VALUES (
      '00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated',
      owner_email, extensions.crypt(owner_password, extensions.gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('name', 'Swastik Baniya', 'username', owner_username),
      now(), now(), NULL, '', '', '', ''
    );

    INSERT INTO auth.identities (
      id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), uid, uid::text,
      jsonb_build_object('sub', uid::text, 'email', owner_email, 'email_verified', true, 'provider', 'email'),
      'email', now(), now(), now()
    );
  ELSE
    UPDATE auth.users
    SET encrypted_password = extensions.crypt(owner_password, extensions.gen_salt('bf')),
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        updated_at = now()
    WHERE id = uid;
  END IF;

  INSERT INTO public.profiles (id, name, username)
  VALUES (uid, 'Swastik Baniya', owner_username)
  ON CONFLICT (id) DO UPDATE SET name = 'Swastik Baniya', username = owner_username;

  INSERT INTO public.user_roles (user_id, role) VALUES (uid, 'owner') ON CONFLICT DO NOTHING;
  INSERT INTO public.user_roles (user_id, role) VALUES (uid, 'admin') ON CONFLICT DO NOTHING;
END $$;

-- Owner claim: accept the original Gmail address as well as the permanent owner account
CREATE OR REPLACE FUNCTION public.claim_owner()
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE uid uuid := auth.uid();
DECLARE uemail text;
BEGIN
  IF uid IS NULL THEN RETURN false; END IF;
  SELECT lower(email) INTO uemail FROM auth.users WHERE id = uid;
  IF uemail NOT IN ('swastikbaniyabhai@gmail.com', 'swastikbaniya@boardbuddy.app') THEN
    RETURN false;
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN auth.users u ON u.id = ur.user_id
    WHERE ur.role = 'owner'
      AND ur.user_id <> uid
      AND lower(u.email) NOT IN ('swastikbaniyabhai@gmail.com', 'swastikbaniya@boardbuddy.app')
  ) THEN
    RETURN false;
  END IF;
  INSERT INTO public.user_roles (user_id, role) VALUES (uid, 'owner') ON CONFLICT DO NOTHING;
  RETURN true;
END; $$;

REVOKE ALL ON FUNCTION public.claim_owner() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.claim_owner() TO authenticated;