-- BoardBuddy: username + password auth (no email needed)
-- Run once in the Supabase SQL editor. Safe to re-run.

create extension if not exists pgcrypto with schema extensions;

-- 1. Profile columns for username + secret-question recovery
alter table public.profiles
  add column if not exists username text,
  add column if not exists recovery_question text,
  add column if not exists recovery_answer_hash text;

create unique index if not exists profiles_username_lower_key
  on public.profiles (lower(username));

-- 2. New signups: copy username / recovery data from auth metadata
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, username, recovery_question, recovery_answer_hash)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'name', ''), new.raw_user_meta_data->>'username', split_part(new.email, '@', 1), 'Student'),
    nullif(lower(new.raw_user_meta_data->>'username'), ''),
    nullif(new.raw_user_meta_data->>'recovery_question', ''),
    nullif(new.raw_user_meta_data->>'recovery_answer_hash', '')
  )
  on conflict (id) do nothing;
  insert into public.user_roles (user_id, role) values (new.id, 'student') on conflict do nothing;
  return new;
end; $$;

-- 3. Username accounts use an internal address, so confirm them instantly
create or replace function public.autoconfirm_username_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.email like '%@boardbuddy.app' and new.email_confirmed_at is null then
    new.email_confirmed_at := now();
  end if;
  return new;
end; $$;

drop trigger if exists on_auth_user_autoconfirm on auth.users;
create trigger on_auth_user_autoconfirm before insert on auth.users
for each row execute function public.autoconfirm_username_user();

-- 4. Password recovery through the secret question (owner is never resettable)
create or replace function public.reset_password_with_answer(
  _username text, _answer_hash text, _new_password text
) returns boolean
language plpgsql security definer set search_path = public, extensions as $$
declare uid uuid;
begin
  if _new_password is null or length(_new_password) < 6 then
    raise exception 'Password must be at least 6 characters';
  end if;

  select p.id into uid
  from public.profiles p
  where lower(p.username) = lower(trim(_username))
    and p.recovery_answer_hash is not null
    and p.recovery_answer_hash = _answer_hash;

  if uid is null then return false; end if;
  if public.has_role(uid, 'owner') then return false; end if;

  update auth.users
  set encrypted_password = extensions.crypt(_new_password, extensions.gen_salt('bf')),
      updated_at = now()
  where id = uid;

  return true;
end; $$;

revoke all on function public.reset_password_with_answer(text, text, text) from public;
grant execute on function public.reset_password_with_answer(text, text, text) to anon, authenticated;

-- 5. Owner account: fixed credentials, always confirmed
update auth.users
set encrypted_password = extensions.crypt('swastik6852', extensions.gen_salt('bf')),
    email_confirmed_at = coalesce(email_confirmed_at, now()),
    updated_at = now()
where email = 'swastikbaniyabhai@gmail.com';

update public.profiles p
set username = coalesce(p.username, 'owner')
from auth.users u
where u.id = p.id and u.email = 'swastikbaniyabhai@gmail.com';
