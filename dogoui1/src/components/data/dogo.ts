export type Vehicle = {
  id: string;
  name: string;
  capacity: string;
  eta: string;
  base: number;
  perKm: number;
  icon: string;
  service: "ride" | "dispatch";
};

export const vehicles: Vehicle[] = [
  { id: "taxi", name: "Taxi (Car)", capacity: "Up to 4 passengers", eta: "5 min", base: 1800, perKm: 180, icon: "🚕", service: "ride" },
  { id: "tricycle", name: "Tricycle (Keke napep)", capacity: "Up to 3 passengers", eta: "9 min", base: 2100, perKm: 140, icon: "🛺", service: "ride" },
  { id: "bike", name: "Bike Dispatcher", capacity: "Parcels up to 15 kg", eta: "6 min", base: 1200, perKm: 95, icon: "🏍️", service: "dispatch" },
];

export const cities = [
  { name: "Lagos — Ikeja GRA", km: 0 },
  { name: "Lagos — Lekki Phase 1", km: 24 },
  { name: "Lagos — Yaba", km: 12 },
  { name: "Ibadan — Bodija", km: 128 },
  { name: "Abuja — Wuse 2", km: 712 },
  { name: "Port Harcourt — GRA Phase 2", km: 608 },
  { name: "Kano — Nassarawa", km: 986 },
  { name: "Benin City — Ugbowo", km: 312 },
];

export const paymentMethods = [
  { id: "card", label: "Fiat Card", hint: "Visa • Verve • Mastercard" },
  { id: "wallet", label: "DOGO Wallet", hint: "Balance ₦184,500" },
  { id: "usdc", label: "Crypto USDC", hint: "Polygon network" },
  { id: "usdt", label: "Crypto USDT", hint: "TRON network" },
] as const;
export type PaymentId = (typeof paymentMethods)[number]["id"];

export const milestones = ["Confirmed", "Picked Up", "In Transit", "Arriving", "Delivered"] as const;

export const naira = (n: number) =>
  "₦" + Math.round(n).toLocaleString("en-NG", { maximumFractionDigits: 0 });

export const vehicleLabel = (id: string) => vehicles.find((v) => v.id === id)?.name ?? "Previous vehicle";

export const vehicleIdFromName = (name?: string) =>
  !name ? "previous" : name.includes("Tricycle") ? "tricycle" : name.includes("Taxi") ? "taxi" : name.includes("Bike") ? "bike" : "previous";
