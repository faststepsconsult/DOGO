import { Link } from "@tanstack/react-router";
import { Wallet, Moon, Sun } from "lucide-react";
import logo from "@/assets/dogo-logo.jpg.asset.json";
import { useAccount } from "@/lib/account-store";
import { useTheme } from "@/lib/theme-store";
import { Button } from "@/components/ui/button";

const nav = [
  { to: "/", label: "Home" },
  { to: "/track", label: "My trips" },
  { to: "/verify", label: "Verification" },
  { to: "/help", label: "Help" },
] as const;

export function AppHeader() {
  const { account } = useAccount();
  const { theme, toggleTheme } = useTheme();
  const initials = account ? account.name.slice(0, 2).toUpperCase() : null;
  const visibleNav = account?.role === "rider"
    ? [{ to: "/rider", label: "Rider dashboard" }, { to: "/verify", label: "Verify vehicle" }, { to: "/help", label: "Help" }, { to: "/account", label: "My profile" }] as const
    : nav;

  return (
    <header className="glass-card sticky top-0 z-40 rounded-none border-x-0 border-t-0 px-4 py-3">
      <div className="mx-auto grid max-w-6xl grid-cols-[minmax(0,1fr)_auto] items-center gap-3">
        <Link to="/" className="flex min-w-0 items-center gap-2.5">
          <img
            src={logo.url}
            alt="DOGO Rides"
            className="h-9 w-9 shrink-0 rounded-xl bg-white object-cover object-center p-0.5"
          />
          <span className="min-w-0">
            <span className="block truncate font-display text-base font-extrabold tracking-tight">DOGO</span>
            <span className="block truncate text-[10px] font-semibold uppercase tracking-[0.22em] text-gold">
              Rides
            </span>
          </span>
        </Link>

        <div className="flex items-center gap-2">
          <nav className="mr-1 hidden items-center gap-1 lg:flex">
            {visibleNav.map((n) => (
              <Link
                key={n.to}
                to={n.to}
                activeProps={{ className: "bg-secondary text-foreground" }}
                activeOptions={{ exact: true }}
                className="rounded-full px-3 py-1.5 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
              >
                {n.label}
              </Link>
            ))}
          </nav>
          <div className="hidden items-center gap-1.5 rounded-full border border-border bg-secondary/70 px-3 py-1.5 sm:flex">
            <Wallet className="h-4 w-4 text-gold" />
            <span className="text-sm font-semibold tabular-nums">₦184,500</span>
          </div>
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={toggleTheme}
            aria-label={`Switch to ${theme === "black" ? "White" : "Black"} mode`}
            title={`Switch to ${theme === "black" ? "White" : "Black"} mode`}
            className="h-9 shrink-0 rounded-full border-brand/35 bg-background/80 px-2.5 shadow-sm sm:px-3"
          >
            {theme === "black" ? <Moon className="text-brand-soft" /> : <Sun className="text-gold" />}
            <span className="hidden text-xs font-bold sm:inline">{theme === "black" ? "Black" : "White"}</span>
          </Button>
          {initials ? (
            <Link
              to="/account"
              aria-label="Your account"
              className="grid h-9 w-9 shrink-0 place-items-center rounded-full brand-gradient text-sm font-bold text-primary-foreground"
            >
              {initials}
            </Link>
          ) : (
            <Link
              to="/auth"
              className="shrink-0 rounded-full brand-gradient px-4 py-2 text-sm font-bold text-primary-foreground"
            >
              Sign in
            </Link>
          )}
        </div>
      </div>

      <nav className="-mx-1 mt-2.5 flex gap-1.5 overflow-x-auto px-1 lg:hidden">
        {visibleNav.map((n) => (
          <Link
            key={n.to}
            to={n.to}
            activeProps={{ className: "bg-secondary text-foreground" }}
            activeOptions={{ exact: true }}
            className="shrink-0 rounded-full border border-border px-3 py-1.5 text-xs font-semibold text-muted-foreground transition-colors hover:text-foreground"
          >
            {n.label}
          </Link>
        ))}
      </nav>
    </header>
  );
}
