import { useState } from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { ArrowRight, Bike, Check, ChevronRight, Clock3, MapPin, Navigation, RotateCcw, ShieldCheck, UserRound, Wallet, X } from "lucide-react";
import { AppHeader } from "@/components/dogo/AppHeader";
import { DogoMap } from "@/components/dogo/DogoMap";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useAccount } from "@/lib/account-store";
import { naira, vehicleIdFromName, vehicleLabel, vehicles } from "@/data/dogo";

type RideOffer = { id: string; vehicleId: string; pickup: string; dropoff: string; distance: number; pickupEta: string; passenger: string };
type TripStep = "accepted" | "pickup" | "onboard";

const sampleOffers: RideOffer[] = [
  { id: "DR-3041", vehicleId: "taxi", pickup: "Lagos — Ikeja GRA", dropoff: "Lagos — Lekki Phase 1", distance: 24, pickupEta: "3 min away", passenger: "Emeka" },
  { id: "DR-3042", vehicleId: "taxi", pickup: "Lagos — Lekki Phase 1", dropoff: "Lagos — Yaba", distance: 12, pickupEta: "6 min away", passenger: "Funke" },
  { id: "DR-1042", vehicleId: "bike", pickup: "Lagos — Ikeja GRA", dropoff: "Lagos — Yaba", distance: 12, pickupEta: "4 min away", passenger: "Ada" },
  { id: "DR-1043", vehicleId: "bike", pickup: "Lagos — Yaba", dropoff: "Lagos — Lekki Phase 1", distance: 24, pickupEta: "7 min away", passenger: "Tomi" },
  { id: "DR-2041", vehicleId: "tricycle", pickup: "Lagos — Ikeja GRA", dropoff: "Lagos — Lekki Phase 1", distance: 24, pickupEta: "5 min away", passenger: "Chioma" },
  { id: "DR-2042", vehicleId: "tricycle", pickup: "Lagos — Yaba", dropoff: "Lagos — Ikeja GRA", distance: 12, pickupEta: "8 min away", passenger: "Kunle" },
];

const fareFor = (offer: RideOffer) => {
  const vehicle = vehicles.find((item) => item.id === offer.vehicleId);
  return vehicle ? Math.round((vehicle.base + vehicle.perKm * offer.distance) / 10) * 10 : 0;
};

export const Route = createFileRoute("/rider")({
  head: () => ({
    meta: [
      { title: "Rider requests and trips — DOGO Rides" },
      { name: "description", content: "Explore the DOGO rider experience: review sample Taxi, Tricycle or Bike dispatch requests, accept or decline, and follow a trip." },
      { property: "og:title", content: "DOGO Rider requests and trips" },
      { property: "og:description", content: "Preview ride requests and trip steps in the DOGO rider workspace." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: RiderPage,
});

function RiderPage() {
  const { account, update } = useAccount();
  const [declined, setDeclined] = useState<string[]>([]);
  const [accepted, setAccepted] = useState<RideOffer | null>(null);
  const [step, setStep] = useState<TripStep>("accepted");
  const [pin, setPin] = useState("");
  const [pinError, setPinError] = useState(false);
  const [completed, setCompleted] = useState<RideOffer[]>([]);

  if (!account || account.role !== "rider") {
    return (
      <div className="min-h-screen bg-background">
        <AppHeader />
        <main className="mx-auto max-w-xl px-4 py-24 text-center">
          <Bike className="mx-auto h-10 w-10 text-brand" />
          <h1 className="mt-5 font-display text-2xl font-bold">Drive with DOGO</h1>
          <p className="mt-2 text-sm text-muted-foreground">Sign in as a rider to see your ride requests.</p>
          <Button asChild className="mt-6 h-12 rounded-lg px-6"><Link to="/auth">Rider sign in <ArrowRight /></Link></Button>
        </main>
      </div>
    );
  }

  const vehicleId = vehicleIdFromName(account.vehicle);
  const offers = sampleOffers.filter((offer) => offer.vehicleId === vehicleId && !declined.includes(offer.id) && !completed.some((trip) => trip.id === offer.id));
  const progress = step === "onboard" ? 0.65 : step === "pickup" ? 0.2 : 0;
  const destination = accepted && (step === "onboard" ? accepted.dropoff : accepted.pickup);
  const stepIndex = !accepted ? 0 : step === "accepted" ? 1 : step === "pickup" ? 2 : 3;

  function startTrip() {
    if (pin !== "4826") {
      setPinError(true);
      return;
    }
    setPinError(false);
    setStep("onboard");
  }

  function completeTrip() {
    if (!accepted) return;
    setCompleted((trips) => [accepted, ...trips]);
    setAccepted(null);
    setStep("accepted");
    setPin("");
  }

  return (
    <div className="min-h-screen bg-background">
      <AppHeader />
      <main className="mx-auto max-w-6xl px-4 pb-24 pt-6 sm:pt-9">
        <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="text-xs font-bold uppercase text-brand-soft">DOGO / Rider</p>
            <h1 className="mt-2 font-display text-2xl font-extrabold sm:text-4xl">Hello, {account.name.split(" ")[0]}</h1>
            <p className="mt-2 text-sm text-muted-foreground">Your space for {vehicleLabel(vehicleId)} rides.</p>
          </div>
          <Link to="/account" className="inline-flex items-center gap-1 text-sm font-semibold text-brand-soft">My profile <ChevronRight className="h-4 w-4" /></Link>
        </div>

        <div className="mb-6 flex items-start gap-3 border-l-4 border-gold bg-secondary/60 px-4 py-3 text-sm">
          <ShieldCheck className="mt-0.5 h-5 w-5 shrink-0 text-gold" />
          <p><strong>Demo mode.</strong> These rides are examples. Going online, accepting a ride and completing a trip here do not contact passengers, start live dispatch or pay out earnings.</p>
        </div>

        <div className="grid gap-7 lg:grid-cols-[minmax(0,1.65fr)_minmax(280px,1fr)]">
          <div className="min-w-0 space-y-6">
            <section aria-label="Availability" className="flex flex-wrap items-center justify-between gap-4 border-y border-border bg-secondary/40 px-4 py-5 sm:px-6">
              <div className="flex items-center gap-3">
                <span className={`h-3 w-3 shrink-0 rounded-full ${account.online ? "bg-success" : "bg-muted-foreground"}`} />
                <div>
                  <h2 className="font-display text-lg font-bold">{account.online ? "Available for sample rides" : "You're offline"}</h2>
                  <p className="text-xs text-muted-foreground">{accepted ? "Finish this sample trip before going offline" : account.online ? "Review requests below" : "Go online to view sample requests"}</p>
                </div>
              </div>
              <Button type="button" role="switch" aria-label="Available for sample rides" aria-checked={!!account.online} disabled={!!accepted} onClick={() => update({ online: !account.online })} variant={account.online ? "default" : "secondary"} className="h-12 min-w-32 rounded-lg px-5 font-bold">
                {account.online ? "Go offline" : "Go online"}
              </Button>
            </section>

            <section aria-label="Trip map" className="relative overflow-hidden rounded-lg border border-border">
              <DogoMap {...(accepted ? { progress } : {})} className="h-[220px] w-full sm:h-[310px]" />
              <div className="absolute bottom-3 left-3 rounded-md border border-border bg-card px-3 py-2 text-xs font-semibold shadow-sm">
                {accepted ? (step === "onboard" ? "To drop-off · sample route" : "To pickup · sample route") : "Sample route preview"}
              </div>
            </section>

            <section aria-labelledby="requests-heading">
              <div className="mb-4 flex flex-wrap items-center justify-between gap-2">
                <div>
                  <p className="text-xs font-bold uppercase text-gold">Sample requests</p>
                  <h2 id="requests-heading" className="mt-1 font-display text-xl font-bold">{accepted ? "Your current trip" : "Ride requests"}</h2>
                </div>
                <span className="border border-border bg-secondary px-2.5 py-1 text-xs font-semibold">Demo only</span>
              </div>

              {accepted ? (
                <div className="border border-border bg-card p-5 sm:p-6">
                  <div className="flex flex-wrap items-start justify-between gap-3 border-b border-border pb-5">
                    <div><p className="text-xs font-bold uppercase text-brand-soft">{accepted.id} · {step === "onboard" ? "On the road" : step === "pickup" ? "At pickup" : "Accepted"}</p><h3 className="mt-1 font-display text-xl font-bold">{accepted.passenger}'s {accepted.vehicleId === "bike" ? "package" : "ride"}</h3><p className="mt-1 text-sm text-muted-foreground">{vehicleLabel(accepted.vehicleId)} · {accepted.distance} km</p></div>
                    <div className="text-left sm:text-right"><p className="text-xs text-muted-foreground">Sample fare</p><p className="font-display text-xl font-bold text-gold">{naira(fareFor(accepted))}</p></div>
                  </div>
                  <RouteStops offer={accepted} />
                  <div className="space-y-4 border-t border-border pt-5">
                    <div className="flex items-center gap-2 text-sm font-semibold"><UserRound className="h-4 w-4 text-brand-soft" /> {accepted.passenger} · Sample passenger</div>
                    {destination && <a href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(destination)}`} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-2 text-sm font-semibold text-brand-soft underline underline-offset-4"><Navigation className="h-4 w-4" /> Directions to {step === "onboard" ? "drop-off" : "pickup"}</a>}
                    {step === "accepted" && <Button onClick={() => setStep("pickup")} className="h-12 w-full rounded-lg text-sm font-bold">I've arrived at pickup <ArrowRight /></Button>}
                    {step === "pickup" && <div className="space-y-3"><div><Label htmlFor="trip-pin">Sample passenger PIN</Label><p className="mt-1 text-xs text-muted-foreground">For this demo, enter <strong>4826</strong> to start the trip.</p></div><Input id="trip-pin" inputMode="numeric" autoComplete="off" maxLength={4} value={pin} onChange={(event) => { setPin(event.target.value.replace(/\D/g, "").slice(0, 4)); setPinError(false); }} placeholder="4-digit PIN" aria-invalid={pinError} className="h-12 max-w-48 text-center text-lg tracking-widest" />{pinError && <p role="alert" className="text-sm text-destructive">That PIN doesn't match this sample trip.</p>}<Button onClick={startTrip} className="h-12 w-full rounded-lg font-bold">Start sample trip <ArrowRight /></Button></div>}
                    {step === "onboard" && <Button onClick={completeTrip} className="h-12 w-full rounded-lg font-bold"><Check /> Complete sample trip</Button>}
                  </div>
                </div>
              ) : !account.online ? (
                <div className="border border-dashed border-border bg-secondary/30 px-5 py-10 text-center"><Bike className="mx-auto h-8 w-8 text-brand-soft" /><p className="mt-3 font-semibold">No requests while you're offline</p><p className="mt-1 text-sm text-muted-foreground">Go online above to preview available rides.</p></div>
              ) : vehicleId === "previous" ? (
                <div className="border border-border bg-secondary/40 px-5 py-8 text-center"><p className="font-semibold">Vehicle not available</p><p className="mt-1 text-sm text-muted-foreground">Only Taxi, Tricycle and Bike dispatch previews are available.</p></div>
              ) : offers.length === 0 ? (
                <div className="border border-border bg-secondary/40 px-5 py-8 text-center"><Check className="mx-auto h-7 w-7 text-success" /><p className="mt-3 font-semibold">You're all caught up</p><p className="mt-1 text-sm text-muted-foreground">No more sample requests right now.</p><Button variant="outline" onClick={() => { setDeclined([]); setCompleted([]); }} className="mt-5 h-11 rounded-lg"><RotateCcw /> Replay samples</Button></div>
              ) : (
                <div className="space-y-3">
                  {offers.map((offer) => <article key={offer.id} className="border border-border bg-card p-5 sm:p-6">
                    <div className="flex flex-wrap items-start justify-between gap-3"><div><p className="text-xs font-bold uppercase text-brand-soft">New request · {offer.id}</p><h3 className="mt-1 font-display text-lg font-bold">{offer.passenger} needs a ride</h3><p className="mt-1 flex items-center gap-1 text-xs text-muted-foreground"><Clock3 className="h-3.5 w-3.5" /> Pickup {offer.pickupEta} · {offer.distance} km trip</p></div><div className="text-left sm:text-right"><p className="text-xs text-muted-foreground">Sample fare</p><p className="font-display text-xl font-bold text-gold">{naira(fareFor(offer))}</p></div></div>
                    <RouteStops offer={offer} />
                    <div className="grid grid-cols-2 gap-3"><Button variant="outline" onClick={() => setDeclined((ids) => [...ids, offer.id])} className="h-12 rounded-lg font-bold"><X /> Decline</Button><Button onClick={() => { setAccepted(offer); setStep("accepted"); setPin(""); }} className="h-12 rounded-lg font-bold"><Check /> Accept ride</Button></div>
                  </article>)}
                </div>
              )}
            </section>

            {completed.length > 0 && <section className="border-t border-border pt-5"><h2 className="font-display text-lg font-bold">Completed in this demo</h2><div className="mt-3 space-y-2">{completed.map((trip) => <div key={trip.id} className="flex flex-wrap items-center justify-between gap-2 border-b border-border py-3 text-sm"><span className="flex items-center gap-2"><Check className="h-4 w-4 text-success" /> {trip.pickup} → {trip.dropoff}</span><span className="font-semibold text-gold">{naira(fareFor(trip))} sample fare</span></div>)}</div><p className="mt-3 text-xs text-muted-foreground">No real trips or payments were recorded.</p></section>}
          </div>

          <aside className="min-w-0 space-y-7">
            <section className="border-t border-border pt-5"><h2 className="font-display text-lg font-bold">Trip steps</h2><ol className="mt-5 space-y-5">{["Accept a request", "Reach pickup", "Check passenger PIN", "Ride to drop-off"].map((label, index) => <li key={label} className="flex items-center gap-3"><span className={`grid h-8 w-8 shrink-0 place-items-center rounded-full border text-xs font-bold ${index < stepIndex ? "border-success bg-success/15 text-success" : index === stepIndex && accepted ? "border-brand bg-brand/15 text-brand-soft" : "border-border text-muted-foreground"}`}>{index < stepIndex ? <Check className="h-4 w-4" /> : index + 1}</span><span className={`text-sm ${index <= stepIndex && accepted ? "font-semibold" : "text-muted-foreground"}`}>{label}</span></li>)}</ol></section>
            <section className="border-t border-border pt-5"><h2 className="font-display text-lg font-bold">Your vehicle</h2><div className="mt-4 flex items-center gap-4 border border-border bg-secondary/40 p-4"><span className="grid h-12 w-12 shrink-0 place-items-center rounded-md bg-brand/15"><Bike className="h-6 w-6 text-brand-soft" /></span><div className="min-w-0"><p className="font-semibold">{account.vehicle ? vehicleLabel(vehicleId) : "Vehicle not added"}</p><p className="text-xs text-muted-foreground">{account.plate || "No plate number"}</p></div></div><Link to="/verify" className="mt-4 flex items-center justify-between gap-3 border-b border-border pb-4 text-sm font-medium"><span className="flex items-center gap-2"><ShieldCheck className="h-4 w-4 text-gold" /> Verification</span><span className="flex items-center gap-1 capitalize text-muted-foreground">{account.verification.kyv} <ChevronRight className="h-4 w-4" /></span></Link></section>
            <section className="border-t border-border pt-5"><h2 className="font-display text-lg font-bold">Earnings</h2><p className="mt-3 flex items-center gap-2 text-sm text-muted-foreground"><Wallet className="h-4 w-4 text-gold" /> No real earnings in this demo.</p></section>
          </aside>
        </div>
      </main>
    </div>
  );
}

function RouteStops({ offer }: { offer: RideOffer }) {
  return <div className="space-y-4 py-5"><div className="flex gap-3"><MapPin className="mt-0.5 h-5 w-5 shrink-0 text-brand-soft" /><div><p className="text-xs text-muted-foreground">Pickup</p><p className="font-semibold">{offer.pickup}</p></div></div><div className="flex gap-3"><MapPin className="mt-0.5 h-5 w-5 shrink-0 text-gold" /><div><p className="text-xs text-muted-foreground">Drop-off</p><p className="font-semibold">{offer.dropoff}</p></div></div></div>;
}
