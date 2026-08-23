# BoardBuddy — apne Supabase project ko connect karne ki guide

Project: `nipxvtxfvcnwuwofxohd` (`https://nipxvtxfvcnwuwofxohd.supabase.co`)
App ki `.env` me URL + publishable key already set hai.

---

## 1. Database banaye (ek hi baar)

1. Supabase Dashboard → **SQL Editor** → **New query**
2. Repo ki file `supabase/SETUP.sql` ka poora content paste kijiye
3. **Run** dabaye

Isse ye sab ban jayega: `profiles`, `user_roles`, `attempts`, `bookmarks`,
`ads`, `audit_log`, `error_reports` waghairah + RLS policies + `claim_owner()`,
`has_role()`, `get_leaderboard()` functions.

> Note: `claim_owner()` sirf **swastikbaniyabhai@gmail.com** ko owner banata hai.
> Doosra email chahiye to SETUP.sql ki last function me wo email badal dijiye.

## 2. Google sign-in enable kijiye

**A. Google Cloud Console** (https://console.cloud.google.com)
1. Project banaye → **APIs & Services → OAuth consent screen** → External → app ka naam, support email bhar ke save
2. **Credentials → Create credentials → OAuth client ID → Web application**
3. **Authorized JavaScript origins**:
   - `http://localhost:8080`
   - aapka published domain (jaise `https://boardbuddy.lovable.app`)
4. **Authorized redirect URI** (bilkul yahi):
   - `https://nipxvtxfvcnwuwofxohd.supabase.co/auth/v1/callback`
5. **Client ID** aur **Client secret** copy kijiye

**B. Supabase Dashboard**
1. **Authentication → Sign In / Providers → Google** → Enable
2. Client ID + Client secret paste karke Save

**C. Redirect URLs (bahut zaroori — warna login ke baad wapas nahi aayega)**
Supabase → **Authentication → URL Configuration**:
- **Site URL**: aapka main app URL (dev me `http://localhost:8080`)
- **Redirect URLs** me add kijiye:
  - `http://localhost:8080/**`
  - `https://<aapka-published-domain>/**`

## 3. Email/password (optional)

Authentication → Providers → Email enabled rakhe. Testing me confirmation mail
se bachna ho to **Confirm email** off kar dijiye.

## 4. Owner panel unlock

1. App me `/auth` se apne owner email se sign in kijiye
2. `/owner` kholiye → **Claim owner access** dabaye
3. Ab Dashboard / Roles / Content / Ads / Audit / Errors sab tabs khulenge

## 5. Deploy

Cloudflare/Vercel par deploy karte waqt ye env vars set kijiye:

```
VITE_SUPABASE_URL=https://nipxvtxfvcnwuwofxohd.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_nr20nWAwaUCXCB5tdXGZOg_0V3P6UGg
VITE_SUPABASE_PROJECT_ID=nipxvtxfvcnwuwofxohd
SUPABASE_URL=https://nipxvtxfvcnwuwofxohd.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_nr20nWAwaUCXCB5tdXGZOg_0V3P6UGg
SUPABASE_PROJECT_ID=nipxvtxfvcnwuwofxohd
```

Service-role key kahin bhi frontend me mat daaliye — app ko uski zaroorat nahi hai.
