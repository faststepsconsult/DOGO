import { Link, createFileRoute } from "@tanstack/react-router";
import {
  CarFront,
  ChevronRight,
  CircleHelp,
  CreditCard,
  RotateCcw,
  Settings,
  ShieldCheck,
  Star,
} from "lucide-react";
import { RiderTabBar } from "@/components/rider/rider-tab-bar";
import { riderStore, useRiderStore } from "@/lib/rider-store";

export const Route = createFileRoute("/rider/account")({
  head: () => ({
    meta: [
      { title: "Bolt · Account" },
      {
        name: "description",
        content: "Rider profile, payment methods and settings in the Bolt customer app demo.",
      },
      { property: "og:title", content: "Bolt · Account" },
      {
        property: "og:description",
        content: "Rider profile, payment methods and settings in the Bolt customer app demo.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: RiderAccount,
});

interface AccountRow {
  Icon: typeof Settings;
  label: string;
  value?: string;
}

const accountRows: AccountRow[] = [
  { Icon: CreditCard, label: "Payment methods", value: "Cash" },
  { Icon: ShieldCheck, label: "Safety centre" },
  { Icon: Settings, label: "Settings" },
  { Icon: CircleHelp, label: "Support" },
];

function RiderAccount() {
  const { trips } = useRiderStore();

  return (
    <div className="mx-auto flex h-dvh w-full max-w-[430px] flex-col overflow-hidden bg-background">
      <header className="px-5 pb-4 pt-7">
        <h1 className="text-2xl font-extrabold">Account</h1>
      </header>

      <div className="flex-1 space-y-4 overflow-y-auto px-5 pb-24">
        <div className="rounded-3xl border border-border bg-card p-5">
          <div className="flex items-center gap-4">
            <span className="flex h-16 w-16 items-center justify-center rounded-full bg-primary text-xl font-extrabold text-primary-foreground">
              AA
            </span>
            <div className="min-w-0">
              <p className="truncate text-lg font-extrabold">Abdulmutallib Alasah</p>
              <p className="text-sm text-muted-foreground">Rider · Joined Oct 2026</p>
            </div>
          </div>
          <div className="mt-4 grid grid-cols-2 divide-x divide-border rounded-2xl bg-muted py-3 text-center">
            <div>
              <p className="flex items-center justify-center gap-1 text-base font-extrabold">
                <Star className="h-4 w-4 fill-primary text-primary" />
                4.9
              </p>
              <p className="text-[11px] font-semibold text-muted-foreground">Rating</p>
            </div>
            <div>
              <p className="text-base font-extrabold">{trips.length}</p>
              <p className="text-[11px] font-semibold text-muted-foreground">Rides</p>
            </div>
          </div>
        </div>

        <ul className="overflow-hidden rounded-3xl border border-border bg-card">
          {accountRows.map(({ Icon, label, value }) => (
            <li key={label}>
              <button
                type="button"
                className="flex w-full items-center gap-3 px-4 py-3.5 text-left text-sm font-bold transition-colors hover:bg-accent [&:not(:last-child)]:border-b [&:not(:last-child)]:border-border"
              >
                <Icon className="h-5 w-5 shrink-0 text-muted-foreground" />
                <span className="flex-1">{label}</span>
                {value && (
                  <span className="text-xs font-semibold text-muted-foreground">{value}</span>
                )}
                <ChevronRight className="h-4 w-4 shrink-0 text-muted-foreground" />
              </button>
            </li>
          ))}
        </ul>

        <Link
          to="/"
          className="flex w-full items-center gap-3 rounded-2xl border border-border bg-card px-4 py-3.5 text-sm font-bold text-primary"
        >
          <CarFront className="h-5 w-5" />
          <span className="flex-1">Open the Driver app</span>
          <ChevronRight className="h-4 w-4 shrink-0 text-muted-foreground" />
        </Link>

        <button
          type="button"
          onClick={() => riderStore.reset()}
          className="flex w-full items-center gap-3 rounded-2xl border border-border bg-card px-4 py-3.5 text-sm font-bold text-destructive"
        >
          <RotateCcw className="h-5 w-5" />
          Reset demo data
        </button>
      </div>

      <RiderTabBar />
    </div>
  );
}
