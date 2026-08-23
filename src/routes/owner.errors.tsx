import { createFileRoute } from "@tanstack/react-router";
import { useCallback, useEffect, useState } from "react";
import { AlertTriangle, Loader2, RefreshCw, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/lib/supabase";

export const Route = createFileRoute("/owner/errors")({
  component: OwnerErrors,
});

type ErrorRow = {
  id: string;
  message: string;
  stack: string | null;
  route: string | null;
  kind: string;
  user_agent: string | null;
  created_at: string;
};

function OwnerErrors() {
  const [rows, setRows] = useState<ErrorRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from("error_logs")
      .select("id,message,stack,route,kind,user_agent,created_at")
      .order("created_at", { ascending: false })
      .limit(200);
    if (error) toast.error("Couldn't load errors", { description: error.message });
    setRows((data ?? []) as ErrorRow[]);
    setLoading(false);
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function clearAll() {
    const { error } = await supabase.from("error_logs").delete().neq("id", "00000000-0000-0000-0000-000000000000");
    if (error) {
      toast.error("Clear failed", { description: error.message });
      return;
    }
    toast.success("Error log cleared");
    void load();
  }

  return (
    <div className="space-y-3">
      <div className="surface flex items-center justify-between gap-3 p-4">
        <div className="flex items-center gap-3">
          <span className="grid h-10 w-10 place-items-center rounded-xl bg-warning-soft text-warning">
            <AlertTriangle className="h-5 w-5" />
          </span>
          <div>
            <p className="text-sm font-bold">Error monitoring</p>
            <p className="text-xs text-muted-foreground">{rows.length} recent reports</p>
          </div>
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => void load()}
            className="grid h-9 w-9 place-items-center rounded-xl border border-input text-muted-foreground"
            aria-label="Refresh"
          >
            <RefreshCw className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={() => void clearAll()}
            className="grid h-9 w-9 place-items-center rounded-xl border border-input text-destructive"
            aria-label="Clear all"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
      </div>

      {loading ? (
        <p className="flex items-center justify-center gap-2 py-10 text-sm text-muted-foreground">
          <Loader2 className="h-4 w-4 animate-spin" /> Loading…
        </p>
      ) : rows.length === 0 ? (
        <p className="surface p-6 text-center text-sm text-muted-foreground">
          No error reports yet — everything is clean.
        </p>
      ) : (
        <ul className="space-y-2">
          {rows.map((r) => (
            <li key={r.id} className="surface p-4">
              <button
                type="button"
                onClick={() => setOpen(open === r.id ? null : r.id)}
                className="w-full text-left"
              >
                <p className="text-sm font-semibold leading-snug">{r.message}</p>
                <p className="mt-1 text-xs text-muted-foreground">
                  {r.kind} · {r.route ?? "—"} · {new Date(r.created_at).toLocaleString()}
                </p>
              </button>
              {open === r.id && r.stack ? (
                <pre className="mt-3 max-h-56 overflow-auto rounded-lg bg-muted p-3 text-[11px] leading-relaxed">
                  {r.stack}
                </pre>
              ) : null}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
