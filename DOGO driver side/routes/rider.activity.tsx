import { Link, createFileRoute } from "@tanstack/react-router";
import { Clock, Route as RouteIcon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { RiderTabBar } from "@/components/rider/rider-tab-bar";
import { naira } from "@/lib/driver-store";
import { useRiderStore } from "@/lib/rider-store";

export const Route = createFileRoute("/rider/activity")({
  head: () => ({
    meta: [
      { title: "Bolt · Activity" },
      {
        name: "description",
        content: "Your past rides, fares and drivers in the Bolt customer app demo.",
      },
      { property: "og:title", content: "Bolt · Activity" },
      {
        property: "og:description",
        content: "Your past rides, fares and drivers in the Bolt customer app demo.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: RiderActivity,
});

function RiderActivity() {
  const { trips } = useRiderStore();

  return (
    <div className="mx-auto flex h-dvh w-full max-w-[430px] flex-col overflow-hidden bg-background">
      <header className="px-5 pb-4 pt-7">
        <h1 className="text-2xl font-extrabold">Activity</h1>
        <p className="text-sm text-muted-foreground">Your rides at a glance</p>
      </header>

      <div className="flex-1 space-y-4 overflow-y-auto px-5 pb-24">
        {trips.length === 0 ? (
          <div className="rounded-3xl border border-dashed border-border bg-card p-6 text-center">
            <p className="font-bold">No rides yet</p>
            <p className="mt-1 text-sm text-muted-foreground">
              Book your first ride and it will show up here.
            </p>
            <Button asChild className="mt-4 font-extrabold">
              <Link to="/rider">Book a ride</Link>
            </Button>
          </div>
        ) : (
          <>
            <div className="flex items-center gap-3 rounded-3xl bg-primary/10 p-4">
              <Clock className="h-6 w-6 shrink-0 text-primary" />
              <p className="text-[13px] font-semibold">
                {trips.length} ride{trips.length > 1 ? "s" : ""} completed in this demo.
              </p>
            </div>
            <ul className="space-y-2.5">
              {trips.map((trip) => (
                <li
                  key={trip.id}
                  className="flex items-center gap-3 rounded-2xl border border-border bg-card px-4 py-3"
                >
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-secondary">
                    <RouteIcon className="h-5 w-5 text-muted-foreground" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-bold">{trip.destination}</p>
                    <p className="truncate text-xs text-muted-foreground">
                      {trip.rideClass} · {trip.driver} ·{" "}
                      {new Date(trip.completedAt).toLocaleTimeString("en-NG", {
                        hour: "2-digit",
                        minute: "2-digit",
                      })}
                    </p>
                  </div>
                  <p className="shrink-0 text-sm font-extrabold text-primary">
                    {naira(trip.fare)}
                  </p>
                </li>
              ))}
            </ul>
          </>
        )}
      </div>

      <RiderTabBar />
    </div>
  );
}
