import { useState } from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { Car, Package, LifeBuoy, Route as RouteIcon, ArrowRight } from "lucide-react";
import { AppHeader } from "@/components/dogo/AppHeader";
import { DogoMap } from "@/components/dogo/DogoMap";
import { BookingDialog } from "@/components/dogo/BookingDialog";
import { naira } from "@/data/dogo";
import { useShipments } from "@/lib/shipment-store";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "DOGO Rides — Taxi rides, Keke and bike dispatch" },
      {
        name: "description",
        content:
          "Book a Taxi or Tricycle ride, or send a package by bike, across Nigeria with DOGO.",
      },
      { property: "og:title", content: "DOGO Rides — Taxi rides, Keke and bike dispatch" },
      {
        property: "og:description",
        content: "Book a Taxi or Keke ride, or send a package by bike.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: Home,
});

function Home() {
  const [booking, setBooking] = useState(false);
  const [sending, setSending] = useState(false);
  const { shipments } = useShipments();
  const active = shipments.filter((s) => s.service === "ride" || s.service === "courier").slice(0, 3);

  return (
    <div className="min-h-screen bg-background">
      <AppHeader />

      <main className="relative mx-auto max-w-6xl px-4 pb-16 pt-4">
        <section className="relative overflow-hidden rounded-[2rem] border border-border">
          <DogoMap className="h-[300px] w-full sm:h-[420px]" />
          <div className="pointer-events-none absolute inset-0 bg-linear-to-t from-background via-background/40 to-transparent" />
          <div className="absolute inset-x-0 top-0 p-4 sm:p-6">
            <h1 className="max-w-md font-display text-2xl font-extrabold leading-tight sm:text-4xl">
              DOGO Rides
            </h1>
            <p className="mt-1.5 max-w-sm text-sm text-muted-foreground sm:text-base">
              Your next ride is a few taps away.
            </p>
          </div>
        </section>

        <div className="relative -mt-16 space-y-4 sm:-mt-20">
          <div className="glass-card rounded-lg p-5 sm:p-7">
            <h2 className="font-display text-xl font-bold">Where are you going?</h2>
            <p className="mt-1 text-sm text-muted-foreground">Ride in a Taxi or Keke, or send a package by bike. See your price first.</p>
            <Button type="button" onClick={() => setBooking(true)} className="mt-5 h-16 w-full justify-between rounded-lg brand-gradient px-5 text-base font-bold text-primary-foreground">
              <span className="flex items-center gap-3"><Car className="h-6 w-6" /> Book a ride</span><ArrowRight className="h-5 w-5" />
            </Button>
            <Button type="button" onClick={() => setSending(true)} variant="outline" className="mt-3 h-14 w-full justify-between rounded-lg border-gold/50 bg-gold/10 px-5 text-base font-bold">
              <span className="flex items-center gap-3"><Package className="h-6 w-6 text-gold" /> Send a package</span><ArrowRight className="h-5 w-5" />
            </Button>
            <Button asChild variant="outline" className="mt-3 h-12 w-full justify-start rounded-lg border-border bg-secondary/40 px-4 text-sm font-semibold">
              <Link to="/help"><LifeBuoy className="h-5 w-5 text-brand-soft" /> Help & support <ArrowRight className="ml-auto h-4 w-4" /></Link>
            </Button>
            <Button asChild variant="outline" className="mt-3 h-12 w-full justify-start rounded-lg border-border bg-secondary/40 px-4 text-sm font-semibold">
              <Link to="/track"><RouteIcon className="h-5 w-5 text-gold" /> My rides <ArrowRight className="ml-auto h-4 w-4" /></Link>
            </Button>
          </div>

          <section className="mt-7">
            <div className="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-3">
              <h2 className="truncate text-lg font-bold">Recent rides</h2>
              <Link to="/track" className="shrink-0 text-sm font-semibold text-brand-soft">
                View all
              </Link>
            </div>
            <div className="mt-3 space-y-2.5">
              {active.length === 0 && <p className="py-4 text-sm text-muted-foreground">Your rides will appear here after you book.</p>}
              {active.map((s) => (
                <Link
                  key={s.code}
                  to="/track/$code"
                  params={{ code: s.code }}
                  className="grid grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-3 rounded-lg border border-border bg-secondary/40 p-3 transition-colors hover:bg-secondary/70"
                >
                  <span className="relative grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-brand/15">
                    {s.service === "courier" ? <Package className="h-5 w-5 text-brand-soft" /> : <Car className="h-5 w-5 text-brand-soft" />}
                    <span className="absolute -right-0.5 -top-0.5 h-2.5 w-2.5 rounded-full bg-success animate-ping-soft" />
                  </span>
                  <span className="min-w-0">
                    <span className="block truncate font-semibold">{s.code}</span>
                    <span className="block truncate text-xs text-muted-foreground">
                      {s.pickup} → {s.dropoff}
                    </span>
                  </span>
                  <span className="shrink-0 text-right text-sm font-semibold tabular-nums">{naira(s.price)}</span>
                </Link>
              ))}
            </div>
          </section>
        </div>
      </main>

      <BookingDialog open={booking} onOpenChange={setBooking} />
      <BookingDialog open={sending} onOpenChange={setSending} service="dispatch" />
    </div>
  );
}
