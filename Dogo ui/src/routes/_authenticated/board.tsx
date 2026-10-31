import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useCrew, SERVICE_LABEL, STATUS_LABEL, PAYMENT_LABEL, RATE_PER_KM, DRIVER_SHARE, naira } from "@/lib/crew";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export const Route = createFileRoute("/_authenticated/board")({
  head: () => ({
    meta: [
      { title: "Trip board — DOGO Crew" },
      { name: "description", content: "Open and active trips for DOGO drivers and dispatchers." },
      { property: "og:title", content: "Trip board — DOGO Crew" },
      { property: "og:description", content: "Open and active trips." },
    ],
  }),
  component: Board,
});

type Tab = "open" | "active" | "done";

function Board() {
  const { session, isDispatcher, isDriver, name } = useCrew();
  const qc = useQueryClient();
  const [tab, setTab] = useState<Tab>("open");

  const { data: trips = [] } = useQuery({
    queryKey: ["trips"],
    queryFn: async () => {
      const { data, error } = await supabase.from("trips").select("*").order("created_at", { ascending: false });
      if (error) throw error;
      return data;
    },
  });

  useEffect(() => {
    const ch = supabase
      .channel("trips-board")
      .on("postgres_changes", { event: "*", schema: "public", table: "trips" }, () =>
        qc.invalidateQueries({ queryKey: ["trips"] }))
      .subscribe();
    return () => { supabase.removeChannel(ch); };
  }, [qc]);

  const filtered = trips.filter((t) =>
    tab === "open" ? t.status === "pending"
    : tab === "active" ? ["accepted", "en_route", "picked_up"].includes(t.status)
    : ["completed", "cancelled"].includes(t.status));

  async function accept(id: string) {
    const { error } = await supabase.rpc("accept_trip", { _trip: id });
    if (error) toast.error(error.message);
    else toast.success("Trip accepted");
    qc.invalidateQueries({ queryKey: ["trips"] });
  }
  async function markPaid(id: string) {
    const { error } = await supabase.rpc("mark_trip_paid", { _trip: id });
    if (error) toast.error(error.message); else toast.success("Payment received — trip sent to drivers");
    qc.invalidateQueries({ queryKey: ["trips"] });
  }

  const count = (s: Tab) => trips.filter((t) =>
    s === "open" ? t.status === "pending" : s === "active" ? ["accepted", "en_route", "picked_up"].includes(t.status) : ["completed", "cancelled"].includes(t.status)).length;

  return (
    <div>
      <section className="map-grid relative overflow-hidden rounded-[2rem] border border-border">
        <div className="h-44 sm:h-56" />
        <div className="absolute inset-0 bg-linear-to-t from-background via-background/40 to-transparent" />
        <div className="absolute inset-x-0 top-0 p-5 sm:p-7">
          <h1 className="text-2xl font-extrabold sm:text-4xl">Hi {name.split(" ")[0] || "there"}</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            {isDispatcher ? "Create trips, assign drivers and keep customers updated." : "Pick up a trip and keep your customer in the loop."}
          </p>
        </div>
      </section>

      <div className="glass-card relative -mt-12 p-4 sm:p-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex gap-1.5">
            {(["open", "active", "done"] as Tab[]).map((t) => (
              <button key={t} onClick={() => setTab(t)}
                className={`rounded-full border border-border px-3.5 py-1.5 text-sm font-semibold ${tab === t ? "bg-secondary text-foreground" : "text-muted-foreground"}`}>
                {t === "open" ? "Open" : t === "active" ? "In progress" : "Finished"} <span className="text-gold">{count(t)}</span>
              </button>
            ))}
          </div>
          {isDispatcher && <NewTrip />}
        </div>

        <div className="mt-4 space-y-3">
          {filtered.length === 0 && <p className="py-10 text-center text-sm text-muted-foreground">No trips here right now.</p>}
          {filtered.map((t) => {
            const mine = t.assigned_to === session.user.id;
            return (
              <div key={t.id} className="rounded-xl border border-border bg-secondary/40 p-4">
                <div className="flex flex-wrap items-start justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span className="rounded-full bg-gold/15 px-2.5 py-0.5 text-xs font-bold text-gold">{SERVICE_LABEL[t.service]}</span>
                    <span className="text-xs text-muted-foreground">#{t.code}</span>
                    <span className="text-xs font-semibold text-brand">{STATUS_LABEL[t.status]}</span>
                    <span className={`text-xs font-semibold ${t.payment_status === "paid" ? "text-success" : "text-gold"}`}>{PAYMENT_LABEL[t.payment_status]}</span>
                    {mine && <span className="text-xs font-semibold text-success">Yours</span>}
                  </div>
                  <span className="font-display text-lg font-bold tabular-nums">{naira(t.fare)}</span>
                </div>
                <div className="mt-3 grid gap-1 text-sm">
                  <p><span className="text-muted-foreground">From</span> {t.pickup}</p>
                  <p><span className="text-muted-foreground">To</span> {t.dropoff}</p>
                  <p className="text-muted-foreground">{Number(t.distance_km) > 0 ? `${t.distance_km} km · ` : ""}{t.customer_name}{t.notes ? ` · ${t.notes}` : ""}</p>
                  {isDriver && <p className="text-success">You earn {naira(Math.floor(t.fare * DRIVER_SHARE))}</p>}
                </div>
                <div className="mt-3 flex flex-wrap gap-2">
                  {isDriver && t.status === "pending" && !t.assigned_to && t.payment_status === "paid" && (
                    <Button onClick={() => accept(t.id)} className="brand-gradient rounded-full font-bold">Accept trip</Button>
                  )}
                  {isDispatcher && t.payment_status === "unpaid" && (
                    <Button onClick={() => markPaid(t.id)} className="brand-gradient rounded-full font-bold">Mark as paid</Button>
                  )}
                  {(isDispatcher || mine) && (
                    <Button asChild variant="outline" className="rounded-full">
                      <Link to="/trips/$id" params={{ id: t.id }}>Open & chat</Link>
                    </Button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function NewTrip() {
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [photo, setPhoto] = useState<File | null>(null);
  const [f, setF] = useState({ service: "taxi", customer_name: "", customer_phone: "", pickup: "", dropoff: "", km: "", notes: "", paid: false });
  const set = (k: "customer_name" | "customer_phone" | "pickup" | "dropoff" | "km" | "notes") =>
    (e: React.ChangeEvent<HTMLInputElement>) => setF({ ...f, [k]: e.target.value });
  const km = Number(f.km) || 0;
  const fare = Math.round(km * RATE_PER_KM[f.service as keyof typeof RATE_PER_KM]);

  async function save(e: React.FormEvent) {
    e.preventDefault();
    if (f.service === "bike" && !photo) { toast.error("Add a picture of the goods"); return; }
    setBusy(true);
    let goods_photo_url: string | null = null;
    if (f.service === "bike" && photo) {
      const path = `${crypto.randomUUID()}-${photo.name.replace(/[^\w.]/g, "")}`;
      const up = await supabase.storage.from("goods-photos").upload(path, photo);
      if (up.error) { toast.error(up.error.message); setBusy(false); return; }
      goods_photo_url = path;
    }
    const { error } = await supabase.from("trips").insert({
      service: f.service as "taxi", customer_name: f.customer_name, customer_phone: f.customer_phone,
      pickup: f.pickup, dropoff: f.dropoff, notes: f.notes || null, distance_km: km, fare, goods_photo_url,
      payment_status: f.paid ? "paid" : "unpaid", paid_at: f.paid ? new Date().toISOString() : null,
    });
    setBusy(false);
    if (error) { toast.error(error.message); return; }
    toast.success(f.paid ? "Trip posted to drivers" : "Trip saved — waiting for customer payment");
    setOpen(false); setPhoto(null);
    qc.invalidateQueries({ queryKey: ["trips"] });
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild><Button className="brand-gradient rounded-full font-bold">New trip</Button></DialogTrigger>
      <DialogContent>
        <DialogHeader><DialogTitle>New trip</DialogTitle></DialogHeader>
        <form onSubmit={save} className="space-y-3">
          <div><Label>Service</Label>
            <Select value={f.service} onValueChange={(v) => setF({ ...f, service: v })}>
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="taxi">Taxi</SelectItem><SelectItem value="keke">Keke</SelectItem><SelectItem value="bike">Bike dispatch</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div><Label>Customer</Label><Input required value={f.customer_name} onChange={set("customer_name")} /></div>
            <div><Label>Phone</Label><Input required value={f.customer_phone} onChange={set("customer_phone")} /></div>
          </div>
          <div><Label>Pickup</Label><Input required value={f.pickup} onChange={set("pickup")} /></div>
          <div><Label>Drop-off</Label><Input required value={f.dropoff} onChange={set("dropoff")} /></div>
          <div className="grid grid-cols-2 gap-3">
            <div><Label>Distance (km)</Label><Input required type="number" step="0.1" min="0.1" value={f.km} onChange={set("km")} /></div>
            <div><Label>Notes</Label><Input value={f.notes} onChange={set("notes")} /></div>
          </div>
          {f.service === "bike" && (
            <div><Label>Picture of the goods</Label>
              <Input type="file" accept="image/*" capture="environment" onChange={(e) => setPhoto(e.target.files?.[0] ?? null)} />
            </div>
          )}
          <div className="rounded-xl border border-gold/30 bg-gold/10 p-3 text-sm">
            <div className="flex justify-between"><span>{km || 0} km × {naira(RATE_PER_KM[f.service as keyof typeof RATE_PER_KM])}</span><span className="font-bold">{naira(fare)}</span></div>
            <div className="flex justify-between text-muted-foreground"><span>Driver 70% / DOGO 30%</span><span>{naira(Math.floor(fare * DRIVER_SHARE))} / {naira(fare - Math.floor(fare * DRIVER_SHARE))}</span></div>
          </div>
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={f.paid} onChange={(e) => setF({ ...f, paid: e.target.checked })} />
            Customer has already paid
          </label>
          <Button disabled={busy} className="brand-gradient h-11 w-full rounded-xl font-bold">{busy ? "Saving…" : "Post trip"}</Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}
