import { useSyncExternalStore } from "react";

/**
 * Simulated driver state for the demo. A tiny module store is enough here:
 * there is no backend, but state must survive tab switches (Home ↔ Earnings).
 */

export type Session =
  | "offline"
  | "online"
  | "request"
  | "toPickup"
  | "atPickup"
  | "onTrip"
  | "complete";

/** Coordinates in the fake map's 390 × 844 viewBox. */
export interface MapPoint {
  x: number;
  y: number;
}

export interface RideRequest {
  id: string;
  passenger: string;
  initials: string;
  rating: number;
  pickupName: string;
  dropoffName: string;
  distanceKm: number;
  minutes: number;
  /** Gross fare the passenger pays; driver payout is 85%. */
  fare: number;
  payment: "Cash" | "Card";
  pickup: MapPoint;
  destination: MapPoint;
  routeToPickup: string;
  routeTrip: string;
}

export interface CompletedTrip {
  id: string;
  passenger: string;
  pickupName: string;
  dropoffName: string;
  /** Driver payout after commission. */
  fare: number;
  distanceKm: number;
  minutes: number;
  payment: "Cash" | "Card";
  completedAt: number;
}

export const COMMISSION = 0.15;

export const rideRequests: RideRequest[] = [
  {
    id: "req-yaba",
    passenger: "Chinedu O.",
    initials: "CO",
    rating: 4.8,
    pickupName: "Yaba Bus Stop, Yaba",
    dropoffName: "Ikeja City Mall, Alausa",
    distanceKm: 9.4,
    minutes: 26,
    fare: 4650,
    payment: "Cash",
    pickup: { x: 117, y: 260 },
    destination: { x: 272, y: 130 },
    routeToPickup: "M195 388 L195 260 L117 260",
    routeTrip: "M117 260 L195 260 L195 130 L272 130",
  },
  {
    id: "req-akoka",
    passenger: "Funmi A.",
    initials: "FA",
    rating: 4.9,
    pickupName: "UNILAG Second Gate, Akoka",
    dropoffName: "Landmark Beach, Victoria Island",
    distanceKm: 11.2,
    minutes: 31,
    fare: 6200,
    payment: "Card",
    pickup: { x: 272, y: 516 },
    destination: { x: 349, y: 130 },
    routeToPickup: "M195 388 L272 388 L272 516",
    routeTrip: "M272 516 L272 388 L349 388 L349 130",
  },
  {
    id: "req-ikeja",
    passenger: "Emeka N.",
    initials: "EN",
    rating: 4.7,
    pickupName: "Ikeja Under Bridge, Ikeja",
    dropoffName: "Murtala Muhammed Airport, Ikeja",
    distanceKm: 14.6,
    minutes: 38,
    fare: 8100,
    payment: "Cash",
    pickup: { x: 117, y: 516 },
    destination: { x: 195, y: 130 },
    routeToPickup: "M195 388 L117 388 L117 516",
    routeTrip: "M117 516 L117 260 L195 260 L195 130",
  },
];

interface DriverState {
  session: Session;
  trips: CompletedTrip[];
}

let state: DriverState = { session: "offline", trips: [] };

const listeners = new Set<() => void>();

function emit() {
  listeners.forEach((listener) => listener());
}

export const driverStore = {
  get: () => state,
  setSession(session: Session) {
    state = { ...state, session };
    emit();
  },
  completeTrip(trip: CompletedTrip) {
    state = { ...state, trips: [trip, ...state.trips] };
    emit();
  },
  reset() {
    state = { session: "offline", trips: [] };
    emit();
  },
  subscribe(listener: () => void) {
    listeners.add(listener);
    return () => {
      listeners.delete(listener);
    };
  },
};

// Server snapshot must be a stable constant: during SSR/hydration the store's
// live state is never read, so without this React throws "Missing
// getServerSnapshot" and the whole route falls back to client rendering.
const SERVER_STATE: DriverState = { session: "offline", trips: [] };

export function useDriverStore() {
  return useSyncExternalStore(driverStore.subscribe, driverStore.get, () => SERVER_STATE);
}

export function todaysPayouts(trips: CompletedTrip[]) {
  return trips.reduce((sum, trip) => sum + trip.fare, 0);
}

export const naira = (amount: number) => `₦${amount.toLocaleString("en-NG")}`;

export const clockTime = (timestamp: number) =>
  new Date(timestamp).toLocaleTimeString("en-NG", {
    hour: "2-digit",
    minute: "2-digit",
  });
