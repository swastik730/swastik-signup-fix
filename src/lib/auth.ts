import { useEffect, useState } from "react";
import type { Session } from "@supabase/supabase-js";
import { supabase } from "@/lib/supabase";
import { clearLocalState } from "./store";
import { stopSync, syncUser } from "./cloud";

let started = false;
let session: Session | null = null;
let ready = false;
const listeners = new Set<() => void>();
let syncedUserId: string | null = null;

function emit() {
  listeners.forEach((l) => l());
}

function handle(next: Session | null) {
  session = next;
  ready = true;
  emit();
  const userId = next?.user.id ?? null;
  if (userId && userId !== syncedUserId) {
    syncedUserId = userId;
    void syncUser(userId);
  } else if (!userId && syncedUserId) {
    syncedUserId = null;
    stopSync();
    clearLocalState();
  }
}

function start() {
  if (started || typeof window === "undefined") return;
  started = true;
  supabase.auth.onAuthStateChange((_event, next) => handle(next));
  void supabase.auth.getSession().then(({ data }) => handle(data.session));
}

export function useSession() {
  const [, force] = useState(0);
  useEffect(() => {
    start();
    const l = () => force((n) => n + 1);
    listeners.add(l);
    return () => {
      listeners.delete(l);
    };
  }, []);
  return { session, user: session?.user ?? null, ready };
}

export async function signOut() {
  await supabase.auth.signOut();
  handle(null);
}
