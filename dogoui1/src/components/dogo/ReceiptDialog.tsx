import { QRCodeSVG } from "qrcode.react";
import { Printer } from "lucide-react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { naira, vehicleLabel } from "@/data/dogo";
import type { Shipment } from "@/lib/shipment-store";

export function ReceiptDialog({
  shipment,
  open,
  onOpenChange,
}: {
  shipment: Shipment;
  open: boolean;
  onOpenChange: (v: boolean) => void;
}) {
  const rows: [string, string][] = [
    ["Trip code", shipment.code],
    ["Pickup", shipment.pickup],
    ["Destination", shipment.dropoff],
    ["Vehicle", vehicleLabel(shipment.vehicleId)],
    ...(shipment.service === "ride" ? [] : [
      ["Package", `${shipment.packageType} • ${shipment.weight} kg`],
      ["Recipient", `${shipment.recipientName || "—"} ${shipment.recipientPhone}`],
    ] as [string, string][]),
    ["Payment", shipment.payment],
    ["Distance", `${shipment.distanceKm} km`],
  ];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[92vh] w-[calc(100vw-1.5rem)] max-w-md overflow-y-auto rounded-3xl print-sheet">
        <DialogHeader className="text-left">
          <DialogTitle className="text-xl font-extrabold">Digital receipt</DialogTitle>
        </DialogHeader>

        <div className="flex items-center justify-between gap-3 rounded-2xl border border-border bg-secondary/40 p-3">
          <div className="min-w-0">
            <p className="text-xs uppercase tracking-widest text-muted-foreground">DOGO Rides</p>
            <p className="truncate font-display text-lg font-bold">{shipment.code}</p>
            <p className="text-xs text-muted-foreground">
              {new Date(shipment.createdAt).toLocaleString("en-NG")}
            </p>
          </div>
          <div className="shrink-0 rounded-xl border border-border bg-qr-surface p-2">
            <QRCodeSVG value={`DOGO|${shipment.code}|${shipment.pin}`} size={84} level="M" fgColor="var(--qr-ink)" />
          </div>
        </div>

        <dl className="mt-1 divide-y divide-border text-sm">
          {rows.map(([k, v]) => (
            <div key={k} className="grid grid-cols-[minmax(0,1fr)_auto] gap-3 py-2">
              <dt className="min-w-0 truncate text-muted-foreground">{k}</dt>
              <dd className="text-right font-medium">{v}</dd>
            </div>
          ))}
        </dl>

        <div className="flex items-center justify-between rounded-2xl border border-gold/40 bg-gold/10 p-3">
          <span className="font-semibold">Total paid</span>
          <span className="text-xl font-extrabold text-gold">{naira(shipment.price)}</span>
        </div>

        <Button onClick={() => window.print()} className="no-print w-full rounded-full">
          <Printer className="mr-1 h-4 w-4" /> Print receipt
        </Button>
      </DialogContent>
    </Dialog>
  );
}
