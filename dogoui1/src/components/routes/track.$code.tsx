import { useEffect, useState } from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { Phone, Star, ShieldCheck, Receipt, ChevronLeft } from "lucide-react";
import { AppHeader } from "@/components/dogo/AppHeader";
import { DogoMap } from "@/components/dogo/DogoMap";
import { ReceiptDialog } from "@/components/dogo/ReceiptDialog";
import { milestones, naira, vehicleLabel } from "@/data/dogo";
import { useShipments } from "@/lib/shipment-store";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/track/$code")({
  head: ({ params }) => ({
    meta: [
      { title: `Trip ${params.code} — DOGO Rides` },
      {
        name: "description",
        content: `Follow DOGO trip ${params.code}, see your driver and trip PIN.`,
      },
      { property: "og:title", content: `Trip ${params.code} — DOGO Rides` },
      { property: "og:description", content: "Follow your DOGO ride and see your driver." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: TrackPage,
});

function TrackPage() {
  const { code } = Route.useParams();
  const { getShipment } = useShipments();
  const shipment = getShipment(code);
  const [stage, setStage] = useState(1);
  const [receipt, setReceipt] = useState(false);

  useEffect(() => {
    const id = setInterval(() => setStage((s) => (s < milestones.length - 1 ? s + 1 : s)), 7000);
    return () => clearInterval(id);
  }, []);

  if (!shipment) {
    return (
      <div className="min-h-screen bg-background">
        <AppHeader />
        <main className="mx-auto max-w-md px-4 py-24 text-center">
          <h1 className="text-xl font-bold">Trip not found</h1>
          <p className="mt-2 text-sm text-muted-foreground">We couldn't find {code}.</p>
          <Link to="/track" className="mt-5 inline-block rounded-full brand-gradient px-5 py-2.5 font-semibold text-primary-foreground">
            Back to rides
          </Link>
        </main>
      </div>
    );
  }

  const rideMilestones = ["Confirmed", "Rider on the way", "Picked up", "On the road", "Arrived"];
  const steps = shipment.service === "ride" ? rideMilestones : milestones;
  const progress = stage / (steps.length - 1);

  return (
    <div className="min-h-screen bg-background">
      <AppHeader />
      <main className="mx-auto max-w-3xl space-y-4 px-4 pb-16 pt-4">
        <Link to="/track" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
          <ChevronLeft className="h-4 w-4" /> All trips
        </Link>

        <section className="relative overflow-hidden rounded-[2rem] border border-border">
          <DogoMap progress={progress} className="h-[280px] w-full sm:h-[360px]" />
          <div className="pointer-events-none absolute inset-0 bg-linear-to-t from-background via-transparent to-background/60" />
          <div className="absolute inset-x-0 top-0 grid grid-cols-[minmax(0,1fr)_auto] items-start gap-3 p-4">
            <div className="min-w-0">
              <p className="truncate font-display text-xl font-extrabold">{shipment.code}</p>
              <p className="truncate text-xs text-muted-foreground">
                {shipment.pickup} → {shipment.dropoff}
              </p>
            </div>
            <span className="shrink-0 rounded-full bg-success/20 px-3 py-1 text-xs font-bold text-success">
               {steps[stage]}
            </span>
          </div>
        </section>

        <section className="glass-card rounded-3xl p-4">
          <ol className="space-y-3">
            {steps.map((m, i) => (
              <li key={m} className="grid grid-cols-[auto_minmax(0,1fr)] items-center gap-3">
                <span
                  className={cn(
                    "grid h-7 w-7 shrink-0 place-items-center rounded-full border text-xs font-bold transition-colors",
                    i < stage
                      ? "border-transparent bg-success text-background"
                      : i === stage
                        ? "border-transparent brand-gradient text-primary-foreground"
                        : "border-border bg-secondary/50 text-muted-foreground",
                  )}
                >
                  {i + 1}
                </span>
                <span className={cn("truncate text-sm", i <= stage ? "font-semibold" : "text-muted-foreground")}>
                  {m}
                </span>
              </li>
            ))}
          </ol>
        </section>

        <section className="glass-card grid grid-cols-[auto_minmax(0,1fr)] items-center gap-3 rounded-3xl p-4">
          <div className="grid h-14 w-14 shrink-0 place-items-center rounded-2xl brand-gradient text-lg font-extrabold text-primary-foreground">
            TO
          </div>
          <div className="min-w-0">
            <p className="truncate font-bold">Tunde Oyelaran</p>
            <p className="truncate text-xs text-muted-foreground">
               {vehicleLabel(shipment.vehicleId)} • LAG-472-XA
            </p>
            <p className="mt-0.5 flex items-center gap-1 text-xs text-gold">
               <Star className="h-3.5 w-3.5 fill-current" /> 4.92 • 1,284 trips
            </p>
          </div>
          <div className="col-span-2 grid grid-cols-2 gap-2">
            <a
              href="tel:+2348024419922"
              className="flex items-center justify-center gap-2 rounded-full brand-gradient py-2.5 text-sm font-semibold text-primary-foreground"
            >
              <Phone className="h-4 w-4" /> Call
            </a>
            <Button type="button" variant="outline" onClick={() => setReceipt(true)} className="rounded-lg border-border bg-secondary/50"><Receipt className="h-4 w-4" /> Receipt</Button>
          </div>
        </section>

        <section className="glass-card grid grid-cols-[minmax(0,1fr)_auto] items-center gap-3 rounded-3xl border-gold/40 p-4">
          <div className="min-w-0">
            <p className="flex items-center gap-1.5 text-sm font-semibold">
              <ShieldCheck className="h-4 w-4 shrink-0 text-gold" /> {shipment.service === "ride" ? "Trip PIN" : "Delivery PIN"}
            </p>
            <p className="mt-1 text-xs text-muted-foreground">{shipment.service === "ride" ? "Share only with your rider." : "Share only with your rider when the package arrives."}</p>
          </div>
          <div className="flex shrink-0 gap-1.5">
            {shipment.pin.split("").map((d, i) => (
              <span
                key={i}
                className="grid h-10 w-9 place-items-center rounded-xl border border-gold/50 bg-gold/10 font-display text-lg font-bold text-gold"
              >
                {d}
              </span>
            ))}
          </div>
        </section>

        <section className="glass-card grid grid-cols-[minmax(0,1fr)_auto] items-center gap-3 rounded-3xl p-4">
          <div className="min-w-0">
            <p className="text-sm text-muted-foreground">Paid with {shipment.payment}</p>
            <p className="text-xl font-extrabold text-gold">{naira(shipment.price)}</p>
          </div>
           <Button
            type="button"
            onClick={() => setReceipt(true)}
            className="flex shrink-0 items-center gap-2 rounded-full border border-border bg-secondary/50 px-4 py-2.5 text-sm font-semibold transition-colors hover:bg-secondary"
          >
            <Receipt className="h-4 w-4 text-brand-soft" /> Receipt
           </Button>
        </section>
      </main>

      <ReceiptDialog shipment={shipment} open={receipt} onOpenChange={setReceipt} />
    </div>
  );
}
