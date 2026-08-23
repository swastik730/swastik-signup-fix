import { createFileRoute, useNavigate, Link } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { CloudUpload, Loader2, ShieldCheck } from "lucide-react";
import { supabase } from "@/lib/supabase";
import { BrandMark } from "@/components/AppShell";
import { useSession } from "@/lib/auth";
import {
  RECOVERY_QUESTIONS,
  hashAnswer,
  identifierToEmail,
  isValidUsername,
  normalizeUsername,
} from "@/lib/username";

/** Only same-origin relative paths are accepted as a post-login destination. */
function safeRedirect(value: unknown): string {
  const raw = typeof value === "string" ? value : "";
  return raw.startsWith("/") && !raw.startsWith("//") ? raw : "/";
}

export const Route = createFileRoute("/auth")({
  validateSearch: (search: Record<string, unknown>): { redirect?: string } => {
    const raw = search["redirect"];
    return typeof raw === "string" ? { redirect: safeRedirect(raw) } : {};
  },
  head: () => ({
    meta: [
      { title: "Sign in to BoardBuddy | Sync your Class 10 progress" },
      {
        name: "description",
        content:
          "Create a BoardBuddy account with just a username and password to sync XP, streak, quiz attempts and bookmarks across devices.",
      },
      { property: "og:title", content: "Sign in to BoardBuddy" },
      {
        property: "og:description",
        content: "Save your Class 10 board preparation progress and study from any device.",
      },
    ],
  }),
  component: AuthPage,
});

const inputClass =
  "h-12 w-full rounded-xl border border-input bg-background px-3 text-sm outline-none focus:border-primary";

function AuthPage() {
  const navigate = useNavigate();
  const { redirect } = Route.useSearch();
  const { user, ready } = useSession();
  const [mode, setMode] = useState<"signin" | "signup" | "forgot">("signin");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [question, setQuestion] = useState(RECOVERY_QUESTIONS[0] as string);
  const [answer, setAnswer] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);

  const target = safeRedirect(redirect);

  useEffect(() => {
    if (ready && user) void navigate({ to: target, replace: true });
  }, [ready, user, target, navigate]);

  function switchMode(next: "signin" | "signup" | "forgot") {
    setMode(next);
    setError(null);
    setInfo(null);
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setInfo(null);

    const id = username.trim();
    if (!id) return setError("Username daaliye.");

    if (mode !== "signin" && !isValidUsername(id)) {
      return setError("Username 3-20 characters ka ho — sirf letters, numbers, . aur _");
    }

    setBusy(true);
    try {
      if (mode === "forgot") {
        if (!answer.trim()) return setError("Secret answer daaliye.");
        if (password.length < 6) return setError("Naya password kam se kam 6 characters ka ho.");
        const rpc = supabase.rpc as unknown as (
          fn: string,
          args: Record<string, unknown>,
        ) => Promise<{ data: boolean | null; error: { message: string } | null }>;
        const { data, error: err } = await rpc("reset_password_with_answer", {
          _username: normalizeUsername(id),
          _answer_hash: await hashAnswer(id, answer),
          _new_password: password,
        });
        if (err) return setError(err.message);
        if (!data) return setError("Username ya secret answer galat hai (owner account reset nahi hota).");
        setInfo("Password badal gaya! Ab naye password se sign in kijiye.");
        setAnswer("");
        setPassword("");
        setMode("signin");
        return;
      }

      if (mode === "signup") {
        if (password.length < 6) return setError("Password kam se kam 6 characters ka ho.");
        if (!answer.trim()) return setError("Secret answer daaliye — password bhoolne par yahi kaam aayega.");
        const { data, error: err } = await supabase.auth.signUp({
          email: identifierToEmail(id),
          password,
          options: {
            data: {
              name: name.trim() || normalizeUsername(id),
              username: normalizeUsername(id),
              recovery_question: question,
              recovery_answer_hash: await hashAnswer(id, answer),
            },
          },
        });
        if (err) {
          return setError(
            /already|exists|duplicate/i.test(err.message)
              ? "Yeh username pehle se le liya gaya hai — dusra try kijiye."
              : err.message,
          );
        }
        if (!data.session) {
          const { error: signInErr } = await supabase.auth.signInWithPassword({
            email: identifierToEmail(id),
            password,
          });
          if (signInErr) return setError(signInErr.message);
        }
        void navigate({ to: target, replace: true });
        return;
      }

      const { data, error: err } = await supabase.auth.signInWithPassword({
        email: identifierToEmail(id),
        password,
      });
      if (err) {
        return setError(
          /invalid/i.test(err.message) ? "Username ya password galat hai." : err.message,
        );
      }
      if (data.session) void navigate({ to: target, replace: true });
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mx-auto flex min-h-screen w-full max-w-md flex-col justify-center px-5 py-10">
      <div className="mb-6 text-center">
        <Link to="/" className="inline-block">
          <BrandMark className="justify-center" />
        </Link>
        <h1 className="mt-5 text-2xl font-extrabold tracking-tight">
          {mode === "signin"
            ? "Welcome back"
            : mode === "signup"
              ? "Create your account"
              : "Reset your password"}
        </h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {mode === "forgot"
            ? "Username aur secret answer se naya password set kijiye."
            : "Sirf username aur password — koi email ki zaroorat nahi."}
        </p>
      </div>

      <div className="surface p-5">
        <form onSubmit={submit} className="space-y-3">
          {mode === "signup" && (
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Aapka naam (display name)"
              autoComplete="name"
              className={inputClass}
            />
          )}

          <input
            required
            id="username"
            name="username"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder="Username"
            autoComplete="username"
            aria-label="Username"
            className={inputClass}
          />

          <input
            type="password"
            required
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder={mode === "forgot" ? "Naya password (min 6)" : "Password (min 6 characters)"}
            autoComplete={mode === "signin" ? "current-password" : "new-password"}
            className={inputClass}
          />

          {mode === "signup" && (
            <>
              <select
                value={question}
                onChange={(e) => setQuestion(e.target.value)}
                className={inputClass}
                aria-label="Secret question"
              >
                {RECOVERY_QUESTIONS.map((q) => (
                  <option key={q} value={q}>
                    {q}
                  </option>
                ))}
              </select>
              <input
                required
                value={answer}
                onChange={(e) => setAnswer(e.target.value)}
                placeholder="Secret answer (yaad rakhiye)"
                className={inputClass}
              />
            </>
          )}

          {mode === "forgot" && (
            <input
              required
              value={answer}
              onChange={(e) => setAnswer(e.target.value)}
              placeholder="Secret answer"
              className={inputClass}
            />
          )}

          {mode === "signin" && (
            <button
              type="button"
              onClick={() => switchMode("forgot")}
              className="w-full text-right text-xs font-semibold text-primary"
            >
              Forgot password?
            </button>
          )}

          {error && <p className="text-xs font-semibold text-destructive">{error}</p>}
          {info && (
            <p className="flex items-start gap-2 rounded-xl bg-success-soft px-3 py-2 text-xs font-semibold text-success">
              <ShieldCheck className="mt-0.5 h-3.5 w-3.5 shrink-0" />
              {info}
            </p>
          )}

          <button
            type="submit"
            disabled={busy}
            className="brand-gradient flex h-12 w-full items-center justify-center gap-2 rounded-xl text-sm font-bold text-primary-foreground disabled:opacity-60"
          >
            {busy && <Loader2 className="h-4 w-4 animate-spin" />}
            {mode === "signin" ? "Sign in" : mode === "signup" ? "Create account" : "Set new password"}
          </button>
        </form>

        <button
          type="button"
          onClick={() => switchMode(mode === "signup" ? "signin" : "signup")}
          className="mt-4 w-full text-center text-xs font-semibold text-primary"
        >
          {mode === "signup" ? "Already have an account? Sign in" : "Need an account? Sign up"}
        </button>
      </div>

      <p className="mt-5 flex items-center justify-center gap-2 text-center text-xs text-muted-foreground">
        <CloudUpload className="h-3.5 w-3.5" />
        Bina account ke bhi padh sakte hain — progress isi device par save rahegi.
      </p>
      <Link to="/" className="mt-3 text-center text-xs font-semibold text-primary">
        Continue without account
      </Link>
    </div>
  );
}
