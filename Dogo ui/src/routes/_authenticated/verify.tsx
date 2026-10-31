import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useCrew, SERVICE_LABEL, VERIFY_LABEL, naira } from "@/lib/crew";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import type { Tables } from "@/integrations/supabase/types";

export const Route = createFileRoute("/_authenticated/verify")({
  head: () => ({
    meta: [
      { title: "Verification — DOGO Crew" },
      { name: "description", content: "Rider and vehicle verification for DOGO drivers." },
      { property: "og:title", content: "Verification — DOGO Crew" },
      { property: "og:description", content: "Rider and vehicle verification for DOGO drivers." },
    ],
  }),
  component: VerifyPage,
});

type RiderVerif = Tables<"rider_verifications">;
type Vehicle = Tables<"vehicles">;

function badge(status: string) {
  const cls = status === "approved" ? "border-success/40 bg-success/10 text-success"
    : status === "rejected" ? "border-destructive/40 bg-destructive/10 text-destructive"
    : "border-gold/40 bg-gold/10 text-gold";
  return (
    <span className={`rounded-full border px-2.5 py-0.5 text-xs font-bold ${cls}`}>
      {VERIFY_LABEL[status as keyof typeof VERIFY_LABEL] ?? status}
    </span>
  );
}

async function uploadDoc(uid: string, file: File, kind: string) {
  const ext = (file.name.split(".").pop() ?? "jpg").replace(/[^\w]/g, "") || "jpg";
  const path = `${uid}/${kind}-${crypto.randomUUID()}.${ext}`;
  const { error } = await supabase.storage.from("verification-docs").upload(path, file);
  if (error) throw error;
  return path;
}

function DocPhoto({ path, className = "h-40" }: { path: string; className?: string }) {
  const { data: url } = useQuery({
    queryKey: ["vdoc", path],
    queryFn: async () => (await supabase.storage.from("verification-docs").createSignedUrl(path, 3600)).data?.signedUrl ?? null,
  });
  if (!url) return <div className={`mt-2 rounded-xl bg-secondary ${className}`} />;
  return <img src={url} alt="Verification document" className={`mt-2 w-full rounded-xl object-cover ${className}`} />;
}

function VerifyPage() {
  const { session, isDispatcher, isDriver } = useCrew();
  const uid = session.user.id;
  const qc = useQueryClient();

  const { data: rider } = useQuery({
    queryKey: ["my-rider-verification", uid],
    queryFn: async () =>
      (await supabase.from("rider_verifications").select("*").eq("user_id", uid)
        .order("created_at", { ascending: false }).limit(1)).data?.[0] ?? null,
  });
  const { data: vehicles = [] } = useQuery({
    queryKey: ["my-vehicles", uid],
    queryFn: async () =>
      (await supabase.from("vehicles").select("*").eq("owner_id", uid)
        .order("created_at", { ascending: false })).data ?? [],
  });

  const riderOk = rider?.status === "approved";
  const vehicleOk = vehicles.some((v) => v.status === "approved");
  const verified = !isDriver || (riderOk && vehicleOk);

  return (
    <div className="mx-auto max-w-2xl space-y-4">
      <div>
        <h1 className="text-2xl font-extrabold">Verification</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {isDriver
            ? "Send your licence and vehicle details. A dispatcher approves them before you can accept trips."
            : "Your details as a crew member. Dispatchers can also review driver submissions below."}
        </p>
        {!verified && (
          <p className="mt-2 rounded-xl border border-gold/40 bg-gold/10 p-3 text-sm text-gold">
            {riderOk ? "Your licence is approved — add a vehicle to start accepting trips."
              : "You can browse the board, but trips stay locked until verification is approved."}
          </p>
        )}
      </div>

      <RiderSection rider={rider ?? null} onDone={() => qc.invalidateQueries({ queryKey: ["my-rider-verification", uid] })} />
      <VehicleSection vehicles={vehicles} onDone={() => qc.invalidateQueries({ queryKey: ["my-vehicles", uid] })} />

      {isDispatcher && <ReviewSection />}

      <p className="pt-2 text-center text-sm text-muted-foreground">
        Ready to work? <Link to="/board" className="text-primary hover:underline">Go to the trip board</Link>
      </p>
    </div>
  );
}

function RiderSection({ rider, onDone }: { rider: RiderVerif | null; onDone: () => void }) {
  const uid = useCrewUid();
  const [busy, setBusy] = useState(false);
  const [license, setLicense] = useState("");
  const [nin, setNin] = useState("");
  const [photo, setPhoto] = useState<File | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      const license_photo = photo ? await uploadDoc(uid, photo, "license") : null;
      const { error } = await supabase.from("rider_verifications").insert({
        user_id: uid, license_number: license, nin: nin || null, license_photo,
      });
      if (error) toast.error(error.message);
      else { toast.success("Sent for review — a dispatcher will check it"); onDone(); }
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Upload failed");
    }
    setBusy(false);
  }

  return (
    <div className="glass-card p-5">
      <div className="flex items-center justify-between">
        <h2 className="font-bold">Rider verification</h2>
        {rider && badge(rider.status)}
      </div>
      {rider?.status === "rejected" && rider.reject_reason && (
        <p className="mt-2 rounded-xl border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive">
          {rider.reject_reason} — fix it and send again.
        </p>
      )}
      {rider && rider.status !== "rejected" ? (
        <div className="mt-4 space-y-3 text-sm">
          <p><span className="text-muted-foreground">Licence number:</span> {rider.license_number}</p>
          {rider.nin && <p><span className="text-muted-foreground">NIN:</span> {rider.nin}</p>}
          {rider.license_photo && <DocPhoto path={rider.license_photo} />}
        </div>
      ) : (
        <form onSubmit={submit} className="mt-4 space-y-3">
          <div>
            <Label>Driver's licence number</Label>
            <Input required className="mt-1.5" value={license} onChange={(e) => setLicense(e.target.value)} placeholder="e.g. ABC12345NG" />
          </div>
          <div>
            <Label>NIN (optional)</Label>
            <Input className="mt-1.5" value={nin} onChange={(e) => setNin(e.target.value)} />
          </div>
          <div>
            <Label>Photo of the licence</Label>
            <Input required type="file" accept="image/*" capture="environment" className="mt-1.5"
              onChange={(e) => setPhoto(e.target.files?.[0] ?? null)} />
          </div>
          <Button disabled={busy} className="brand-gradient w-full rounded-xl font-bold">
            {busy ? "Uploading…" : "Send for review"}
          </Button>
        </form>
      )}
    </div>
  );
}

function VehicleSection({ vehicles, onDone }: { vehicles: Vehicle[]; onDone: () => void }) {
  const uid = useCrewUid();
  const [open, setOpen] = useState(false);

  return (
    <div className="glass-card p-5">
      <div className="flex items-center justify-between">
        <h2 className="font-bold">Vehicles</h2>
        <Button size="sm" className="brand-gradient rounded-full font-bold" onClick={() => setOpen(true)}>Add vehicle</Button>
      </div>
      {vehicles.length === 0 ? (
        <p className="mt-3 text-sm text-muted-foreground">No vehicle yet. Add the taxi, keke or bike you drive.</p>
      ) : (
        <div className="mt-4 space-y-3">
          {vehicles.map((v) => (
            <div key={v.id} className="rounded-xl border border-border bg-secondary/40 p-3">
              <div className="flex items-center justify-between gap-2">
                <p className="font-semibold">{v.model} · <span className="uppercase">{v.plate}</span></p>
                {badge(v.status)}
              </div>
              <p className="mt-1 text-xs text-muted-foreground">
                {SERVICE_LABEL[v.service]}{v.color ? ` · ${v.color}` : ""}
                {v.status === "rejected" && v.reject_reason ? ` · ${v.reject_reason}` : ""}
              </p>
              {v.photo && <DocPhoto path={v.photo} className="h-32" />}
            </div>
          ))}
        </div>
      )}
      <AddVehicle open={open} onOpenChange={setOpen} onDone={onDone} />
    </div>
  );
}

function AddVehicle({ open, onOpenChange, onDone }: { open: boolean; onOpenChange: (v: boolean) => void; onDone: () => void }) {
  const uid = useCrewUid();
  const [busy, setBusy] = useState(false);
  const [photo, setPhoto] = useState<File | null>(null);
  const [f, setF] = useState({ service: "taxi", model: "", plate: "", color: "" });
  const set = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement>) => setF({ ...f, [k]: e.target.value });

  async function save(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      const vphoto = photo ? await uploadDoc(uid, photo, "vehicle") : null;
      const { error } = await supabase.from("vehicles").insert({
        owner_id: uid, service: f.service as "taxi", model: f.model, plate: f.plate.toUpperCase(),
        color: f.color || null, photo: vphoto,
      });
      if (error) toast.error(error.message);
      else { toast.success("Vehicle sent for review"); onDone(); onOpenChange(false); setF({ service: "taxi", model: "", plate: "", color: "" }); }
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Upload failed");
    }
    setBusy(false);
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader><DialogTitle>Add vehicle</DialogTitle></DialogHeader>
        <form onSubmit={save} className="space-y-3">
          <div>
            <Label>Service</Label>
            <Select value={f.service} onValueChange={(v) => setF({ ...f, service: v })}>
              <SelectTrigger className="mt-1.5"><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="taxi">Taxi</SelectItem>
                <SelectItem value="keke">Keke</SelectItem>
                <SelectItem value="bike">Bike dispatch</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div><Label>Make & model</Label><Input required className="mt-1.5" placeholder="Toyota Corolla 2012" value={f.model} onChange={set("model")} /></div>
          <div><Label>Plate number</Label><Input required className="mt-1.5 uppercase" placeholder="LAG-123-AB" value={f.plate} onChange={set("plate")} /></div>
          <div><Label>Colour (optional)</Label><Input className="mt-1.5" value={f.color} onChange={set("color")} /></div>
          <div>
            <Label>Photo of the vehicle</Label>
            <Input required type="file" accept="image/*" capture="environment" className="mt-1.5"
              onChange={(e) => setPhoto(e.target.files?.[0] ?? null)} />
          </div>
          <Button disabled={busy} className="brand-gradient h-11 w-full rounded-xl font-bold">{busy ? "Saving…" : "Save vehicle"}</Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function ReviewSection() {
  const qc = useQueryClient();
  const { data: rows = [] } = useQuery({
    queryKey: ["review-riders"],
    refetchInterval: 30000,
    queryFn: async () => (await supabase.from("rider_verifications").select("*").order("created_at", { ascending: false })).data ?? [],
  });
  const { data: vehs = [] } = useQuery({
    queryKey: ["review-vehicles"],
    refetchInterval: 30000,
    queryFn: async () => (await supabase.from("vehicles").select("*").order("created_at", { ascending: false })).data ?? [],
  });
  const { data: members = [] } = useQuery({
    queryKey: ["members"],
    queryFn: async () => (await supabase.rpc("list_members")).data ?? [],
  });
  const nameOf = (id: string) => members.find((m) => m.id === id)?.full_name ?? "Crew member";

  const pending = [
    ...rows.filter((r) => r.status === "pending").map((r) => ({ kind: "rider" as const, id: r.id, user: r.user_id, row: r })),
    ...vehs.filter((v) => v.status === "pending").map((v) => ({ kind: "vehicle" as const, id: v.id, user: v.owner_id, row: v })),
  ];

  async function review(kind: "rider" | "vehicle", id: string, status: "approved" | "rejected", reason?: string) {
    const table = kind === "rider" ? "rider_verifications" : "vehicles";
    const { error } = await supabase.from(table).update({
      status, reject_reason: status === "rejected" ? reason ?? "Not approved" : null, reviewed_at: new Date().toISOString(),
    }).eq("id", id);
    if (error) toast.error(error.message);
    else { toast.success(status === "approved" ? "Approved" : "Rejected"); qc.invalidateQueries(); }
  }

  return (
    <div className="glass-card p-5">
      <h2 className="font-bold">Review queue</h2>
      <p className="mt-1 text-sm text-muted-foreground">Driver submissions waiting for a decision.</p>
      {pending.length === 0 ? (
        <p className="mt-3 text-sm text-muted-foreground">Nothing waiting right now.</p>
      ) : (
        <div className="mt-4 space-y-3">
          {pending.map((p) => (
            <div key={p.id} className="rounded-xl border border-border bg-secondary/40 p-3">
              <div className="flex items-center justify-between">
                <p className="font-semibold">{nameOf(p.user)}</p>
                <span className="rounded-full bg-gold/15 px-2.5 py-0.5 text-xs font-bold text-gold">
                  {p.kind === "rider" ? "Licence" : "Vehicle"}
                </span>
              </div>
              {p.kind === "rider" ? (
                <div className="mt-2 space-y-1 text-sm">
                  <p><span className="text-muted-foreground">Licence:</span> {p.row.license_number}{p.row.nin ? ` · NIN ${p.row.nin}` : ""}</p>
                  {p.row.license_photo && <DocPhoto path={p.row.license_photo} />}
                </div>
              ) : (
                <div className="mt-2 space-y-1 text-sm">
                  <p>{p.row.model} · <span className="uppercase">{p.row.plate}</span> · {SERVICE_LABEL[p.row.service]}</p>
                  {p.row.photo && <DocPhoto path={p.row.photo} />}
                </div>
              )}
              <div className="mt-3 flex gap-2">
                <Button size="sm" className="brand-gradient rounded-full font-bold" onClick={() => review(p.kind, p.id, "approved")}>Approve</Button>
                <RejectButton onReject={(reason) => review(p.kind, p.id, "rejected", reason)} />
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function RejectButton({ onReject }: { onReject: (reason: string) => void }) {
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState("");
  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button size="sm" variant="outline" className="rounded-full">Reject</Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader><DialogTitle>Reject submission</DialogTitle></DialogHeader>
        <Label>Reason shown to the driver</Label>
        <Input className="mt-1.5" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Photo is blurry, send again" />
        <Button variant="destructive" className="mt-2 w-full rounded-xl font-bold"
          onClick={() => { onReject(reason); setOpen(false); }}>Reject</Button>
      </DialogContent>
    </Dialog>
  );
}

function useCrewUid() {
  return useCrew().session.user.id;
}
