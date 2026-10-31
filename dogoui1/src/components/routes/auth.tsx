import { useState } from "react";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { Bike, User, ShieldCheck } from "lucide-react";
import { AppHeader } from "@/components/dogo/AppHeader";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { useAccount, roleLabels, type Role } from "@/lib/account-store";
import { vehicles } from "@/data/dogo";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/auth")({
  head: () => ({
    meta: [
      { title: "Join DOGO Rides — Passenger or Rider" },
      {
        name: "description",
        content:
          "Join DOGO Rides as a passenger, Taxi or Tricycle driver, or Bike dispatcher.",
      },
      { property: "og:title", content: "Join DOGO Rides" },
      { property: "og:description", content: "Ride with DOGO or register as a rider." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: AuthPage,
});

const roleMeta: { id: Role; icon: typeof User; blurb: string }[] = [
  { id: "customer", icon: User, blurb: "Book a Taxi or Tricycle ride, or send a package." },
  { id: "rider", icon: Bike, blurb: "Drive and manage your trips." },
];

function AuthPage() {
  const navigate = useNavigate();
  const { signIn } = useAccount();
  const [role, setRole] = useState<Role>("customer");
  const [mode, setMode] = useState<"signin" | "register">("register");

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
   const [vehicle, setVehicle] = useState(vehicles[0]?.name ?? "");
  const [plate, setPlate] = useState("");

  const valid =
    email.includes("@") &&
    (mode === "signin" ||
      (name.trim().length > 1 &&
        phone.trim().length >= 7 &&
        (role !== "rider" || plate.trim().length > 2)));

  function submit() {
    signIn({
       name: name.trim() || email.split("@")[0] || "Rider",
      email: email.trim(),
      phone: phone.trim(),
      role,
      vehicle: role === "rider" ? vehicle : undefined,
      plate: role === "rider" ? plate.trim().toUpperCase() : undefined,
      online: false,
    });
    navigate({ to: role === "rider" ? "/rider" : "/account" });
  }

  return (
    <div className="min-h-screen bg-background">
      <AppHeader />
      <main className="mx-auto max-w-lg px-4 pb-20 pt-6">
        <h1 className="font-display text-2xl font-extrabold">Welcome to DOGO</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Choose whether you want to ride or drive.
        </p>

        <div className="mt-5 grid grid-cols-2 gap-2">
          {roleMeta.map((r) => {
            const on = role === r.id;
            return (
              <Button
                key={r.id}
                type="button"
                onClick={() => setRole(r.id)}
                className={cn(
                  "h-auto min-h-28 flex-col items-start whitespace-normal rounded-lg border p-3 text-left transition-all",
                   on ? "border-brand bg-brand/10 text-foreground shadow-[0_0_0_1px_var(--brand)]" : "border-border bg-secondary/40 text-foreground hover:bg-secondary/70",
                )}
              >
                <r.icon className={cn("h-5 w-5", on ? "text-brand" : "text-muted-foreground")} />
                <span className="mt-2 block text-sm font-bold">{roleLabels[r.id]}</span>
                <span className="mt-0.5 block text-xs text-muted-foreground">{r.blurb}</span>
              </Button>
            );
          })}
        </div>

        <div className="glass-card mt-5 rounded-3xl p-5">
          <div className="flex rounded-full border border-border bg-secondary/50 p-1">
            {(["register", "signin"] as const).map((m) => (
              <Button
                key={m}
                type="button"
                onClick={() => setMode(m)}
                className={cn(
                  "h-10 flex-1 rounded-full px-3 py-1.5 text-sm font-semibold transition-colors",
                   mode === m ? "brand-gradient text-primary-foreground" : "bg-transparent text-muted-foreground hover:text-foreground",
                )}
              >
                {m === "register" ? "Create account" : "Sign in"}
              </Button>
            ))}
          </div>

          <div className="mt-4 space-y-3">
            {mode === "register" && (
              <div className="space-y-2">
                <Label htmlFor="name">Full name</Label>
                <Input id="name" value={name} placeholder="Amaka Nwosu" onChange={(e) => setName(e.target.value.slice(0, 60))} />
              </div>
            )}
            <div className="space-y-2">
              <Label htmlFor="email">Email address</Label>
              <Input id="email" type="email" value={email} placeholder="you@example.com" onChange={(e) => setEmail(e.target.value.slice(0, 120))} />
            </div>
            {mode === "register" && (
              <div className="space-y-2">
                <Label htmlFor="phone">Phone number</Label>
                <Input id="phone" value={phone} placeholder="+234 802 000 0000" onChange={(e) => setPhone(e.target.value.slice(0, 20))} />
              </div>
            )}

            {mode === "register" && role === "rider" && (
              <>
                <div className="space-y-2">
                  <Label htmlFor="vehicle">Vehicle type</Label>
                  <select
                    id="vehicle"
                    value={vehicle}
                    onChange={(e) => setVehicle(e.target.value)}
                    className="h-10 w-full rounded-md border border-input bg-background px-3 text-sm"
                  >
                    {vehicles.map((v) => (
                      <option key={v.id} value={v.name}>
                        {v.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="plate">Plate number</Label>
                  <Input id="plate" value={plate} placeholder="LSD-284-XR" onChange={(e) => setPlate(e.target.value.slice(0, 15))} />
                </div>
              </>
            )}


            <div className="space-y-2">
              <Label htmlFor="pass">Password</Label>
              <Input id="pass" type="password" placeholder="••••••••" />
            </div>

            <Button disabled={!valid} onClick={submit} className="w-full rounded-full">
              {mode === "register" ? `Continue as ${roleLabels[role]}` : "Sign in"}
            </Button>

            <p className="flex items-start gap-2 text-xs text-muted-foreground">
              <ShieldCheck className="mt-0.5 h-3.5 w-3.5 shrink-0 text-gold" />
              Demo sign-in — your details stay on this device.
            </p>
          </div>
        </div>
      </main>
    </div>
  );
}
