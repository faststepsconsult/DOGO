import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { BikeIcon, CarFrontIcon, ShieldCheck } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { lovable } from "@/integrations/lovable/index";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Logo } from "@/components/Logo";

export const Route = createFileRoute("/auth")({
  ssr: false,
  head: () => ({
    meta: [
      { title: "Crew sign in — DOGO Rides" },
      { name: "description", content: "Sign in to the DOGO Rides driver and dispatcher console." },
      { property: "og:title", content: "Crew sign in — DOGO Rides" },
      { property: "og:description", content: "Drivers and dispatchers only." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: AuthPage,
});

function AuthPage() {
  const navigate = useNavigate();
  const [mode, setMode] = useState<"in" | "up">("in");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    const { data } = supabase.auth.onAuthStateChange((_e, s) => {
      if (s) navigate({ to: "/board", replace: true });
    });
    supabase.auth.getSession().then(({ data }) => data.session && navigate({ to: "/board", replace: true }));
    return () => data.subscription.unsubscribe();
  }, [navigate]);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    if (mode === "in") {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) toast.error(error.message);
    } else {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: { emailRedirectTo: window.location.origin, data: { full_name: name, phone } },
      });
      if (error) toast.error(error.message);
      else if (!data.session) toast.success("Check your email to confirm your account.");
    }
    setBusy(false);
  }

  async function google() {
    const r = await lovable.auth.signInWithOAuth("google", { redirect_uri: window.location.origin });
    if (r.error) toast.error("Google sign-in failed");
  }

  return (
    <div className="min-h-screen bg-background px-4 py-10 sm:py-14">
      <div className="mx-auto flex max-w-xl flex-col items-center">
        <div className="mb-8 self-start"><Logo /></div>

        <h1 className="font-display text-4xl font-extrabold tracking-tight">Welcome to DOGO</h1>
        <p className="mt-1.5 text-sm text-muted-foreground">Crew console — for riders, drivers and dispatchers.</p>

        {/* Role cards, matching the DOGO Rides sign-in template */}
        <div className="mt-6 grid w-full grid-cols-2 gap-3">
          <div className="rounded-2xl border-2 border-primary bg-primary/10 p-4">
            <CarFrontIcon className="h-5 w-5 text-primary" />
            <p className="mt-2 font-semibold">Rider / Driver</p>
            <p className="mt-0.5 text-xs text-muted-foreground">Drive and manage your trips.</p>
          </div>
          <div className="rounded-2xl border border-border bg-card p-4 opacity-70">
            <BikeIcon className="h-5 w-5 text-gold" />
            <p className="mt-2 font-semibold">Dispatcher</p>
            <p className="mt-0.5 text-xs text-muted-foreground">Granted by DOGO after sign-up.</p>
          </div>
        </div>

        <form onSubmit={submit} className="glass-card mt-5 w-full p-6">
          {/* Segmented pill toggle */}
          <div className="flex rounded-full border border-border bg-secondary/60 p-1">
            {(["up", "in"] as const).map((m) => (
              <button key={m} type="button" onClick={() => setMode(m)}
                className={`flex-1 rounded-full py-2.5 text-sm font-bold transition-colors ${mode === m ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground"}`}>
                {m === "up" ? "Create account" : "Sign in"}
              </button>
            ))}
          </div>

          <div className="mt-5 space-y-4">
            {mode === "up" && (
              <>
                <div>
                  <Label>Full name</Label>
                  <Input className="mt-1.5 h-11 rounded-xl" placeholder="Amaka Nwosu" required value={name} onChange={(e) => setName(e.target.value)} />
                </div>
                <div>
                  <Label>Phone number</Label>
                  <Input className="mt-1.5 h-11 rounded-xl" placeholder="+234 802 000 0000" required value={phone} onChange={(e) => setPhone(e.target.value)} />
                </div>
              </>
            )}
            <div>
              <Label>Email address</Label>
              <Input className="mt-1.5 h-11 rounded-xl" type="email" placeholder="you@example.com" required value={email} onChange={(e) => setEmail(e.target.value)} />
            </div>
            <div>
              <Label>Password</Label>
              <Input className="mt-1.5 h-11 rounded-xl" type="password" required minLength={6} value={password} onChange={(e) => setPassword(e.target.value)} />
            </div>
            <Button disabled={busy} className="h-12 w-full rounded-xl text-base font-bold">
              {busy ? "Please wait…" : mode === "in" ? "Sign in" : "Continue as Rider / Driver"}
            </Button>
          </div>

          <p className="mt-4 flex items-center gap-1.5 text-xs text-muted-foreground">
            <ShieldCheck className="h-3.5 w-3.5 text-gold" />
            New crew members add their licence and vehicle for verification after sign-up.
          </p>

          <Button type="button" variant="outline" onClick={google} className="mt-4 h-12 w-full rounded-xl">Continue with Google</Button>
        </form>
      </div>
    </div>
  );
}
