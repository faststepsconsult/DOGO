import { createFileRoute, Link } from "@tanstack/react-router";
import { BadgeCheck, CalendarDays, Route as RouteIcon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { DriverTabBar } from "@/components/driver/driver-tab-bar";
import {
  COMMISSION,
  clockTime,
  naira,
  todaysPayouts,
  useDriverStore,
} from "@/lib/driver-store";

export const Route = createFileRoute("/earnings")({
  head: () => ({
    meta: [
      { title: "Bolt Driver · Earnings" },
      {
        name: "description",
        content: "Track your daily and weekly driver earnings in the demo app.",
      },
      { property: "og:title", content: "Bolt Driver · Earnings" },
      {
        property: "og:description",
        content: "Track your daily and weekly driver earnings in the demo app.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: EarningsPage,
});

const DAY_LABELS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] as const;

function EarningsPage() {
  const { trips } = useDriverStore();
  const today = todaysPayouts(trips);
  const todayIdx = (new Date().getDay() + 6) % 7; // Monday-first index
  const todayBar = Math.max(6, Math.min(100, (today / 10000) * 100));

  return (
    <div className="mx-auto flex h-dvh w-full max-w-[430px] flex-col overflow-hidden bg-background">
      <header className="px-5 pb-4 pt-7">
        <h1 className="text-2xl font-extrabold">Earnings</h1>
        <p className="text-sm text-muted-foreground">
          Today,{" "}
          {new Date().toLocaleDateString("en-NG", {
            weekday: "long",
            day: "numeric",
            month: "long",
          })}
        </p>
      </header>

      <div className="flex-1 space-y-4 overflow-y-auto px-5 pb-24">
        <div className="rounded-3xl bg-primary p-5 text-primary-foreground shadow-float">
          <p className="text-sm font-semibold opacity-90">Earned today</p>
          <p className="mt-1 text-4xl font-extrabold">{naira(today)}</p>
          <div className="mt-4 grid grid-cols-3 gap-2 text-center">
            <div className="rounded-2xl bg-primary-foreground/15 py-2.5">
              <p className="text-lg font-extrabold">{trips.length}</p>
              <p className="text-[11px] font-semibold opacity-90">Trips</p>
            </div>
            <div className="rounded-2xl bg-primary-foreground/15 py-2.5">
              <p className="text-lg font-extrabold">
                {trips.length ? naira(Math.round(today / trips.length)) : "—"}
              </p>
              <p className="text-[11px] font-semibold opacity-90">Avg / trip</p>
            </div>
            <div className="rounded-2xl bg-primary-foreground/15 py-2.5">
              <p className="text-lg font-extrabold">{DRIVER_SHARE}%</p>
              <p className="text-[11px] font-semibold opacity-90">Your share</p>
            </div>
          </div>
        </div>

        <div className="rounded-3xl border border-border bg-card p-5">
          <div className="flex items-center justify-between">
            <h2 className="font-extrabold">This week</h2>
            <span className="flex items-center gap-1 text-xs font-semibold text-muted-foreground">
              <CalendarDays className="h-4 w-4" /> Mon – Sun
            </span>
          </div>
          <div className="mt-5 flex items-end justify-between gap-2">
            {DAY_LABELS.map((label, i) => (
              <div key={label} className="flex flex-1 flex-col items-center gap-1.5">
                <div className="flex h-20 w-full items-end">
                  <div
                    className={`w-full rounded-lg ${i === todayIdx ? "bg-primary" : "bg-muted"}`}
                    style={{ height: i === todayIdx ? `${todayBar}%` : "5%" }}
                  />
                </div>
                <span
                  className={`text-[10px] font-bold ${
                    i === todayIdx ? "text-foreground" : "text-muted-foreground"
                  }`}
                >
                  {label}
                </span>
              </div>
            ))}
          </div>
        </div>

        <div className="flex items-center gap-3 rounded-3xl bg-primary/10 p-4">
          <BadgeCheck className="h-6 w-6 shrink-0 text-primary" />
          <p className="text-[13px] font-semibold">
            Starter plan — you keep {DRIVER_SHARE}% of every fare. Higher shares unlock as you
            complete more trips.
          </p>
        </div>

        <h2 className="pt-2 font-extrabold">Recent trips</h2>
        {trips.length === 0 ? (
          <div className="rounded-3xl border border-dashed border-border bg-card p-6 text-center">
            <p className="font-bold">No trips yet</p>
            <p className="mt-1 text-sm text-muted-foreground">
              Go online and your completed trips will appear here.
            </p>
            <Button asChild className="mt-4 font-extrabold">
              <Link to="/">Go online</Link>
            </Button>
          </div>
        ) : (
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
                  <p className="truncate text-sm font-bold">{trip.dropoffName}</p>
                  <p className="truncate text-xs text-muted-foreground">
                    from {trip.pickupName} · {clockTime(trip.completedAt)}
                  </p>
                </div>
                <p className="shrink-0 text-sm font-extrabold text-primary">
                  {naira(trip.fare)}
                </p>
              </li>
            ))}
          </ul>
        )}
      </div>

      <DriverTabBar />
    </div>
  );
}

const DRIVER_SHARE = Math.round((1 - COMMISSION) * 100);
