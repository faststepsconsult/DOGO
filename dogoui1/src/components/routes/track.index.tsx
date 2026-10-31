import { createFileRoute, Link } from "@tanstack/react-router";
import { Bike } from "lucide-react";
import { AppHeader } from "@/components/dogo/AppHeader";
import { naira } from "@/data/dogo";
import { useShipments } from "@/lib/shipment-store";

export const Route = createFileRoute("/track/")({
  head: () => ({
    meta: [
      { title: "My rides — DOGO Rides" },
      {
        name: "description",
        content: "See your DOGO rides, trip status, driver details and receipts.",
      },
      { property: "og:title", content: "My rides — DOGO Rides" },
      { property: "og:description", content: "Follow your DOGO rides and see your trip receipts." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: TrackList,
});

function TrackList() {
  const { shipments } = useShipments();
  const rides = shipments.filter((s) => s.service === "ride");

  return (
    <div className="min-h-screen bg-background">
      <AppHeader />
      <main className="mx-auto max-w-3xl px-4 pb-16 pt-6">
        <h1 className="font-display text-2xl font-extrabold">Your trips</h1>
        <p className="mt-1 text-sm text-muted-foreground">Choose a trip to see where it is.</p>
        <div className="mt-4 space-y-2.5">
          {rides.length === 0 && <p className="text-sm text-muted-foreground">No rides yet. Book your first ride from Home.</p>}
          {rides.map((s) => (
            <Link
              key={s.code}
              to="/track/$code"
              params={{ code: s.code }}
              className="glass-card grid grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-3 rounded-2xl p-3.5 transition-transform hover:-translate-y-0.5"
            >
              <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-brand/15">
                <Bike className="h-5 w-5 text-brand-soft" />
              </span>
              <span className="min-w-0">
                <span className="block truncate font-semibold">{s.code}</span>
                <span className="block truncate text-xs text-muted-foreground">
                  {s.pickup} → {s.dropoff}
                </span>
              </span>
              <span className="shrink-0 text-sm font-semibold tabular-nums">{naira(s.price)}</span>
            </Link>
          ))}
        </div>
      </main>
    </div>
  );
}
