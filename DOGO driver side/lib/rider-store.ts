import { useSyncExternalStore } from "react";

/**
 * Simulated rider (customer) state for the demo — mirrors driver-store.
 * A tiny module store is enough: no backend, but state must survive tab
 * switches (Ride ↔ Activity ↔ Account).
 */

export type RiderSession =
  | "idle"
  | "picking"
  | "confirm"
  | "searching"
  | "arriving"
  | "onTrip"
  | "complete";

/** Coordinates in the fake map's 390 × 844 viewBox (same map as the driver app). */
export interface MapPoint {
  x: number;
  y: number;
}

/** The rider's fixed demo pickup point, on the x=195 / y=516 crossing. */
export const PICKUP: MapPoint = { x: 195, y: 516 };
export const PICKUP_NAME = "Bourdillon Road, Ikoyi";

export interface Destination {
  id: string;
  name: string;
  area: string;
  km: number;
  minutes: number;
  point: MapPoint;
  /** SVG route path from the pickup point to this destination. */
  route: string;
}

const routeTo = (point: MapPoint) =>
  point.x === PICKUP.x
    ? `M195 516 L195 ${point.y}`
    : `M195 516 L${point.x} 516 L${point.x} ${point.y}`;

export const destinations: Destination[] = [
  {
    id: "dest-landmark",
    name: "Landmark Beach",
    area: "Victoria Island",
    km: 6.4,
    minutes: 21,
    point: { x: 349, y: 260 },
    route: routeTo({ x: 349, y: 260 }),
  },
  {
    id: "dest-unilag",
    name: "UNILAG Second Gate",
    area: "Akoka, Yaba",
    km: 4.7,
    minutes: 16,
    point: { x: 272, y: 516 },
    route: routeTo({ x: 272, y: 516 }),
  },
  {
    id: "dest-ikeja-mall",
    name: "Ikeja City Mall",
    area: "Alausa, Ikeja",
    km: 12.8,
    minutes: 34,
    point: { x: 272, y: 130 },
    route: routeTo({ x: 272, y: 130 }),
  },
  {
    id: "dest-airport",
    name: "Murtala Muhammed Airport",
    area: "Ikeja",
    km: 14.2,
    minutes: 38,
    point: { x: 195, y: 130 },
    route: routeTo({ x: 195, y: 130 }),
  },
  {
    id: "dest-under-bridge",
    name: "Ikeja Under Bridge",
    area: "Ikeja",
    km: 9.6,
    minutes: 27,
    point: { x: 117, y: 260 },
    route: routeTo({ x: 117, y: 260 }),
  },
];

export interface RideClass {
  id: "bolt" | "comfort" | "xl";
  name: string;
  tagline: string;
  multiplier: number;
  etaMinutes: number;
}

export const rideClasses: RideClass[] = [
  { id: "bolt", name: "Bolt", tagline: "Everyday rides", multiplier: 1, etaMinutes: 4 },
  { id: "comfort", name: "Comfort", tagline: "Newer cars, extra legroom", multiplier: 1.35, etaMinutes: 6 },
  { id: "xl", name: "XL", tagline: "Room for up to 6", multiplier: 1.6, etaMinutes: 8 },
];

/** Base estimate: ₦900 flag + ₦230/km, scaled by the ride class. */
export function estimateFare(km: number, multiplier: number): number {
  return Math.round(((900 + km * 230) * multiplier) / 10) * 10;
}

export interface DriverMatch {
  name: string;
  initials: string;
  rating: number;
  car: string;
  plate: string;
}

export const driverPool: DriverMatch[] = [
  { name: "Tunde B.", initials: "TB", rating: 4.9, car: "Toyota Corolla", plate: "KJA 456 JK" },
  { name: "Ngozi E.", initials: "NE", rating: 4.8, car: "Kia Rio", plate: "LSD 812 AB" },
  { name: "Yusuf K.", initials: "YK", rating: 4.9, car: "Hyundai Elantra", plate: "AAA 233 FG" },
];

export interface RiderTrip {
  id: string;
  destination: string;
  area: string;
  rideClass: string;
  fare: number;
  km: number;
  minutes: number;
  driver: string;
  plate: string;
  completedAt: number;
}

interface RiderState {
  session: RiderSession;
  destinationId: string | null;
  rideClassId: RideClass["id"];
  trips: RiderTrip[];
}

// Server snapshot must be a stable constant: during SSR/hydration the store's
// live state is never read, so without this React throws "Missing
// getServerSnapshot" and the whole route falls back to client rendering.
const SERVER_STATE: RiderState = {
  session: "idle",
  destinationId: null,
  rideClassId: "bolt",
  trips: [],
};

let state: RiderState = SERVER_STATE;

const listeners = new Set<() => void>();

function emit() {
  listeners.forEach((listener) => listener());
}

export const riderStore = {
  get: () => state,
  setSession(session: RiderSession) {
    state = { ...state, session };
    emit();
  },
  pickDestination(id: string) {
    state = { ...state, destinationId: id, session: "confirm" };
    emit();
  },
  setRideClass(id: RideClass["id"]) {
    state = { ...state, rideClassId: id };
    emit();
  },
  completeTrip(trip: RiderTrip) {
    state = { ...state, trips: [trip, ...state.trips] };
    emit();
  },
  reset() {
    state = SERVER_STATE;
    emit();
  },
  subscribe(listener: () => void) {
    listeners.add(listener);
    return () => {
      listeners.delete(listener);
    };
  },
};

export function useRiderStore() {
  return useSyncExternalStore(riderStore.subscribe, riderStore.get, () => SERVER_STATE);
}
