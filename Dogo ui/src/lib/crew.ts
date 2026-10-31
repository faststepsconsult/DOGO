import { createContext, useContext } from "react";
import type { Session } from "@supabase/supabase-js";

export type Role = "admin" | "dispatcher" | "driver";

export type CrewCtx = {
  session: Session;
  roles: Role[];
  isDispatcher: boolean;
  isDriver: boolean;
  name: string;
};

export const CrewContext = createContext<CrewCtx | null>(null);
export function useCrew() {
  const c = useContext(CrewContext);
  if (!c) throw new Error("useCrew outside crew area");
  return c;
}

export const SERVICE_LABEL = { taxi: "Taxi", keke: "Keke", bike: "Bike dispatch" } as const;
export const STATUS_LABEL = {
  pending: "Waiting",
  accepted: "Accepted",
  en_route: "On the way",
  picked_up: "Picked up",
  completed: "Completed",
  cancelled: "Cancelled",
} as const;
export const VERIFY_LABEL = {
  pending: "Under review",
  approved: "Verified",
  rejected: "Not approved",
} as const;
export const NEXT_STATUS: Record<string, { to: string; label: string } | undefined> = {
  accepted: { to: "en_route", label: "Start driving to pickup" },
  en_route: { to: "picked_up", label: "Customer picked up" },
  picked_up: { to: "completed", label: "Complete trip" },
};
export const naira = (n: number) => "₦" + n.toLocaleString("en-NG");

// Price per kilometre for each service (placeholder rates — confirm with DOGO).
export const RATE_PER_KM = { taxi: 250, keke: 150, bike: 200 } as const;
export const DRIVER_SHARE = 0.7;
export const PAYMENT_LABEL: Record<string, string> = { unpaid: "Awaiting payment", paid: "Paid", refunded: "Refunded" };
