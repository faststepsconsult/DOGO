import { useState } from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { BadgeCheck, Clock, FileUp, ShieldAlert, ShieldCheck, Upload } from "lucide-react";
import { AppHeader } from "@/components/dogo/AppHeader";
import { Button } from "@/components/ui/button";
import { useAccount, type VerificationStatus, type VerificationTier } from "@/lib/account-store";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/verify")({
  head: () => ({
    meta: [
      { title: "Account checks — DOGO Rides" },
      {
        name: "description",
        content:
          "Identity and driver checks for passengers and riders on DOGO Rides.",
      },
      { property: "og:title", content: "Account checks — DOGO Rides" },
      { property: "og:description", content: "Identity and vehicle checks for DOGO passengers and riders." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: VerifyPage,
});

const tiers: {
  id: VerificationTier;
  title: string;
  subtitle: string;
  audience: string;
  docs: string[];
}[] = [
  {
    id: "kyc",
    title: "KYC — Know Your Customer",
    subtitle: "Identity verification for every DOGO account",
    audience: "All users",
    docs: ["Government ID (NIN, Passport or Driver's Licence)", "Selfie liveness check", "Proof of address"],
  },
  {
    id: "kyv",
    title: "KYV — Know Your Vehicle",
    subtitle: "Vehicle papers for riders and drivers",
    audience: "Riders & Drivers",
    docs: ["Driver's licence", "Vehicle registration papers", "Roadworthiness certificate", "Insurance certificate"],
  },
  {
    id: "kyw",
    title: "KYW — Know Your Work",
    subtitle: "Work history, references and conduct record",
    audience: "Riders, Drivers & Agents",
    docs: ["Guarantor form", "Previous employer reference", "Police character report"],
  },
];

const statusMeta: Record<VerificationStatus, { label: string; icon: typeof ShieldAlert; cls: string }> = {
  unverified: { label: "Unverified", icon: ShieldAlert, cls: "bg-destructive/15 text-destructive" },
  review: { label: "In review", icon: Clock, cls: "bg-gold/20 text-gold" },
  verified: { label: "Verified", icon: BadgeCheck, cls: "bg-brand/20 text-brand" },
};

function VerifyPage() {
  const { account, setVerification } = useAccount();
  const [open, setOpen] = useState<VerificationTier | null>(null);
  const [uploaded, setUploaded] = useState<Record<string, boolean>>({});

  const verification = account?.verification;

  return (
    <div className="min-h-screen bg-background">
      <AppHeader />
      <main className="mx-auto max-w-3xl px-4 pb-20 pt-6">
        <div className="glass-card rounded-3xl p-5">
          <div className="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-3">
            <div className="min-w-0">
              <h1 className="font-display text-2xl font-extrabold">Verification Center</h1>
              <p className="mt-1 text-sm text-muted-foreground">
                 Check your identity and rider documents here.
              </p>
            </div>
            <ShieldCheck className="h-10 w-10 shrink-0 text-gold" />
          </div>
          {!account && (
            <Link
              to="/auth"
              className="mt-4 inline-flex items-center rounded-full brand-gradient px-4 py-2 text-sm font-bold text-primary-foreground"
            >
              Sign in to start verification
            </Link>
          )}
        </div>

        <div className="mt-4 space-y-3">
          {tiers.map((t) => {
            const status: VerificationStatus = verification?.[t.id] ?? "unverified";
            const meta = statusMeta[status];
            const isOpen = open === t.id;
            const done = t.docs.filter((d) => uploaded[t.id + d]).length;
            return (
              <div key={t.id} className="glass-card rounded-3xl p-4">
                <div className="grid grid-cols-[minmax(0,1fr)_auto] items-start gap-3">
                  <div className="min-w-0">
                    <p className="truncate font-display text-base font-bold">{t.title}</p>
                    <p className="mt-0.5 text-xs text-muted-foreground">{t.subtitle}</p>
                    <span className="mt-2 inline-block rounded-full bg-secondary/70 px-2.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-muted-foreground">
                      {t.audience}
                    </span>
                  </div>
                  <span className={cn("flex shrink-0 items-center gap-1.5 rounded-full px-3 py-1 text-xs font-bold", meta.cls)}>
                    <meta.icon className="h-3.5 w-3.5" /> {meta.label}
                  </span>
                </div>

                <div className="mt-3 flex flex-wrap items-center gap-2">
                  <Button
                    size="sm"
                    variant={isOpen ? "secondary" : "default"}
                    className="rounded-full"
                    onClick={() => setOpen(isOpen ? null : t.id)}
                    disabled={!account}
                  >
                    {status === "verified" ? "View documents" : isOpen ? "Hide" : "Start submission"}
                  </Button>
                  {status === "review" && (
                    <Button size="sm" variant="ghost" className="rounded-full" onClick={() => setVerification(t.id, "verified")}>
                      Simulate approval
                    </Button>
                  )}
                </div>

                {isOpen && account && (
                  <div className="animate-rise mt-4 space-y-2 border-t border-border pt-4">
                    {t.docs.map((d, i) => {
                      const key = t.id + d;
                      const up = !!uploaded[key];
                      return (
                        <button
                          key={d}
                          type="button"
                          onClick={() => setUploaded((p) => ({ ...p, [key]: !p[key] }))}
                          className={cn(
                            "grid w-full grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-3 rounded-2xl border p-3 text-left transition-colors",
                            up ? "border-brand bg-brand/10" : "border-border bg-secondary/40 hover:bg-secondary/70",
                          )}
                        >
                          <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-background/60 text-xs font-bold">
                            {i + 1}
                          </span>
                          <span className="min-w-0 truncate text-sm font-medium">{d}</span>
                          {up ? (
                            <BadgeCheck className="h-4 w-4 shrink-0 text-brand" />
                          ) : (
                            <FileUp className="h-4 w-4 shrink-0 text-muted-foreground" />
                          )}
                        </button>
                      );
                    })}
                    <div className="flex items-center justify-between gap-3 pt-1">
                      <p className="text-xs text-muted-foreground">
                        {done}/{t.docs.length} documents attached
                      </p>
                      <Button
                        size="sm"
                        className="rounded-full"
                        disabled={done < t.docs.length}
                        onClick={() => {
                          setVerification(t.id, "review");
                          setOpen(null);
                        }}
                      >
                        <Upload className="mr-1.5 h-4 w-4" /> Submit for review
                      </Button>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </main>
    </div>
  );
}
