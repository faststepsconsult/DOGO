import { Link, createFileRoute } from "@tanstack/react-router";
import {
  BadgeCheck,
  Car,
  ChevronRight,
  CircleHelp,
  FileCheck2,
  RotateCcw,
  Settings,
  ShieldCheck,
  Star,
  UserRound,
  Wallet2,
  type LucideIcon,
} from "lucide-react";
import avatar from "@/assets/driver-avatar.png";
import vehicle from "@/assets/vehicle-corolla.png";
import { DriverTabBar } from "@/components/driver/driver-tab-bar";
import { driverStore, useDriverStore } from "@/lib/driver-store";

export const Route = createFileRoute("/profile")({
  head: () => ({
    meta: [
      { title: "Bolt Driver · Profile" },
      {
        name: "description",
        content: "Driver profile, vehicle details and account settings in the demo app.",
      },
      { property: "og:title", content: "Bolt Driver · Profile" },
      {
        property: "og:description",
        content: "Driver profile, vehicle details and account settings in the demo app.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: ProfilePage,
});

interface MenuRow {
  Icon: LucideIcon;
  label: string;
  value?: string;
}

const menuRows: MenuRow[] = [
  { Icon: FileCheck2, label: "Documents", value: "Approved" },
  { Icon: Wallet2, label: "Payment method", value: "Cash & Card" },
  { Icon: ShieldCheck, label: "Safety centre" },
  { Icon: Settings, label: "Settings" },
  { Icon: CircleHelp, label: "Support" },
];

function ProfilePage() {
  const { trips } = useDriverStore();

  return (
    <div className="mx-auto flex h-dvh w-full max-w-[430px] flex-col overflow-hidden bg-background">
      <header className="px-5 pb-4 pt-7">
        <h1 className="text-2xl font-extrabold">Profile</h1>
      </header>

      <div className="flex-1 space-y-4 overflow-y-auto px-5 pb-24">
        <div className="rounded-3xl border border-border bg-card p-5">
          <div className="flex items-center gap-4">
            <img
              src={avatar}
              alt="Driver portrait"
              width={816}
              height={816}
              loading="lazy"
              className="h-16 w-16 rounded-full object-cover"
            />
            <div className="min-w-0">
              <p className="truncate text-lg font-extrabold">Abdulmutallib Alasah</p>
              <p className="text-sm text-muted-foreground">New driver · Joined Oct 2026</p>
            </div>
          </div>
          <div className="mt-4 grid grid-cols-3 divide-x divide-border rounded-2xl bg-muted py-3 text-center">
            <div>
              <p className="flex items-center justify-center gap-1 text-base font-extrabold">
                <Star className="h-4 w-4 fill-primary text-primary" />
                5.0
              </p>
              <p className="text-[11px] font-semibold text-muted-foreground">Rating</p>
            </div>
            <div>
              <p className="text-base font-extrabold">{trips.length}</p>
              <p className="text-[11px] font-semibold text-muted-foreground">Trips</p>
            </div>
            <div>
              <p className="flex items-center justify-center gap-1 text-base font-extrabold text-primary">
                <BadgeCheck className="h-4 w-4" />
                Verified
              </p>
              <p className="text-[11px] font-semibold text-muted-foreground">Account</p>
            </div>
          </div>
        </div>

        <div className="overflow-hidden rounded-3xl border border-border bg-card">
          <img
            src={vehicle}
            alt="White Toyota Corolla"
            width={1152}
            height={576}
            loading="lazy"
            className="h-32 w-full object-cover"
          />
          <div className="flex items-center gap-3 p-4">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-secondary">
              <Car className="h-5 w-5 text-muted-foreground" />
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-bold">Toyota Corolla 2018</p>
              <p className="text-xs text-muted-foreground">White · Sedan · 4 seats</p>
            </div>
            <BadgeCheck className="h-5 w-5 shrink-0 text-primary" />
          </div>
        </div>

        <ul className="overflow-hidden rounded-3xl border border-border bg-card">
          {menuRows.map(({ Icon, label, value }) => (
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
          to="/rider"
          className="flex w-full items-center gap-3 rounded-2xl border border-border bg-card px-4 py-3.5 text-sm font-bold text-primary"
        >
          <UserRound className="h-5 w-5" />
          <span className="flex-1">Try the Rider app</span>
          <ChevronRight className="h-4 w-4 shrink-0 text-muted-foreground" />
        </Link>

        <button
          type="button"
          onClick={() => driverStore.reset()}
          className="flex w-full items-center gap-3 rounded-2xl border border-border bg-card px-4 py-3.5 text-sm font-bold text-destructive"
        >
          <RotateCcw className="h-5 w-5" />
          Reset demo data
        </button>
      </div>

      <DriverTabBar />
    </div>
  );
}
