import { createFileRoute, Link, Outlet, redirect, useNavigate } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { CrewContext, naira, type Role } from "@/lib/crew";
import { Logo } from "@/components/Logo";
import { Button } from "@/components/ui/button";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Wallet } from "lucide-react";

export const Route = createFileRoute("/_authenticated")({
  ssr: false,
  beforeLoad: async () => {
    const { data } = await supabase.auth.getSession();
    if (!data.session) throw redirect({ to: "/auth" });
    return { session: data.session };
  },
  component: CrewLayout,
});

function CrewLayout() {
  const { session } = Route.useRouteContext();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const uid = session.user.id;

  const { data, isLoading } = useQuery({
    queryKey: ["me", uid],
    queryFn: async () => {
      const [r, p] = await Promise.all([
        supabase.from("user_roles").select("role").eq("user_id", uid),
        supabase.from("profiles").select("full_name").eq("id", uid).maybeSingle(),
      ]);
      return { roles: (r.data ?? []).map((x) => x.role as Role), name: p.data?.full_name ?? "" };
    },
  });

  useEffect(() => {
    const { data } = supabase.auth.onAuthStateChange((e) => {
      if (e === "SIGNED_OUT") navigate({ to: "/auth", replace: true });
    });
    return () => data.subscription.unsubscribe();
  }, [navigate]);

  async function signOut() {
    await qc.cancelQueries();
    qc.clear();
    await supabase.auth.signOut();
    navigate({ to: "/auth", replace: true });
  }

  if (isLoading || !data) return <div className="min-h-screen bg-background" />;

  const roles = data.roles;
  const isDispatcher = roles.includes("dispatcher");
  const isDriver = roles.includes("driver");

  if (!isDispatcher && !isDriver) {
    return (
      <div className="grid min-h-screen place-items-center bg-background px-4">
        <div className="glass-card max-w-sm p-6 text-center">
          <h1 className="text-xl font-bold">Awaiting approval</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Your account is registered. A DOGO dispatcher needs to approve you as a driver or dispatcher before you can see trips.
          </p>
          <div className="mt-5 flex justify-center gap-2">
            <Button variant="outline" className="rounded-full" onClick={() => qc.invalidateQueries({ queryKey: ["me"] })}>Check again</Button>
            <Button variant="ghost" className="rounded-full" onClick={signOut}>Sign out</Button>
          </div>
        </div>
      </div>
    );
  }

  const nav = [
    { to: "/board", label: "Trips" },
    ...(isDispatcher ? [{ to: "/team", label: "Crew" }] : []),
  ] as const;

  return (
    <CrewContext.Provider value={{ session, roles, isDispatcher, isDriver, name: data.name }}>
      <div className="min-h-screen bg-background">
        <header className="glass-card sticky top-0 z-40 rounded-none border-x-0 border-t-0 px-4 py-3">
          <div className="mx-auto flex max-w-6xl items-center justify-between gap-3">
            <Link to="/board"><Logo /></Link>
            <div className="flex items-center gap-2">
              <nav className="flex gap-1">
                {nav.map((n) => (
                  <Link key={n.to} to={n.to} className="rounded-full px-3 py-1.5 text-sm font-medium text-muted-foreground hover:text-foreground"
                    activeProps={{ className: "bg-secondary text-foreground" }}>{n.label}</Link>
                ))}
              </nav>
              {isDriver ? <WalletPill /> : (
                <span className="hidden rounded-full border border-gold/40 bg-gold/10 px-3 py-1 text-xs font-bold text-gold sm:inline">Dispatcher</span>
              )}
              <Button size="sm" variant="outline" className="rounded-full" onClick={signOut}>Sign out</Button>
            </div>
          </div>
        </header>
        <main className="mx-auto max-w-6xl px-4 pb-16 pt-4"><Outlet /></main>
      </div>
    </CrewContext.Provider>
  );
}

function WalletPill() {
  const { data } = useQuery({
    queryKey: ["wallet"],
    refetchInterval: 30000,
    queryFn: async () => (await supabase.rpc("my_wallet")).data?.[0] ?? { balance: 0, trips_done: 0, today: 0 },
  });
  return (
    <Popover>
      <PopoverTrigger asChild>
        <button className="flex items-center gap-1.5 rounded-full border border-gold/40 bg-gold/10 px-3 py-1 text-xs font-bold text-gold">
          <Wallet className="h-3.5 w-3.5" /> <span className="tabular-nums">{naira(data?.balance ?? 0)}</span>
        </button>
      </PopoverTrigger>
      <PopoverContent align="end" className="glass-card w-64">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Wallet balance</p>
        <p className="font-display text-2xl font-extrabold tabular-nums">{naira(data?.balance ?? 0)}</p>
        <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
          <div><p className="text-muted-foreground">Today</p><p className="font-bold">{naira(data?.today ?? 0)}</p></div>
          <div><p className="text-muted-foreground">Trips done</p><p className="font-bold">{data?.trips_done ?? 0}</p></div>
        </div>
        <p className="mt-3 text-xs text-muted-foreground">You keep 70% of every fare. DOGO keeps 30%.</p>
      </PopoverContent>
    </Popover>
  );
}
