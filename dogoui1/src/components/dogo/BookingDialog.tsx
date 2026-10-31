import { useMemo, useState } from "react";
import { useNavigate } from "@tanstack/react-router";
import { ArrowLeft, ArrowRight, Check, Clock3, CreditCard, MapPin } from "lucide-react";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { cities, naira, paymentMethods, vehicles } from "@/data/dogo";
import { useShipments } from "@/lib/shipment-store";
import { cn } from "@/lib/utils";

function cityKm(name: string) {
  return cities.find((city) => city.name === name)?.km;
}

function randomCode() {
  const characters = "ABCDEFGHJKLMNPQRSTUVWXYZ0123456789";
  return "DG-" + Array.from({ length: 6 }, () => characters[Math.floor(Math.random() * characters.length)]).join("");
}

export function BookingDialog({ open, onOpenChange, service = "ride" }: { open: boolean; onOpenChange: (value: boolean) => void; service?: "ride" | "dispatch" }) {
  const isDispatch = service === "dispatch";
  const options = vehicles.filter((v) => v.service === service);
  const navigate = useNavigate();
  const { addShipment } = useShipments();
  const [step, setStep] = useState(0);
  const [pickup, setPickup] = useState(cities[0]?.name ?? "");
  const [dropoff, setDropoff] = useState(cities[1]?.name ?? "");
  const [vehicleId, setVehicleId] = useState(service === "dispatch" ? "bike" : "taxi");
  const [payment, setPayment] = useState<string>("wallet");
  const [scheduled, setScheduled] = useState(false);
  const [scheduledDate, setScheduledDate] = useState("");
  const [scheduledTime, setScheduledTime] = useState("09:00");

  const distanceKm = useMemo(() => {
    const from = cityKm(pickup);
    const to = cityKm(dropoff);
    return from === undefined || to === undefined ? 18 : Math.max(5, Math.abs(to - from));
  }, [pickup, dropoff]);
  const [recipientName, setRecipientName] = useState("");
  const [recipientPhone, setRecipientPhone] = useState("");
  const [item, setItem] = useState("");
  const vehicle = options.find((v) => v.id === vehicleId) ?? options[0];
  if (!vehicle) return null;
  const fare = (v: (typeof vehicles)[number]) => Math.round((v.base + v.perKm * distanceKm) / 10) * 10;
  const price = fare(vehicle);
  const recipientOk = !isDispatch || (recipientName.trim().length > 1 && recipientPhone.replace(/\D/g, "").length >= 10);
  const canContinue = pickup.trim().length > 2 && dropoff.trim().length > 2 && pickup !== dropoff && (!scheduled || (scheduledDate !== "" && scheduledTime !== "" && new Date(`${scheduledDate}T${scheduledTime}`).getTime() > Date.now()));

  function confirm() {
    const selectedVehicle = vehicle;
    if (!canContinue || !recipientOk || !selectedVehicle) return;
    const code = randomCode();
    addShipment({
      code, pickup, dropoff, vehicleId: selectedVehicle.id, vehicleName: selectedVehicle.name, packageType: isDispatch ? "Parcel" : "Ride", weight: 0,
      recipientName: isDispatch ? recipientName : "", recipientPhone: isDispatch ? recipientPhone : "", itemLabel: isDispatch ? item || "Parcel" : undefined, payment: paymentMethods.find((method) => method.id === payment)?.label ?? "DOGO Wallet",
      price, distanceKm, pin: String(Math.floor(1000 + Math.random() * 9000)), createdAt: new Date().toISOString(),
      service: isDispatch ? "courier" : "ride", speed: scheduled ? "scheduled" : "casual",
      scheduledAt: scheduled ? `${scheduledDate} ${scheduledTime}` : undefined,
    });
    onOpenChange(false);
    setStep(0);
    navigate({ to: "/track/$code", params: { code } });
  }

  return (
    <Dialog open={open} onOpenChange={(value) => { onOpenChange(value); if (!value) setStep(0); }}>
      <DialogContent className="max-h-[92vh] w-[calc(100vw-1.5rem)] max-w-lg overflow-y-auto rounded-lg p-0">
        <div className="brand-gradient px-5 pb-5 pt-6 text-primary-foreground">
          <DialogHeader className="space-y-1 text-left">
            <DialogTitle className="text-xl font-extrabold">{isDispatch ? "Send a package" : "Book a ride"}</DialogTitle>
            <DialogDescription className="text-primary-foreground/80">{(isDispatch ? ["Where should it go?", "Your bike dispatcher", "Recipient and payment"] : ["Where are you going?", "Choose your ride", "Review your trip"])[step]}</DialogDescription>
          </DialogHeader>
          <div className="mt-5 flex gap-2" aria-label={`Step ${step + 1} of 3`}>
            {[0, 1, 2].map((index) => <span key={index} className={cn("h-1.5 flex-1 rounded-full", index <= step ? "bg-primary-foreground" : "bg-primary-foreground/25")} />)}
          </div>
        </div>

        <div className="space-y-5 px-5 pb-5">
          {step === 0 && <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="pickup"><MapPin className="mr-1 inline h-4 w-4 text-brand" /> Pick-up point</Label>
              <Input id="pickup" list="dogo-cities" value={pickup} onChange={(event) => setPickup(event.target.value)} className="h-12" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="dropoff"><MapPin className="mr-1 inline h-4 w-4 text-gold" /> Where to?</Label>
              <Input id="dropoff" list="dogo-cities" value={dropoff} onChange={(event) => setDropoff(event.target.value)} className="h-12" />
            </div>
            <datalist id="dogo-cities">{cities.map((city) => <option key={city.name} value={city.name} />)}</datalist>
            <div className="flex flex-wrap gap-2">
              {cities.slice(0, 4).map((city) => <Button key={city.name} type="button" variant="outline" onClick={() => setDropoff(city.name)} className="h-10 rounded-lg text-xs">{city.name}</Button>)}
            </div>
            <div className="flex gap-2">
              <Button type="button" variant={scheduled ? "outline" : "default"} onClick={() => setScheduled(false)} className="h-12 flex-1 rounded-lg">{isDispatch ? "Send now" : "Ride now"}</Button>
              <Button type="button" variant={scheduled ? "default" : "outline"} onClick={() => setScheduled(true)} className="h-12 flex-1 rounded-lg"><Clock3 className="h-4 w-4" /> Later</Button>
            </div>
            {scheduled && <div className="grid grid-cols-2 gap-3">
              <div className="space-y-2"><Label htmlFor="ride-date">Date</Label><Input id="ride-date" type="date" min={new Date().toLocaleDateString("en-CA")} value={scheduledDate} onChange={(event) => setScheduledDate(event.target.value)} /></div>
              <div className="space-y-2"><Label htmlFor="ride-time">Time</Label><Input id="ride-time" type="time" value={scheduledTime} onChange={(event) => setScheduledTime(event.target.value)} /></div>
            </div>}
            <p className="text-sm text-muted-foreground">Estimated distance: <span className="font-semibold text-foreground">{distanceKm} km</span></p>
          </div>}

          {step === 1 && <div className="space-y-3">
            {options.map((option) => <Button key={option.id} type="button" variant="outline" aria-pressed={vehicleId === option.id} onClick={() => setVehicleId(option.id)} className={cn("grid h-24 w-full grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-3 whitespace-normal rounded-lg border p-4 text-left", vehicleId === option.id ? "border-brand bg-brand/10" : "border-border bg-secondary/40")}>
              <span className="grid h-12 w-12 place-items-center rounded-lg bg-background text-2xl">{option.icon}</span>
              <span className="min-w-0"><span className="block font-bold leading-snug">{option.name}</span><span className="block text-xs text-muted-foreground">{option.capacity} · {option.eta} away</span></span>
              <span className="shrink-0 font-bold tabular-nums text-gold">{naira(fare(option))}</span>
            </Button>)}
            <p className="text-xs text-muted-foreground">Fares shown are estimates for your selected route.</p>
          </div>}

          {step === 2 && <div className="space-y-4">
            <div className="rounded-lg border border-border bg-secondary/40 p-4 text-sm">
              <p className="font-bold">{pickup} → {dropoff}</p>
              <p className="mt-1 text-muted-foreground">{vehicle.name} · {distanceKm} km {scheduled ? `· ${scheduledDate} at ${scheduledTime}` : "· Ride now"}</p>
              <p className="mt-3 border-t border-border pt-3 text-lg font-extrabold text-gold">Estimated fare: {naira(price)}</p>
            </div>
            {isDispatch && <div className="space-y-3">
              <div className="space-y-2"><Label htmlFor="item">What are you sending?</Label><Input id="item" placeholder="e.g. Documents, food, phone" value={item} onChange={(e) => setItem(e.target.value)} /></div>
              <div className="space-y-2"><Label htmlFor="rname">Recipient name</Label><Input id="rname" value={recipientName} onChange={(e) => setRecipientName(e.target.value)} /></div>
              <div className="space-y-2"><Label htmlFor="rphone">Recipient phone</Label><Input id="rphone" type="tel" placeholder="080..." value={recipientPhone} onChange={(e) => setRecipientPhone(e.target.value)} /></div>
            </div>}
            <Label className="flex items-center gap-2"><CreditCard className="h-4 w-4 text-brand" /> Payment method</Label>
            {paymentMethods.map((method) => <Button key={method.id} type="button" variant="outline" aria-pressed={payment === method.id} onClick={() => setPayment(method.id)} className={cn("flex h-14 w-full items-center justify-between rounded-lg border px-4 text-left", payment === method.id ? "border-brand bg-brand/10" : "border-border bg-secondary/40")}>
              <span className="min-w-0"><span className="block font-semibold">{method.label}</span><span className="block text-xs text-muted-foreground">{method.hint}</span></span>
              {payment === method.id && <Check className="h-4 w-4 shrink-0 text-brand" />}
            </Button>)}
          </div>}

          <div className="flex items-center justify-between gap-3 border-t border-border pt-4">
            <div className="min-w-0"><p className="text-xs text-muted-foreground">Estimated fare</p><p className="text-lg font-extrabold tabular-nums text-gold">{naira(price)}</p></div>
            <div className="flex gap-2">
              {step > 0 && <Button type="button" variant="secondary" onClick={() => setStep(step - 1)} className="h-12 rounded-lg"><ArrowLeft className="h-4 w-4" /> Back</Button>}
              {step < 2 ? <Button type="button" disabled={step === 0 && !canContinue} onClick={() => setStep(step + 1)} className="h-12 rounded-lg">Next <ArrowRight className="h-4 w-4" /></Button> : <Button type="button" disabled={!recipientOk} onClick={confirm} className="h-12 rounded-lg">{isDispatch ? "Send package" : "Confirm ride"}</Button>}
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
