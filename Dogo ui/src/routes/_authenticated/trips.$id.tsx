import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useCrew, SERVICE_LABEL, STATUS_LABEL, NEXT_STATUS, PAYMENT_LABEL, DRIVER_SHARE, naira } from "@/lib/crew";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import type { Tables } from "@/integrations/supabase/types";

function GoodsPhoto({ path }: { path: string }) {
  const { data: url } = useQuery({
    queryKey: ["goods", path],
    queryFn: async () => (await supabase.storage.from("goods-photos").createSignedUrl(path, 3600)).data?.signedUrl ?? null,
  });
  return (
    <div className="glass-card p-5">
      <p className="text-xs uppercase tracking-widest text-muted-foreground">Goods to deliver</p>
      {url ? <img src={url} alt="Goods for dispatch" className="mt-2 max-h-72 w-full rounded-xl object-cover" /> : <div className="mt-2 h-40 rounded-xl bg-secondary" />}
    </div>
  );
}

function CancelTrip({ trip, onDone }: { trip: Tables<"trips">; onDone: () => void }) {
  const [open, setOpen] = useState(false);
  const [km, setKm] = useState("");
  const moved = !!trip.moved_at;
  const paid = trip.payment_status === "paid";
  const covered = Math.min(Number(km) || 0, Number(trip.distance_km) || 0);
  const refund = !paid ? 0
    : !moved || covered <= 0 ? Math.floor(trip.fare * 0.9)
    : Number(trip.distance_km) > 0 ? Math.max(0, Math.floor(trip.fare * (1 - covered / Number(trip.distance_km)))) : 0;

  async function go() {
    const { data, error } = await supabase.rpc("cancel_trip", { _trip: trip.id, _covered_km: moved ? Number(km) || 0 : 0 });
    if (error) { toast.error(error.message); return; }
    toast.success(paid ? `Trip cancelled — refund ${naira(data ?? 0)}` : "Trip cancelled");
    setOpen(false); onDone();
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild><Button variant="ghost" className="w-full text-destructive">Cancel trip</Button></DialogTrigger>
      <DialogContent>
        <DialogHeader><DialogTitle>Cancel trip #{trip.code}</DialogTitle></DialogHeader>
        {moved ? (
          <div><Label>Distance already covered (km of {trip.distance_km})</Label>
            <Input type="number" step="0.1" min="0" value={km} onChange={(e) => setKm(e.target.value)} />
          </div>
        ) : <p className="text-sm text-muted-foreground">The driver has not moved yet, so DOGO keeps 10%.</p>}
        <div className="rounded-xl border border-gold/30 bg-gold/10 p-3 text-sm">
          {paid ? <>Customer refund: <b>{naira(refund)}</b> of {naira(trip.fare)}</> : "Customer has not paid — nothing to refund."}
        </div>
        <Button onClick={go} variant="destructive" className="h-11 w-full rounded-xl font-bold">Confirm cancel</Button>
      </DialogContent>
    </Dialog>
  );
}

export const Route = createFileRoute("/_authenticated/trips/$id")({
  head: () => ({
    meta: [
      { title: "Trip details — DOGO Crew" },
      { name: "description", content: "Trip progress and customer chat." },
      { property: "og:title", content: "Trip details — DOGO Crew" },
      { property: "og:description", content: "Trip progress and customer chat." },
    ],
  }),
  component: TripPage,
});

const QUICK = ["I'm on my way 🚗", "I've arrived at pickup", "Running 5 mins late, sorry", "Please confirm your exact location"];

function TripPage() {
  const { id } = Route.useParams();
  const { session, isDispatcher } = useCrew();
  const qc = useQueryClient();
  const [text, setText] = useState("");
  const endRef = useRef<HTMLDivElement>(null);

  const { data: trip } = useQuery({
    queryKey: ["trip", id],
    queryFn: async () => (await supabase.from("trips").select("*").eq("id", id).maybeSingle()).data,
  });
  const { data: msgs = [] } = useQuery({
    queryKey: ["msgs", id],
    queryFn: async () => (await supabase.from("trip_messages").select("*").eq("trip_id", id).order("created_at")).data ?? [],
  });
  const { data: crew = [] } = useQuery({
    queryKey: ["members"],
    enabled: isDispatcher,
    queryFn: async () => (await supabase.rpc("list_members")).data ?? [],
  });
  const nameOf = (uid: string | null) => crew.find((c) => c.id === uid)?.full_name;

  useEffect(() => {
    const ch = supabase.channel(`trip-${id}`)
      .on("postgres_changes", { event: "INSERT", schema: "public", table: "trip_messages", filter: `trip_id=eq.${id}` },
        () => qc.invalidateQueries({ queryKey: ["msgs", id] }))
      .on("postgres_changes", { event: "UPDATE", schema: "public", table: "trips", filter: `id=eq.${id}` },
        () => qc.invalidateQueries({ queryKey: ["trip", id] }))
      .subscribe();
    return () => { supabase.removeChannel(ch); };
  }, [id, qc]);

  useEffect(() => { endRef.current?.scrollIntoView({ behavior: "smooth" }); }, [msgs.length]);

  if (!trip) return <p className="py-20 text-center text-muted-foreground">Trip not found or not assigned to you.</p>;

  async function send(body: string, kind: "staff" | "customer_log" = "staff") {
    if (!body.trim()) return;
    const { error } = await supabase.from("trip_messages").insert({ trip_id: id, body, sender_id: session.user.id, sender_kind: kind });
    if (error) { toast.error(error.message); return; }
    setText("");
    qc.invalidateQueries({ queryKey: ["msgs", id] });
  }
  function refresh() {
    qc.invalidateQueries({ queryKey: ["trip", id] });
    qc.invalidateQueries({ queryKey: ["trips"] });
    qc.invalidateQueries({ queryKey: ["wallet"] });
  }
  async function update(patch: Record<string, unknown>) {
    const { error } = await supabase.from("trips").update({ ...patch, updated_at: new Date().toISOString() }).eq("id", id);
    if (error) { toast.error(error.message); return; }
    refresh();
  }
  async function markPaid() {
    const { error } = await supabase.rpc("mark_trip_paid", { _trip: id });
    if (error) toast.error(error.message); else toast.success("Payment recorded");
    refresh();
  }

  const next = NEXT_STATUS[trip.status];
  const canAct = isDispatcher || trip.assigned_to === session.user.id;
  const drivers = crew.filter((c) => c.roles.includes("driver"));

  return (
    <div className="grid gap-4 lg:grid-cols-[1fr_1.1fr]">
      <div className="space-y-4">
        <Link to="/board" className="text-sm text-muted-foreground hover:text-foreground">← All trips</Link>
        <div className="glass-card p-5">
          <div className="flex items-center justify-between">
            <span className="rounded-full bg-gold/15 px-2.5 py-0.5 text-xs font-bold text-gold">{SERVICE_LABEL[trip.service]} · #{trip.code}</span>
            <span className="text-sm font-semibold text-brand">{STATUS_LABEL[trip.status]}</span>
          </div>
          <p className="mt-3 font-display text-3xl font-extrabold tabular-nums">{naira(trip.fare)}</p>
          <p className="text-sm text-muted-foreground">
            {Number(trip.distance_km) > 0 && `${trip.distance_km} km · `}
            <span className={trip.payment_status === "paid" ? "text-success" : "text-gold"}>{PAYMENT_LABEL[trip.payment_status]}</span>
            {" · "}Driver gets {naira(Math.floor((trip.fare - (trip.refund_amount ?? 0)) * DRIVER_SHARE))}
          </p>
          {trip.refund_amount != null && (
            <p className="mt-2 rounded-lg border border-border bg-secondary/40 p-2.5 text-sm">
              Refunded {naira(trip.refund_amount)} to customer{trip.distance_covered_km ? ` · ${trip.distance_covered_km} km covered` : " · driver had not moved (10% kept)"}
            </p>
          )}
          <div className="mt-4 space-y-2 text-sm">
            <p><span className="text-muted-foreground">Pickup</span><br />{trip.pickup}</p>
            <p><span className="text-muted-foreground">Drop-off</span><br />{trip.dropoff}</p>
            {trip.notes && <p className="rounded-lg border border-gold/30 bg-gold/10 p-2.5">{trip.notes}</p>}
          </div>
        </div>

        <div className="glass-card p-5">
          <p className="text-xs uppercase tracking-widest text-muted-foreground">Customer</p>
          <p className="mt-1 text-lg font-bold">{trip.customer_name}</p>
          <div className="mt-3 flex gap-2">
            <Button asChild className="brand-gradient flex-1 rounded-full font-bold"><a href={`tel:${trip.customer_phone}`}>Call</a></Button>
            <Button asChild variant="outline" className="flex-1 rounded-full"><a href={`sms:${trip.customer_phone}`}>SMS</a></Button>
            <Button asChild variant="outline" className="flex-1 rounded-full">
              <a target="_blank" rel="noreferrer" href={`https://wa.me/${trip.customer_phone.replace(/\D/g, "")}`}>WhatsApp</a>
            </Button>
          </div>
        </div>

        {trip.goods_photo_url && <GoodsPhoto path={trip.goods_photo_url} />}

        {canAct && (
          <div className="glass-card space-y-3 p-5">
            {isDispatcher && trip.payment_status === "unpaid" && (
              <Button onClick={markPaid} className="brand-gradient h-12 w-full rounded-xl font-bold">Customer has paid</Button>
            )}
            {next && trip.payment_status === "paid" && <Button onClick={() => update({ status: next.to })} className="brand-gradient h-12 w-full rounded-xl font-bold">{next.label}</Button>}
            {isDispatcher && trip.payment_status === "paid" && (
              <div>
                <p className="mb-1.5 text-sm text-muted-foreground">Assigned driver{trip.assigned_to ? `: ${nameOf(trip.assigned_to) ?? "—"}` : ""}</p>
                <Select value={trip.assigned_to ?? ""} onValueChange={(v) => update({ assigned_to: v, status: trip.status === "pending" ? "accepted" : trip.status })}>
                  <SelectTrigger><SelectValue placeholder="Assign a driver" /></SelectTrigger>
                  <SelectContent>{drivers.map((d) => <SelectItem key={d.id} value={d.id}>{d.full_name || "Driver"}</SelectItem>)}</SelectContent>
                </Select>
              </div>
            )}
            {!["completed", "cancelled"].includes(trip.status) && <CancelTrip trip={trip} onDone={refresh} />}
          </div>
        )}
      </div>

      <div className="glass-card flex h-[75vh] flex-col p-0">
        <div className="border-b border-border p-4">
          <h2 className="font-bold">Conversation</h2>
          <p className="text-xs text-muted-foreground">Messages with {trip.customer_name}, shared with the dispatch team.</p>
        </div>
        <div className="flex-1 space-y-2 overflow-y-auto p-4">
          {msgs.length === 0 && <p className="text-center text-sm text-muted-foreground">No messages yet.</p>}
          {msgs.map((m) => {
            const fromCustomer = m.sender_kind !== "staff";
            const me = m.sender_id === session.user.id && !fromCustomer;
            return (
              <div key={m.id} className={`flex ${fromCustomer ? "justify-start" : "justify-end"}`}>
                <div className={`max-w-[80%] rounded-2xl px-3.5 py-2 text-sm ${fromCustomer ? "bg-secondary" : "brand-gradient text-primary-foreground"}`}>
                  <p className="text-[10px] font-semibold opacity-70">
                    {fromCustomer ? `${trip.customer_name}${m.sender_kind === "customer_log" ? " (logged by crew)" : ""}` : me ? "You" : nameOf(m.sender_id) ?? "Crew"}
                  </p>
                  {m.body}
                  <p className="mt-0.5 text-[10px] opacity-60">{new Date(m.created_at).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}</p>
                </div>
              </div>
            );
          })}
          <div ref={endRef} />
        </div>
        {canAct && (
          <div className="border-t border-border p-3">
            <div className="mb-2 flex gap-1.5 overflow-x-auto">
              {QUICK.map((q) => (
                <button key={q} onClick={() => send(q)} className="shrink-0 rounded-full border border-border px-3 py-1 text-xs text-muted-foreground hover:text-foreground">{q}</button>
              ))}
            </div>
            <form onSubmit={(e) => { e.preventDefault(); send(text); }} className="flex gap-2">
              <Input value={text} onChange={(e) => setText(e.target.value)} placeholder="Message the customer…" className="rounded-full" />
              <Button type="button" variant="outline" className="rounded-full" title="Record what the customer said on a call"
                onClick={() => send(text, "customer_log")}>Log reply</Button>
              <Button className="brand-gradient rounded-full font-bold">Send</Button>
            </form>
          </div>
        )}
      </div>
    </div>
  );
}
