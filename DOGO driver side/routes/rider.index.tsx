import { useEffect, useState } from "react";
import { Link, createFileRoute } from "@tanstack/react-router";
import {
  Armchair,
  Banknote,
  Car,
  Check,
  MapPin,
  Navigation,
  Phone,
  Search,
  ShieldCheck,
  Star,
  Users,
  X,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { RiderTabBar } from "@/components/rider/rider-tab-bar";
import { FakeMap } from "@/components/driver/fake-map";
import { naira } from "@/lib/driver-store";
import {
  PICKUP,
  PICKUP_NAME,
  destinations,
  driverPool,
  estimateFare,
  rideClasses,
  riderStore,
  useRiderStore,
  type Destination,
  type DriverMatch,
  type MapPoint,
  type RideClass,
  type RiderSession,
} from "@/lib/rider-store";

export const Route = createFileRoute("/rider/")({
  head: () => ({
    meta: [
      { title: "Bolt · Ride" },
      {
        name: "description",
        content:
          "Book a ride in seconds — a Bolt-style customer app demo with live trip updates.",
      },
      { property: "og:title", content: "Bolt · Ride" },
      {
        property: "og:description",
        content:
          "Book a ride in seconds — a Bolt-style customer app demo with live trip updates.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: RiderHome,
});

const SEARCH_SECONDS = 4;
const ARRIVE_SECONDS = 8;
const TRIP_SECONDS = 12;
const DRIVER_START: MapPoint = { x: 195, y: 388 };

const classIcons = { bolt: Car, comfort: Armchair, xl: Users } as const;

interface MapScene {
  driver?: MapPoint;
  passenger?: MapPoint;
  destination?: MapPoint;
  route?: string;
}

function sceneFor(session: RiderSession, destination: Destination, eta: number): MapScene {
  switch (session) {
    case "arriving": {
      const progress = 1 - eta / ARRIVE_SECONDS;
      return {
        driver: { x: 195, y: Math.round(388 + (516 - 388) * progress) },
        passenger: PICKUP,
        route: "M195 388 L195 516",
      };
    }
    case "onTrip":
      return { driver: PICKUP, destination: destination.point, route: destination.route };
    case "complete":
      return { passenger: destination.point, destination: destination.point };
    default:
      return { passenger: PICKUP };
  }
}

function RiderHome() {
  const { session, destinationId, rideClassId, trips } = useRiderStore();
  const destination =
    destinations.find((d) => d.id === destinationId) ?? destinations[0]!;
  const rideClass = rideClasses.find((c) => c.id === rideClassId) ?? rideClasses[0]!;
  const fare = estimateFare(destination.km, rideClass.multiplier);
  const driver = driverPool[trips.length % driverPool.length] ?? driverPool[0]!;
  const [eta, setEta] = useState(ARRIVE_SECONDS);
  const [stars, setStars] = useState(5);
  const [moving, setMoving] = useState(false);

  // Searching for nearby drivers resolves after a few seconds.
  useEffect(() => {
    if (session !== "searching") return;
    const timer = setTimeout(() => riderStore.setSession("arriving"), SEARCH_SECONDS * 1000);
    return () => clearTimeout(timer);
  }, [session]);

  // Matched driver approaches; the ETA counts down to pickup.
  useEffect(() => {
    if (session !== "arriving") return;
    setEta(ARRIVE_SECONDS);
    setMoving(false);
    const interval = setInterval(() => setEta((s) => Math.max(0, s - 1)), 1000);
    return () => clearInterval(interval);
  }, [session]);

  useEffect(() => {
    if (session === "arriving" && eta === 0) riderStore.setSession("onTrip");
  }, [session, eta]);

  // The trip auto-completes and is filed into Activity.
  useEffect(() => {
    if (session !== "onTrip") return;
    setMoving(false);
    const timer = setTimeout(() => setMoving(true), 300);
    const complete = setTimeout(() => {
      riderStore.completeTrip({
        id: `rtrip-${Date.now()}`,
        destination: destination.name,
        area: destination.area,
        rideClass: rideClass.name,
        fare,
        km: destination.km,
        minutes: destination.minutes,
        driver: driver.name,
        plate: driver.plate,
        completedAt: Date.now(),
      });
      riderStore.setSession("complete");
    }, TRIP_SECONDS * 1000);
    return () => {
      clearTimeout(timer);
      clearTimeout(complete);
    };
  }, [session, destination, rideClass, fare, driver]);

  if (session === "complete") {
    return (
      <div className="mx-auto flex h-dvh w-full max-w-[430px] flex-col overflow-hidden bg-background">
        <RideComplete
          destination={destination}
          fare={fare}
          rideClass={rideClass}
          driver={driver}
          stars={stars}
          onStars={setStars}
          onDone={() => riderStore.setSession("idle")}
        />
      </div>
    );
  }

  const scene = sceneFor(session, destination, eta);
  const busy = session !== "idle";

  return (
    <div className="relative mx-auto flex h-dvh w-full max-w-[430px] flex-col overflow-hidden bg-background">
      <FakeMap {...scene} />

      {/* Floating top bar */}
      <div className="absolute inset-x-0 top-0 z-10 flex items-center justify-between p-4">
        <div className="flex items-center gap-1.5 rounded-full bg-card px-3.5 py-2 text-sm shadow-float">
          <Banknote className="h-4 w-4 text-primary" strokeWidth={2.5} />
          <span className="font-extrabold">Cash</span>
          <span className="text-xs font-semibold text-muted-foreground">payment</span>
        </div>
        <Link
          to="/rider/account"
          aria-label="Account"
          className="flex h-10 w-10 items-center justify-center rounded-full bg-card text-sm font-extrabold text-foreground shadow-float"
        >
          AA
        </Link>
      </div>

      {/* Bottom sheet driven by the session state machine */}
      <div className={`relative z-10 mt-auto px-3 ${busy ? "pb-4" : "pb-[76px]"}`}>
        {session === "idle" && <IdleSheet onPlan={() => riderStore.setSession("picking")} />}
        {session === "picking" && (
          <PickingSheet
            onSelect={(d) => riderStore.pickDestination(d.id)}
            onClose={() => riderStore.setSession("idle")}
          />
        )}
        {session === "confirm" && (
          <ConfirmSheet
            destination={destination}
            rideClass={rideClass}
            onChoose={riderStore.setRideClass}
            onBack={() => riderStore.setSession("picking")}
            onRequest={() => riderStore.setSession("searching")}
          />
        )}
        {session === "searching" && (
          <SearchingSheet
            destination={destination}
            fare={fare}
            onCancel={() => riderStore.setSession("idle")}
          />
        )}
        {session === "arriving" && (
          <ArrivingSheet driver={driver} rideClass={rideClass} eta={eta} onCancel={() => riderStore.setSession("idle")} />
        )}
        {session === "onTrip" && (
          <OnTripSheet
            destination={destination}
            fare={fare}
            rideClass={rideClass}
            moving={moving}
          />
        )}
      </div>

      {!busy && <RiderTabBar />}
    </div>
  );
}

function IdleSheet({ onPlan }: { onPlan: () => void }) {
  return (
    <div className="rounded-t-3xl bg-card px-5 pb-6 pt-5 shadow-sheet">
      <div className="flex items-center gap-3 rounded-2xl bg-muted px-4 py-3">
        <MapPin className="h-4 w-4 shrink-0 fill-primary text-primary" />
        <p className="truncate text-sm font-bold">{PICKUP_NAME}</p>
      </div>
      <button
        type="button"
        onClick={onPlan}
        className="mt-3 flex w-full items-center gap-3 rounded-2xl bg-muted px-4 py-4 text-left transition-colors hover:bg-accent"
      >
        <Search className="h-5 w-5 text-muted-foreground" />
        <span className="flex-1 text-base font-extrabold text-muted-foreground">Where to?</span>
      </button>
      <div className="mt-4 flex items-center justify-between rounded-2xl bg-muted px-4 py-3">
        <span className="text-xs font-semibold text-muted-foreground">Paying with</span>
        <span className="flex items-center gap-1.5 text-sm font-bold">
          <Banknote className="h-4 w-4 text-primary" /> Cash
        </span>
      </div>
    </div>
  );
}

function PickingSheet({
  onSelect,
  onClose,
}: {
  onSelect: (destination: Destination) => void;
  onClose: () => void;
}) {
  return (
    <div className="rounded-t-3xl bg-card px-5 pb-6 pt-4 shadow-sheet">
      <div className="flex items-center gap-3">
        <button
          type="button"
          aria-label="Back"
          onClick={onClose}
          className="flex h-9 w-9 items-center justify-center rounded-full bg-muted text-foreground transition-colors hover:bg-accent"
        >
          <X className="h-4.5 w-4.5" />
        </button>
        <p className="flex-1 text-base font-extrabold">Plan your ride</p>
      </div>
      <div className="mt-3 flex items-center gap-3 rounded-2xl bg-muted px-4 py-3">
        <MapPin className="h-4 w-4 shrink-0 fill-primary text-primary" />
        <p className="truncate text-sm font-bold">{PICKUP_NAME}</p>
      </div>
      <ul>
        {destinations.map((d) => (
          <li key={d.id}>
            <button
              type="button"
              onClick={() => onSelect(d)}
              className="flex w-full items-center gap-3 px-1 py-3 text-left transition-colors hover:bg-accent [&:not(:last-child)]:border-b [&:not(:last-child)]:border-border"
            >
              <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-secondary">
                <Navigation className="h-4 w-4 rotate-45 text-muted-foreground" />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block truncate text-sm font-bold">{d.name}</span>
                <span className="block truncate text-xs text-muted-foreground">{d.area}</span>
              </span>
              <span className="shrink-0 text-xs font-semibold text-muted-foreground">
                {d.km} km
              </span>
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}

function ConfirmSheet({
  destination,
  rideClass,
  onChoose,
  onBack,
  onRequest,
}: {
  destination: Destination;
  rideClass: RideClass;
  onChoose: (id: RideClass["id"]) => void;
  onBack: () => void;
  onRequest: () => void;
}) {
  return (
    <div className="rounded-t-3xl bg-card px-5 pb-6 pt-4 shadow-sheet">
      <div className="flex items-center gap-3">
        <button
          type="button"
          aria-label="Back"
          onClick={onBack}
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-muted text-foreground transition-colors hover:bg-accent"
        >
          <X className="h-4.5 w-4.5" />
        </button>
        <div className="min-w-0 flex-1">
          <p className="truncate text-base font-extrabold leading-6">{destination.name}</p>
          <p className="truncate text-xs text-muted-foreground">
            {destination.km} km · ~{destination.minutes} min
          </p>
        </div>
      </div>

      <div className="mt-3 space-y-2">
        {rideClasses.map((c) => {
          const Icon = classIcons[c.id];
          const active = c.id === rideClass.id;
          return (
            <button
              key={c.id}
              type="button"
              onClick={() => onChoose(c.id)}
              className={`flex w-full items-center gap-3 rounded-2xl border px-4 py-3 text-left transition-colors ${
                active ? "border-primary bg-primary/10" : "border-border hover:bg-accent"
              }`}
            >
              <Icon className={`h-5 w-5 shrink-0 ${active ? "text-primary" : "text-muted-foreground"}`} />
              <span className="min-w-0 flex-1">
                <span className="block text-sm font-extrabold">{c.name}</span>
                <span className="block truncate text-xs text-muted-foreground">{c.tagline}</span>
              </span>
              <span className="shrink-0 text-right">
                <span className={`block text-sm font-extrabold ${active ? "text-primary" : ""}`}>
                  {naira(estimateFare(destination.km, c.multiplier))}
                </span>
                <span className="block text-xs text-muted-foreground">{c.etaMinutes} min away</span>
              </span>
            </button>
          );
        })}
      </div>

      <div className="mt-3 flex items-center justify-between rounded-2xl bg-muted px-4 py-3">
        <span className="text-xs font-semibold text-muted-foreground">Paying with</span>
        <span className="flex items-center gap-1.5 text-sm font-bold">
          <Banknote className="h-4 w-4 text-primary" /> Cash
        </span>
      </div>

      <Button size="lg" className="mt-3 w-full text-base font-extrabold" onClick={onRequest}>
        Request {rideClass.name}
      </Button>
    </div>
  );
}

function SearchingSheet({
  destination,
  fare,
  onCancel,
}: {
  destination: Destination;
  fare: number;
  onCancel: () => void;
}) {
  return (
    <div className="rounded-t-3xl bg-card px-5 pb-6 pt-6 shadow-sheet">
      <div className="flex flex-col items-center text-center">
        <span className="relative flex h-12 w-12">
          <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-primary opacity-50" />
          <span className="relative flex h-12 w-12 items-center justify-center rounded-full bg-primary/15">
            <Search className="h-5 w-5 text-primary" />
          </span>
        </span>
        <p className="mt-3 text-base font-extrabold">Finding your driver…</p>
        <p className="mt-1 text-sm text-muted-foreground">
          {destination.name} · {naira(fare)}
        </p>
      </div>
      <button
        type="button"
        onClick={onCancel}
        className="mt-4 w-full text-center text-sm font-semibold text-muted-foreground"
      >
        Cancel
      </button>
    </div>
  );
}

function ArrivingSheet({
  driver,
  rideClass,
  eta,
  onCancel,
}: {
  driver: DriverMatch;
  rideClass: RideClass;
  eta: number;
  onCancel: () => void;
}) {
  return (
    <div className="rounded-t-3xl bg-card px-5 pb-6 pt-5 shadow-sheet">
      <p className="text-xs font-extrabold uppercase tracking-wide text-muted-foreground">
        Your {rideClass.name} is {eta > 0 ? `${eta} min away` : "arriving now"}
      </p>
      <div className="mt-2 flex items-center gap-3">
        <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-secondary text-sm font-extrabold">
          {driver.initials}
        </span>
        <div className="min-w-0 flex-1">
          <p className="truncate text-base font-extrabold">{driver.name}</p>
          <p className="flex items-center gap-1 text-xs font-semibold text-muted-foreground">
            <Star className="h-3.5 w-3.5 fill-primary text-primary" />
            {driver.rating}
          </p>
        </div>
        <ShieldCheck className="h-5 w-5 shrink-0 text-primary" />
      </div>
      <div className="mt-3 flex items-center justify-between rounded-2xl bg-muted px-4 py-3">
        <p className="text-sm font-extrabold tracking-wider">{driver.plate}</p>
        <p className="text-xs font-semibold text-muted-foreground">{driver.car}</p>
      </div>
      <div className="mt-3 flex gap-3">
        <Button variant="outline" size="lg" className="flex-1 font-bold">
          <Phone className="h-5 w-5" /> Contact
        </Button>
        <Button variant="outline" size="lg" className="flex-1 font-bold" onClick={onCancel}>
          Cancel ride
        </Button>
      </div>
    </div>
  );
}

function OnTripSheet({
  destination,
  fare,
  rideClass,
  moving,
}: {
  destination: Destination;
  fare: number;
  rideClass: RideClass;
  moving: boolean;
}) {
  return (
    <div className="rounded-t-3xl bg-card px-5 pb-6 pt-5 shadow-sheet">
      <p className="text-xs font-extrabold uppercase tracking-wide text-muted-foreground">
        In trip · {rideClass.name}
      </p>
      <div className="mt-2 flex items-start justify-between gap-3">
        <p className="flex items-start gap-2 text-base font-extrabold leading-6">
          <MapPin className="mt-1 h-4 w-4 shrink-0 fill-primary text-primary" />
          {destination.name}
        </p>
        <div className="shrink-0 text-right">
          <p className="text-sm font-extrabold text-primary">{naira(fare)}</p>
          <p className="text-xs font-semibold text-muted-foreground">
            ~{destination.minutes} min
          </p>
        </div>
      </div>
      <div className="mt-4 h-1.5 rounded-full bg-muted">
        <div
          className="h-full rounded-full bg-primary transition-all ease-linear"
          style={{ width: moving ? "82%" : "6%", transitionDuration: `${TRIP_SECONDS * 1000}ms` }}
        />
      </div>
      <p className="mt-3 text-center text-xs text-muted-foreground">
        Sit back — you'll be notified on arrival.
      </p>
    </div>
  );
}

function RideComplete({
  destination,
  fare,
  rideClass,
  driver,
  stars,
  onStars,
  onDone,
}: {
  destination: Destination;
  fare: number;
  rideClass: RideClass;
  driver: DriverMatch;
  stars: number;
  onStars: (n: number) => void;
  onDone: () => void;
}) {
  return (
    <div className="flex h-full flex-col px-5 pb-6 pt-10">
      <div className="flex flex-1 flex-col items-center justify-center text-center">
        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary">
          <Check className="h-8 w-8 text-primary-foreground" strokeWidth={3} />
        </div>
        <h1 className="mt-5 text-2xl font-extrabold">You've arrived!</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {driver.name} dropped you at {destination.name}.
        </p>
        <p className="mt-5 text-4xl font-extrabold text-primary">{naira(fare)}</p>
        <p className="text-xs font-semibold text-muted-foreground">Paid in cash</p>

        <div className="mt-6 w-full rounded-2xl bg-muted px-4 py-3 text-left text-sm">
          <div className="flex justify-between py-0.5">
            <span className="text-muted-foreground">Ride class</span>
            <span className="font-bold">{rideClass.name}</span>
          </div>
          <div className="flex justify-between py-0.5">
            <span className="text-muted-foreground">Distance</span>
            <span className="font-bold">
              {destination.km} km · {destination.minutes} min
            </span>
          </div>
          <div className="flex justify-between border-t border-border py-0.5 pt-2">
            <span className="text-muted-foreground">Driver</span>
            <span className="font-bold">
              {driver.name} · {driver.plate}
            </span>
          </div>
        </div>

        <p className="mt-6 text-sm font-bold">Rate {driver.name}</p>
        <div className="mt-2 flex gap-2">
          {[1, 2, 3, 4, 5].map((n) => (
            <button
              key={n}
              type="button"
              aria-label={`${n} star${n > 1 ? "s" : ""}`}
              onClick={() => onStars(n)}
            >
              <Star
                className={`h-8 w-8 transition-colors ${
                  n <= stars ? "fill-primary text-primary" : "text-muted-foreground/40"
                }`}
              />
            </button>
          ))}
        </div>
      </div>
      <Button size="lg" className="text-base font-extrabold" onClick={onDone}>
        Done
      </Button>
    </div>
  );
}
