import { useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { Check, MessageCircle, Phone, Mail } from "lucide-react";
import { AppHeader } from "@/components/dogo/AppHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useShipments } from "@/lib/shipment-store";

export const Route = createFileRoute("/help")({
  head: () => ({
    meta: [
      { title: "Help & support — DOGO Rides" },
      { name: "description", content: "Get help with a DOGO ride, package delivery, payment or vehicle verification." },
      { property: "og:title", content: "Help & support — DOGO Rides" },
      { property: "og:description", content: "Report a problem or contact DOGO customer service." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: HelpPage,
});

const topics = ["Ride problem", "Package problem", "Payment or refund", "Vehicle verification", "Safety concern", "Something else"];

const faqs = [
  { q: "How do I cancel a ride?", a: "Open My trips, choose the trip and contact your driver or report it here." },
  { q: "My package hasn't arrived", a: "Check the trip page for live status. If it's late, report it below with your trip code." },
  { q: "How do drivers get verified?", a: "Drivers upload their licence, vehicle papers and plate number on the Verification page." },
  { q: "I was charged the wrong amount", a: "Choose \"Payment or refund\" below and include your trip code." },
];

function HelpPage() {
  const { shipments } = useShipments();
  const [topic, setTopic] = useState(topics[0] ?? "");
  const [trip, setTrip] = useState("");
  const [message, setMessage] = useState("");
  const [caseId, setCaseId] = useState<string | null>(null);

  function submit() {
    if (message.trim().length < 5) return;
    setCaseId("CASE-DOGO-" + Math.floor(1000 + Math.random() * 9000));
  }

  return (
    <div className="min-h-screen bg-background">
      <AppHeader />
      <main className="mx-auto max-w-3xl space-y-6 px-4 pb-16 pt-6">
        <div>
          <h1 className="font-display text-2xl font-extrabold sm:text-3xl">How can we help?</h1>
          <p className="mt-1 text-sm text-muted-foreground">Our customer service team helps passengers, drivers and dispatchers.</p>
        </div>

        <div className="grid gap-3 sm:grid-cols-3">
          <Button asChild variant="outline" className="h-14 justify-start rounded-lg"><a href="tel:+2348000003646"><Phone className="h-5 w-5 text-brand" /> Call us</a></Button>
          <Button asChild variant="outline" className="h-14 justify-start rounded-lg"><a href="https://wa.me/2348000003646" target="_blank" rel="noreferrer"><MessageCircle className="h-5 w-5 text-success" /> WhatsApp</a></Button>
          <Button asChild variant="outline" className="h-14 justify-start rounded-lg"><a href="mailto:support@dogo.ng"><Mail className="h-5 w-5 text-gold" /> Email</a></Button>
        </div>

        <section className="glass-card rounded-lg p-5">
          <h2 className="font-display text-lg font-bold">Report a problem</h2>
          {caseId ? (
            <div className="mt-4 rounded-lg border border-success/40 bg-success/10 p-4">
              <p className="flex items-center gap-2 font-bold"><Check className="h-5 w-5 text-success" /> Report saved: {caseId}</p>
              <p className="mt-1 text-sm text-muted-foreground">Demo only — this report is not sent to a support team yet.</p>
              <Button type="button" variant="secondary" className="mt-3" onClick={() => { setCaseId(null); setMessage(""); }}>New report</Button>
            </div>
          ) : (
            <div className="mt-4 space-y-4">
              <div className="flex flex-wrap gap-2">
                {topics.map((t) => (
                  <Button key={t} type="button" size="sm" variant={topic === t ? "default" : "outline"} aria-pressed={topic === t} onClick={() => setTopic(t)} className="rounded-full">{t}</Button>
                ))}
              </div>
              <div className="space-y-2">
                <Label htmlFor="trip">Trip code (optional)</Label>
                <Input id="trip" list="trip-codes" placeholder="DG-XXXXXX" value={trip} onChange={(e) => setTrip(e.target.value)} />
                <datalist id="trip-codes">{shipments.map((s) => <option key={s.code} value={s.code} />)}</datalist>
              </div>
              <div className="space-y-2">
                <Label htmlFor="msg">What happened?</Label>
                <Textarea id="msg" rows={4} value={message} onChange={(e) => setMessage(e.target.value)} />
              </div>
              <Button type="button" disabled={message.trim().length < 5} onClick={submit} className="h-12 w-full rounded-lg">Send report</Button>
            </div>
          )}
        </section>

        <section>
          <h2 className="font-display text-lg font-bold">Common questions</h2>
          <div className="mt-3 space-y-2">
            {faqs.map((f) => (
              <details key={f.q} className="rounded-lg border border-border bg-secondary/40 p-4">
                <summary className="cursor-pointer font-semibold">{f.q}</summary>
                <p className="mt-2 text-sm text-muted-foreground">{f.a}</p>
              </details>
            ))}
          </div>
        </section>
      </main>
    </div>
  );
}
