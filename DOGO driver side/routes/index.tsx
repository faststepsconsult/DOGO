import { useEffect, useRef, useState } from "react";
import { Link, createFileRoute } from "@tanstack/react-router";
import {
  BadgeCheck,
  Banknote,
  Check,
  Menu,
  Navigation,
  Star,
  UserRound,
  X,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { DriverTabBar } from "@/components/driver/driver-tab-bar";
import { FakeMap } from "@/components/driver/fake-map";
import {
  COMMISSION,
  driverStore,
  naira,
  rideRequests,
  todaysPayouts,
  useDriverStore,
  type CompletedTrip,
  type MapPoint,
  type RideRequest,
  type Session,
} from "@/lib/driver-store";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Bolt Driver · Home" },
      {
        name: "description",
        content:
          "Go online, receive ride requests and complete trips — a Bolt-style driver app demo.",
      },
      { property: "og:title", content: "Bolt Driver · Home" },
      {
        property: "og:description",
        content:
          "Go online, receive ride requests and complete trips — a Bolt-style driver app demo.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: DriverHome,
});

const REQUEST_SECONDS = 15;
const HOME: MapPoint = { x: 195, y: 388 };
const DRIVER_SHARE = Math.round((1 - COMMISSION) * 100);

interface MapScene {
  driver?: MapPoint;
  passenger?: MapPoint;
  destination?: MapPoint;
  route?: string;
}

function mapScene(session: Session, request: RideRequest): MapScene {
  switch (session) {
    case "request":
    case "toPickup":
      return {
        driver: HOME,
        passenger: request.pickup,
        destination: request.destination,
        route: request.routeToPickup,
      };
    case "atPickup":
      return {
        driver: { x: request.pickup.x + 8, y: request.pickup.y + 4 },
        passenger: request.pickup,
        destination: request.destination,
      };
    case "onTrip":
      return {
        driver: request.pickup,
        destination: request.destination,
        route: request.routeTrip,
      };
    case "complete":
      return { driver: request.destination, destination: request.destination };
    default:
      return { driver: HOME };
  }
}

function DriverHome() {
  const { session, trips } = useDriverStore();
  const request = rideRequests[trips.length % rideRequests.length] ?? rideRequests[0]!;
  const [secondsLeft, setSecondsLeft] = useState(REQUEST_SECONDS);
  const [waitSeconds, setWaitSeconds] = useState(0);
  const [stars, setStars] = useState(5);
  const activeRef = useRef<RideRequest>(request);

  const busy = session !== "offline" && session !== "online";
  const active = activeRef.current;
  const today = todaysPayouts(trips);

  // A new ride request arrives a few seconds after going online.
  useEffect(() => {
    if (session !== "online") return;
    const timer = setTimeout(() => driverStore.setSession("request"), 5000);
    return () => clearTimeout(timer);
  }, [session]);

  // Unanswered requests expire and the search resumes.
  useEffect(() => {
    if (session !== "request") return;
    setSecondsLeft(REQUEST_SECONDS);
    const interval = setInterval(
      () => setSecondsLeft((s) => Math.max(0, s - 1)),
      1000,
    );
    return () => clearInterval(interval);
  }, [session]);

  useEffect(() => {
    if (session === "request" && secondsLeft === 0) {
      driverStore.setSession("online");
    }
  }, [session, secondsLeft]);

  // Waiting-for-passenger stopwatch.
  useEffect(() => {
    if (session !== "atPickup") return;
    setWaitSeconds(0);
    const interval = setInterval(() => setWaitSeconds((s) => s + 1), 1000);
    return () => clearInterval(interval);
  }, [session]);

  const accept = () => {
    activeRef.current = request;
    driverStore.setSession("toPickup");
  };

  const finishTrip = () => {
    const r = activeRef.current;
    const trip: CompletedTrip = {
      id: `trip-${Date.now()}`,
      passenger: r.passenger,
      pickupName: r.pickupName,
      dropoffName: r.dropoffName,
      fare: Math.round(r.fare * (1 - COMMISSION)),
      distanceKm: r.distanceKm,
      minutes: r.minutes,
      payment: r.payment,
      completedAt: Date.now(),
    };
    driverStore.completeTrip(trip);
    driverStore.setSession("complete");
  };

  if (session === "complete") {
    const payout = Math.round(active.fare * (1 - COMMISSION));
    return (
      <div className="mx-auto flex h-dvh w-full max-w-[430px] flex-col overflow-hidden bg-background">
        <CompleteTrip
          payout={payout}
          gross={active.fare}
          passenger={active.passenger}
          stars={stars}
          onStars={setStars}
          onContinue={() => driverStore.setSession("online")}
        />
      </div>
    );
  }

  const scene = mapScene(session, request);

  return (
    <div className="relative mx-auto flex h-dvh w-full max-w-[430px] flex-col overflow-hidden bg-background">
      <FakeMap {...scene} />

      {/* Floating top bar */}
      <div className="absolute inset-x-0 top-0 z-10 flex items-start justify-between p-4">
        <button
          type="button"
          aria-label="Menu"
          className="flex h-10 w-10 items-center justify-center rounded-full bg-card text-foreground shadow-float"
        >
          <Menu className="h-5 w-5" />
        </button>
        <div className="flex items-center gap-1.5 rounded-full bg-card px-3.5 py-2 text-sm shadow-float">
          <Banknote className="h-4 w-4 text-primary" strokeWidth={2.5} />
          <span className="font-extrabold">{naira(today)}</span>
          <span className="text-xs font-semibold text-muted-foreground">today</span>
        </div>
        <Link
          to="/profile"
          aria-label="Profile"
          className="flex h-10 w-10 items-center justify-center rounded-full bg-card text-foreground shadow-float"
        >
          <UserRound className="h-5 w-5" />
        </Link>
      </div>

      {/* Bottom sheet driven by the session state machine */}
      <div className={`relative z-10 mt-auto px-3 ${busy ? "pb-4" : "pb-[76px]"}`}>
        {session === "offline" && <OfflineSheet hasTrips={trips.length > 0} />}
        {session === "online" && <OnlineSheet today={today} trips={trips.length} />}
        {session === "request" && (
          <RequestSheet
            request={request}
            secondsLeft={secondsLeft}
            total={REQUEST_SECONDS}
            onAccept={accept}
            onDecline={() => driverStore.setSession("online")}
          />
        )}
        {session === "toPickup" && (
          <ToPickupSheet
            request={active}
            onArrived={() => driverStore.setSession("atPickup")}
            onCancel={() => driverStore.setSession("online")}
          />
        )}
        {session === "atPickup" && (
          <AtPickupSheet
            request={active}
            waitSeconds={waitSeconds}
            onStart={() => driverStore.setSession("onTrip")}
          />
        )}
        {session === "onTrip" && <OnTripSheet request={active} onComplete={finishTrip} />}
      </div>

      {!busy && <DriverTabBar />}
    </div>
  );
}

function OfflineSheet({ hasTrips }: { hasTrips: boolean }) {
  return (
    <div className="rounded-t-3xl bg-card px-5 pb-6 pt-5 shadow-sheet">
      {!hasTrips && (
        <div className="mb-4 flex items-center gap-2.5 rounded-xl bg-primary/10 px-3.5 py-3">
          <BadgeCheck className="h-5 w-5 shrink-0 text-primary" />
          <p className="text-[13px] font-semibold text-foreground">
            Your driver account is active — welcome aboard, Abdul!
          </p>
        </div>
      )}
      <div className="flex items-center justify-between gap-4">
        <div>
          <h2 className="text-lg font-extrabold">You're offline</h2>
          <p className="text-sm text-muted-foreground">
            Turn on to start receiving ride requests.
          </p>
        </div>
        <Switch
          checked={false}
          onCheckedChange={() => driverStore.setSession("online")}
          aria-label="Go online"
        />
      </div>
    </div>
  );
}

function OnlineSheet({ today, trips }: { today: number; trips: number }) {
  return (
    <div className="rounded-t-3xl bg-card px-5 pb-6 pt-5 shadow-sheet">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h2 className="text-lg font-extrabold">You're online</h2>
          <div className="mt-2 flex items-center gap-2">
            <span className="relative flex h-2.5 w-2.5">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-primary opacity-60" />
              <span className="relative inline-flex h-2.5 w-2.5 rounded-full bg-primary" />
            </span>
            <p className="text-sm font-semibold text-muted-foreground">
              Looking for ride requests near you…
            </p>
          </div>
        </div>
        <Switch
          checked
          onCheckedChange={() => driverStore.setSession("offline")}
          aria-label="Go offline"
        />
      </div>
      <div className="mt-5 grid grid-cols-3 divide-x divide-border rounded-2xl bg-muted py-3 text-center">
        <div className="px-2">
          <p className="text-base font-extrabold">{naira(today)}</p>
          <p className="text-xs font-semibold text-muted-foreground">Today</p>
        </div>
        <div className="px-2">
          <p className="text-base font-extrabold">{trips}</p>
          <p className="text-xs font-semibold text-muted-foreground">Trips</p>
        </div>
        <div className="px-2">
          <p className="text-base font-extrabold">{DRIVER_SHARE}%</p>
          <p className="text-xs font-semibold text-muted-foreground">Your share</p>
        </div>
      </div>
      <p className="mt-4 text-center text-xs text-muted-foreground">
        Your first request will appear automatically.
      </p>
    </div>
  );
}

function CountdownRing({ seconds, total }: { seconds: number; total: number }) {
  const r = 18;
  const c = 2 * Math.PI * r;
  return (
    <div className="relative h-11 w-11 shrink-0">
      <svg viewBox="0 0 44 44" className="h-11 w-11 -rotate-90">
        <circle cx="22" cy="22" r={r} fill="none" strokeWidth={4} className="stroke-muted" />
        <circle
          cx="22"
          cy="22"
          r={r}
          fill="none"
          strokeWidth={4}
          strokeLinecap="round"
          className="stroke-primary transition-[stroke-dashoffset] duration-1000 ease-linear"
          strokeDasharray={c}
          strokeDashoffset={c * (1 - seconds / total)}
        />
      </svg>
      <span className="absolute inset-0 flex items-center justify-center text-sm font-extrabold">
        {seconds}
      </span>
    </div>
  );
}

function RequestSheet({
  request,
  secondsLeft,
  total,
  onAccept,
  onDecline,
}: {
  request: RideRequest;
  secondsLeft: number;
  total: number;
  onAccept: () => void;
  onDecline: () => void;
}) {
  return (
    <div className="rounded-t-3xl bg-card px-5 pb-6 pt-5 shadow-sheet">
      <div className="flex items-center gap-3">
        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-secondary text-sm font-extrabold">
          {request.initials}
        </div>
        <div className="min-w-0 flex-1">
          <p className="truncate text-base font-extrabold">{request.passenger}</p>
          <p className="flex items-center gap-1 text-xs font-semibold text-muted-foreground">
            <Star className="h-3.5 w-3.5 fill-primary text-primary" />
            {request.rating} · pays {request.payment.toLowerCase()}
          </p>
        </div>
        <CountdownRing seconds={secondsLeft} total={total} />
      </div>

      <div className="mt-4 flex gap-3">
        <div className="flex flex-col items-center self-stretch pt-1.5">
          <span className="h-2.5 w-2.5 rounded-full bg-primary" />
          <span className="my-1 w-0.5 flex-1 rounded bg-border" />
          <span className="h-2.5 w-2.5 rounded-sm bg-foreground" />
        </div>
        <div className="space-y-3">
          <p className="text-sm font-semibold leading-5">{request.pickupName}</p>
          <p className="text-sm font-semibold leading-5">{request.dropoffName}</p>
        </div>
      </div>

      <div className="mt-4 flex items-center justify-between rounded-2xl bg-muted px-4 py-3">
        <div>
          <p className="text-xl font-extrabold text-primary">{naira(request.fare)}</p>
          <p className="text-xs font-semibold text-muted-foreground">Your earnings</p>
        </div>
        <div className="text-right text-xs font-semibold text-muted-foreground">
          <p>{request.distanceKm} km trip</p>
          <p>~{request.minutes} min</p>
        </div>
      </div>

      <div className="mt-4 flex gap-3">
        <Button
          variant="outline"
          size="lg"
          className="w-28 shrink-0 font-bold"
          onClick={onDecline}
        >
          <X className="h-5 w-5" /> Decline
        </Button>
        <Button size="lg" className="flex-1 text-base font-extrabold" onClick={onAccept}>
          <Navigation className="h-5 w-5" /> Accept ride
        </Button>
      </div>
    </div>
  );
}

function ToPickupSheet({
  request,
  onArrived,
  onCancel,
}: {
  request: RideRequest;
  onArrived: () => void;
  onCancel: () => void;
}) {
  return (
    <div className="rounded-t-3xl bg-card px-5 pb-6 pt-5 shadow-sheet">
      <p className="text-xs font-extrabold uppercase tracking-wide text-muted-foreground">
        On the way to pickup
      </p>
      <div className="mt-2 flex items-start justify-between gap-3">
        <p className="text-base font-extrabold leading-6">{request.pickupName}</p>
        <div className="shrink-0 text-right">
          <p className="text-sm font-extrabold text-primary">4 min</p>
          <p className="text-xs font-semibold text-muted-foreground">1.2 km</p>
        </div>
      </div>
      <p className="mt-1 text-sm text-muted-foreground">
        Passenger: <span className="font-semibold text-foreground">{request.passenger}</span>
      </p>
      <Button size="lg" className="mt-4 w-full text-base font-extrabold" onClick={onArrived}>
        I've arrived
      </Button>
      <button
        type="button"
        onClick={onCancel}
        className="mt-2 w-full text-center text-sm font-semibold text-muted-foreground"
      >
        Cancel ride
      </button>
    </div>
  );
}

function AtPickupSheet({
  request,
  waitSeconds,
  onStart,
}: {
  request: RideRequest;
  waitSeconds: number;
  onStart: () => void;
}) {
  const wait = `${String(Math.floor(waitSeconds / 60)).padStart(2, "0")}:${String(
    waitSeconds % 60,
  ).padStart(2, "0")}`;
  return (
    <div className="rounded-t-3xl bg-card px-5 pb-6 pt-5 shadow-sheet">
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-xs font-extrabold uppercase tracking-wide text-muted-foreground">
            You've arrived
          </p>
          <p className="mt-1 text-base font-extrabold">Waiting for {request.passenger}</p>
        </div>
        <div className="shrink-0 rounded-xl bg-muted px-3 py-2 text-center">
          <p className="text-sm font-extrabold tabular-nums">{wait}</p>
          <p className="text-[11px] font-semibold text-muted-foreground">wait time</p>
        </div>
      </div>
      <Button size="lg" className="mt-4 w-full text-base font-extrabold" onClick={onStart}>
        Start trip
      </Button>
    </div>
  );
}

function OnTripSheet({
  request,
  onComplete,
}: {
  request: RideRequest;
  onComplete: () => void;
}) {
  const [moving, setMoving] = useState(false);
  useEffect(() => {
    const timer = setTimeout(() => setMoving(true), 300);
    return () => clearTimeout(timer);
  }, []);
  return (
    <div className="rounded-t-3xl bg-card px-5 pb-6 pt-5 shadow-sheet">
      <p className="text-xs font-extrabold uppercase tracking-wide text-muted-foreground">
        In trip
      </p>
      <div className="mt-2 flex items-start justify-between gap-3">
        <p className="flex items-start gap-2 text-base font-extrabold leading-6">
          <Navigation className="mt-1 h-4 w-4 shrink-0 fill-primary text-primary" />
          {request.dropoffName}
        </p>
        <div className="shrink-0 text-right">
          <p className="text-sm font-extrabold text-primary">~{request.minutes} min</p>
          <p className="text-xs font-semibold text-muted-foreground">{request.distanceKm} km left</p>
        </div>
      </div>
      <div className="mt-4 h-1.5 rounded-full bg-muted">
        <div
          className="h-full rounded-full bg-primary transition-all duration-[25000ms] ease-linear"
          style={{ width: moving ? "78%" : "6%" }}
        />
      </div>
      <Button size="lg" className="mt-4 w-full text-base font-extrabold" onClick={onComplete}>
        Complete trip
      </Button>
    </div>
  );
}

function CompleteTrip({
  payout,
  gross,
  passenger,
  stars,
  onStars,
  onContinue,
}: {
  payout: number;
  gross: number;
  passenger: string;
  stars: number;
  onStars: (n: number) => void;
  onContinue: () => void;
}) {
  const commission = gross - payout;
  return (
    <div className="flex h-full flex-col px-5 pb-6 pt-10">
      <div className="flex flex-1 flex-col items-center justify-center text-center">
        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary">
          <Check className="h-8 w-8 text-primary-foreground" strokeWidth={3} />
        </div>
        <h1 className="mt-5 text-2xl font-extrabold">Trip complete!</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {passenger} was dropped off at the destination.
        </p>
        <p className="mt-5 text-4xl font-extrabold text-primary">{naira(payout)}</p>
        <p className="text-xs font-semibold text-muted-foreground">Added to today's earnings</p>

        <div className="mt-6 w-full rounded-2xl bg-muted px-4 py-3 text-left text-sm">
          <div className="flex justify-between py-0.5">
            <span className="text-muted-foreground">Fare collected</span>
            <span className="font-bold">{naira(gross)}</span>
          </div>
          <div className="flex justify-between py-0.5">
            <span className="text-muted-foreground">Bolt commission ({COMMISSION * 100}%)</span>
            <span className="font-bold">−{naira(commission)}</span>
          </div>
          <div className="mt-1 flex justify-between border-t border-border pt-2">
            <span className="font-extrabold">Your payout</span>
            <span className="font-extrabold text-primary">{naira(payout)}</span>
          </div>
        </div>

        <p className="mt-6 text-sm font-bold">Rate your passenger</p>
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
      <Button size="lg" className="text-base font-extrabold" onClick={onContinue}>
        Continue
      </Button>
    </div>
  );
}
