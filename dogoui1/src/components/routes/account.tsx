import { createFileRoute, Link } from "@tanstack/react-router";
import { ArrowRight, BadgeCheck, Bike, LogOut, ShieldAlert, Wallet } from "lucide-react";
import { AppHeader } from "@/components/dogo/AppHeader";
import { Button } from "@/components/ui/button";
import { useAccount, roleLabels } from "@/lib/account-store";
import { useShipments } from "@/lib/shipment-store";
import { naira, vehicleIdFromName, vehicleLabel } from "@/data/dogo";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/account")({
  head: () => ({
    meta: [
      { title: "Your profile — DOGO Rides" },
      {
        name: "description",
        content: "See your DOGO ride history or manage your rider status.",
      },
      { property: "og:title", content: "Your DOGO profile" },
      { property: "og:description", content: "Your rides and rider account in one place." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: AccountPage,
});

function AccountPage() {
  const { account, signOut, update } = useAccount();
  const { shipments } = useShipments();

  if (!account) {
    return (
      <div className="min-h-screen bg-background">
        <AppHeader />
        <main className="mx-auto max-w-md px-4 pb-20 pt-16 text-center">
          <h1 className="font-display text-2xl font-extrabold">You're not signed in</h1>
          <p className="mt-2 text-sm text-muted-foreground">
             Sign in as a passenger or rider to see your account.
          </p>
          <Link
            to="/auth"
            className="mt-5 inline-flex rounded-full brand-gradient px-5 py-2.5 font-bold text-primary-foreground"
          >
            Sign in or register
          </Link>
        </main>
      </div>
    );
  }

  const verifiedCount = Object.values(account.verification).filter((v) => v === "verified").length;

  return (
    <div className="min-h-screen bg-background">
      <AppHeader />
      <main className="mx-auto max-w-3xl px-4 pb-20 pt-6">
        <div className="glass-card grid grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-3 rounded-3xl p-5">
          <span className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl brand-gradient text-lg font-extrabold text-primary-foreground">
            {account.name.slice(0, 2).toUpperCase()}
          </span>
          <div className="min-w-0">
            <h1 className="truncate font-display text-xl font-extrabold">{account.name}</h1>
            <p className="truncate text-xs text-muted-foreground">
              {roleLabels[account.role]} • {account.email}
            </p>
          </div>
          <Button variant="secondary" size="sm" className="shrink-0 rounded-full" onClick={signOut}>
            <LogOut className="mr-1.5 h-4 w-4" /> Sign out
          </Button>
        </div>

        <Link
          to="/verify"
          className="glass-card mt-3 flex items-center justify-between gap-3 rounded-3xl p-4"
        >
          <span className="flex min-w-0 items-center gap-2">
            {verifiedCount > 0 ? (
              <BadgeCheck className="h-5 w-5 shrink-0 text-brand" />
            ) : (
              <ShieldAlert className="h-5 w-5 shrink-0 text-gold" />
            )}
            <span className="min-w-0">
              <span className="block truncate text-sm font-bold">Verification status</span>
              <span className="block truncate text-xs text-muted-foreground">
                 {verifiedCount} checks complete
              </span>
            </span>
          </span>
          <span className="shrink-0 text-sm font-semibold text-brand">Open</span>
        </Link>

        {account.role === "customer" && (
          <section className="mt-6">
             <h2 className="font-display text-lg font-bold">Ride history</h2>
            <div className="mt-3 space-y-2">
               {shipments.filter((s) => s.service === "ride").map((s) => (
                <Link
                  key={s.code}
                  to="/track/$code"
                  params={{ code: s.code }}
                  className="glass-card grid grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-3 rounded-2xl p-3"
                >
                   <Bike className="h-5 w-5 shrink-0 text-brand" />
                  <span className="min-w-0">
                    <span className="block truncate text-sm font-semibold">
                      {s.pickup} → {s.dropoff}
                    </span>
                    <span className="block truncate text-xs text-muted-foreground">
                       {s.code} • {vehicleLabel(s.vehicleId)}
                    </span>
                  </span>
                  <span className="shrink-0 font-semibold tabular-nums">{naira(s.price)}</span>
                </Link>
              ))}
            </div>
            <div className="glass-card mt-3 flex items-center justify-between rounded-2xl p-4">
              <span className="flex items-center gap-2 text-sm font-semibold">
                <Wallet className="h-4 w-4 text-gold" /> DOGO Wallet
              </span>
              <span className="font-display text-lg font-extrabold tabular-nums">₦184,500</span>
            </div>
          </section>
        )}

        {account.role === "rider" && (
          <section className="mt-6 space-y-3">
            <Button asChild className="h-14 w-full justify-between rounded-lg px-5 text-base font-bold">
              <Link to="/rider"><span className="flex items-center gap-2"><Bike className="h-5 w-5" /> Open rider dashboard</span><ArrowRight className="h-5 w-5" /></Link>
            </Button>
            <div className="glass-card flex items-center justify-between gap-3 rounded-3xl p-5">
              <div className="min-w-0">
                <p className="text-sm font-bold">{account.online ? "You're online" : "You're offline"}</p>
                <p className="text-xs text-muted-foreground">
                   {account.online ? "Ready for ride requests" : "Go online to start receiving rides"}
                </p>
              </div>
               <Button
                type="button"
                role="switch"
                aria-checked={!!account.online}
                aria-label="Toggle online status"
                onClick={() => update({ online: !account.online })}
                className={cn(
                   "relative h-8 w-14 shrink-0 rounded-full p-0 transition-colors",
                  account.online ? "brand-gradient" : "bg-secondary",
                )}
              >
                <span
                  className={cn(
                    "absolute top-1 h-6 w-6 rounded-full bg-background transition-all",
                    account.online ? "left-7" : "left-1",
                  )}
                />
               </Button>
            </div>

            <div className="glass-card rounded-3xl p-5">
              <p className="flex items-center gap-2 text-sm font-bold">
                <Bike className="h-4 w-4 text-brand" /> Vehicle details
              </p>
              <dl className="mt-3 grid grid-cols-2 gap-3 text-sm">
                <div>
                  <dt className="text-xs text-muted-foreground">Vehicle</dt>
                   <dd className="font-semibold">{account.vehicle ? vehicleLabel(vehicleIdFromName(account.vehicle)) : "—"}</dd>
                </div>
                <div>
                  <dt className="text-xs text-muted-foreground">Plate</dt>
                  <dd className="font-semibold">{account.plate ?? "—"}</dd>
                </div>
                <div>
                  <dt className="text-xs text-muted-foreground">KYV status</dt>
                  <dd className="font-semibold capitalize">{account.verification.kyv}</dd>
                </div>
                <div>
                  <dt className="text-xs text-muted-foreground">KYW status</dt>
                  <dd className="font-semibold capitalize">{account.verification.kyw}</dd>
                </div>
              </dl>
            </div>

          </section>
        )}

      </main>
    </div>
  );
}
