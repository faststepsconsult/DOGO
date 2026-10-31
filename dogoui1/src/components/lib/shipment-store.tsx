import { createContext, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from "react";

export type Shipment = {
  code: string;
  pickup: string;
  dropoff: string;
  vehicleId: string;
  vehicleName: string;
  packageType: string;
  weight: number;
  recipientName: string;
  recipientPhone: string;
  payment: string;
  price: number;
  distanceKm: number;
  pin: string;
  createdAt: string;
  speed?: "casual" | "express" | "scheduled";
  itemLabel?: string | undefined;
  extraStops?: string[] | undefined;
  scheduledAt?: string | undefined;
  service?: "courier" | "ride" | undefined;
};

type Ctx = {
  shipments: Shipment[];
  addShipment: (s: Shipment) => void;
  getShipment: (code: string) => Shipment | undefined;
};

const ShipmentContext = createContext<Ctx | null>(null);
const KEY = "dogo.shipments.v1";

const seed: Shipment[] = [
  {
    code: "DG-4821HK",
    pickup: "Lagos — Ikeja GRA",
    dropoff: "Lagos — Lekki Phase 1",
    vehicleId: "bike",
    vehicleName: "Bike Dispatcher",
    packageType: "Document",
    weight: 2,
    recipientName: "Chidinma Okoro",
    recipientPhone: "+234 802 441 9922",
    payment: "DOGO Wallet",
    price: 3480,
    distanceKm: 24,
    pin: "4193",
    createdAt: new Date().toISOString(),
  },
  {
    code: "DG-7710QP",
    pickup: "Lagos — Yaba",
    dropoff: "Ibadan — Bodija",
    vehicleId: "tricycle",
    vehicleName: "Tricycle (Keke napep)",
    packageType: "Electronics",
    weight: 46,
    recipientName: "Musa Bello",
    recipientPhone: "+234 703 118 4470",
    payment: "Crypto USDT",
    price: 38680,
    distanceKm: 128,
    pin: "8025",
    createdAt: new Date().toISOString(),
  },
];

export function ShipmentProvider({ children }: { children: ReactNode }) {
  const [shipments, setShipments] = useState<Shipment[]>(seed);
  const shipmentsRef = useRef<Shipment[]>(seed);

  useEffect(() => {
    try {
      const raw = localStorage.getItem(KEY);
      if (raw) {
        shipmentsRef.current = JSON.parse(raw) as Shipment[];
        setShipments(shipmentsRef.current);
      }
    } catch {
      /* ignore */
    }
  }, []);

  const value = useMemo<Ctx>(
    () => ({
      shipments,
      addShipment: (s) => {
        const next = [s, ...shipmentsRef.current];
        shipmentsRef.current = next;
        try {
          localStorage.setItem(KEY, JSON.stringify(next));
        } catch {
          /* ignore */
        }
        setShipments(next);
      },
      getShipment: (code) => shipments.find((s) => s.code === code),
    }),
    [shipments],
  );

  return <ShipmentContext.Provider value={value}>{children}</ShipmentContext.Provider>;
}

export function useShipments() {
  const ctx = useContext(ShipmentContext);
  if (!ctx) throw new Error("useShipments must be used inside ShipmentProvider");
  return ctx;
}
