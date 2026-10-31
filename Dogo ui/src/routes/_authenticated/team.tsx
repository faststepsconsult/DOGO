import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useCrew } from "@/lib/crew";
import { Switch } from "@/components/ui/switch";

export const Route = createFileRoute("/_authenticated/team")({
  head: () => ({
    meta: [
      { title: "Crew members — DOGO Crew" },
      { name: "description", content: "Approve drivers and dispatchers." },
      { property: "og:title", content: "Crew members — DOGO Crew" },
      { property: "og:description", content: "Approve drivers and dispatchers." },
    ],
  }),
  component: Team,
});

function Team() {
  const { isDispatcher, session } = useCrew();
  const qc = useQueryClient();
  const { data: members = [] } = useQuery({
    queryKey: ["members"],
    enabled: isDispatcher,
    queryFn: async () => (await supabase.rpc("list_members")).data ?? [],
  });

  if (!isDispatcher) return <p className="py-20 text-center text-muted-foreground">Dispatchers only.</p>;

  async function toggle(user: string, role: "driver" | "dispatcher", grant: boolean) {
    const { error } = await supabase.rpc("set_member_role", { _user: user, _role: role, _grant: grant });
    if (error) { toast.error(error.message); return; }
    qc.invalidateQueries({ queryKey: ["members"] });
  }

  const pending = members.filter((m) => !m.roles.includes("driver") && !m.roles.includes("dispatcher"));

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-extrabold">Crew</h1>
        <p className="text-sm text-muted-foreground">Only approved drivers and dispatchers can see trips and customers.</p>
      </div>
      {pending.length > 0 && (
        <p className="rounded-xl border border-gold/40 bg-gold/10 p-3 text-sm">
          <span className="font-bold text-gold">{pending.length}</span> waiting for approval.
        </p>
      )}
      <div className="glass-card divide-y divide-border">
        {members.map((m) => (
          <div key={m.id} className="flex flex-wrap items-center justify-between gap-3 p-4">
            <div>
              <p className="font-semibold">{m.full_name || "Unnamed"} {m.id === session.user.id && <span className="text-xs text-muted-foreground">(you)</span>}</p>
              <p className="text-xs text-muted-foreground">{m.phone ?? "No phone"}</p>
            </div>
            <div className="flex gap-5 text-sm">
              {(["driver", "dispatcher"] as const).map((r) => (
                <label key={r} className="flex items-center gap-2 capitalize">
                  <Switch checked={m.roles.includes(r)} disabled={m.id === session.user.id && r === "dispatcher"}
                    onCheckedChange={(v) => toggle(m.id, r, v)} />
                  {r}
                </label>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
