import { Link } from "@tanstack/react-router";
import { House, UserRound, Wallet } from "lucide-react";

const tabs = [
  { to: "/", label: "Home", Icon: House },
  { to: "/earnings", label: "Earnings", Icon: Wallet },
  { to: "/profile", label: "Profile", Icon: UserRound },
] as const;

export function DriverTabBar() {
  return (
    <nav className="absolute inset-x-0 bottom-0 z-20 flex border-t border-border bg-card/95 pb-[env(safe-area-inset-bottom)] backdrop-blur-sm">
      {tabs.map(({ to, label, Icon }) => (
        <Link
          key={to}
          to={to}
          activeOptions={{ exact: true }}
          className="flex flex-1 flex-col items-center gap-0.5 py-2.5 text-[11px] font-bold text-muted-foreground transition-colors data-[status=active]:text-primary"
        >
          <Icon className="h-5 w-5" />
          {label}
        </Link>
      ))}
    </nav>
  );
}
