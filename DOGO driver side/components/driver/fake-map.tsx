import { CarFront, MapPin, UserRound } from "lucide-react";
import type { MapPoint } from "@/lib/driver-store";

/**
 * Stylised offline map for the demo. The SVG uses `preserveAspectRatio="none"`
 * so the 390 × 844 viewBox stretches to fill any container — that keeps the
 * percent-positioned HTML markers and the SVG route path perfectly aligned.
 */

interface FakeMapProps {
  driver?: MapPoint | null;
  passenger?: MapPoint | null;
  destination?: MapPoint | null;
  /** SVG path in the 390 × 844 coordinate space. */
  route?: string | null;
}

const blocks: Array<[number, number, number, number]> = [
  [48, 8, 61, 114],
  [125, 8, 62, 114],
  [207, 8, 57, 114],
  [280, 8, 61, 114],
  [48, 138, 61, 114],
  [125, 138, 62, 114],
  [48, 268, 61, 112],
  [280, 268, 61, 112],
  [48, 398, 61, 110],
  [125, 398, 62, 110],
  [207, 398, 57, 110],
  [48, 524, 61, 112],
  [207, 524, 57, 112],
  [280, 524, 61, 112],
  [48, 652, 61, 184],
  [207, 652, 57, 184],
  [280, 652, 61, 184],
];

const labels: Array<{ text: string; x: number; y: number }> = [
  { text: "IKEJA", x: 316, y: 92 },
  { text: "MUSHIN", x: 196, y: 330 },
  { text: "YABA", x: 318, y: 470 },
  { text: "SURULERE", x: 110, y: 700 },
  { text: "LAGOS ISLAND", x: 316, y: 786 },
];

const toPercent = (p: MapPoint) => ({
  left: `${(p.x / 390) * 100}%`,
  top: `${(p.y / 844) * 100}%`,
});

export function FakeMap({ driver, passenger, destination, route }: FakeMapProps) {
  return (
    <div className="absolute inset-0 overflow-hidden bg-map-bg">
      <svg
        viewBox="0 0 390 844"
        preserveAspectRatio="none"
        className="absolute inset-0 h-full w-full"
        aria-hidden="true"
      >
        {/* City blocks */}
        {blocks.map(([x, y, w, h], i) => (
          <rect
            key={i}
            x={x}
            y={y}
            width={w}
            height={h}
            rx={10}
            fill="var(--map-block)"
          />
        ))}

        {/* Park + water */}
        <rect x={125} y={268} width={62} height={112} rx={10} fill="var(--map-park)" />
        <rect x={-16} y={652} width={56} height={192} fill="var(--map-water)" />

        {/* Minor roads */}
        {[40, 117, 272, 349].map((x) => (
          <line key={`v${x}`} x1={x} y1={0} x2={x} y2={844} stroke="var(--map-road)" strokeWidth={16} />
        ))}
        {[130, 260, 516, 644].map((y) => (
          <line key={`h${y}`} x1={0} y1={y} x2={390} y2={y} stroke="var(--map-road)" strokeWidth={16} />
        ))}

        {/* Major roads */}
        <line x1={195} y1={0} x2={195} y2={844} stroke="var(--map-road-major)" strokeWidth={24} />
        <line x1={0} y1={388} x2={390} y2={388} stroke="var(--map-road-major)" strokeWidth={24} />

        {/* District labels */}
        {labels.map((label) => (
          <text
            key={label.text}
            x={label.x}
            y={label.y}
            textAnchor="middle"
            fontSize={11}
            fontWeight={700}
            letterSpacing={2}
            fill="var(--map-label)"
          >
            {label.text}
          </text>
        ))}

        {/* Route: white casing + animated green line */}
        {route && (
          <g>
            <path
              d={route}
              fill="none"
              stroke="white"
              strokeOpacity={0.9}
              strokeWidth={9}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path
              d={route}
              fill="none"
              stroke="var(--primary)"
              strokeWidth={5}
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeDasharray="14 10"
              className="map-route-dash"
            />
          </g>
        )}
      </svg>

      {/* Destination pin */}
      {destination && (
        <div
          className="absolute z-[1] -translate-x-1/2 -translate-y-full transition-all duration-1000 ease-in-out"
          style={toPercent(destination)}
        >
          <div className="flex h-9 w-9 items-center justify-center rounded-full rounded-bl-none border-2 border-white bg-foreground text-background shadow-lg shadow-black/40">
            <MapPin className="h-4.5 w-4.5" />
          </div>
        </div>
      )}

      {/* Passenger marker */}
      {passenger && (
        <div
          className="absolute z-[2] -translate-x-1/2 -translate-y-1/2 transition-all duration-1000 ease-in-out"
          style={toPercent(passenger)}
        >
          <div className="relative flex h-9 w-9 items-center justify-center rounded-full border-2 border-white bg-card text-foreground shadow-lg shadow-black/40">
            <span className="absolute inset-0 animate-ping rounded-full bg-primary/40" />
            <UserRound className="h-4.5 w-4.5" />
          </div>
        </div>
      )}

      {/* Driver marker */}
      {driver && (
        <div
          className="absolute z-[3] -translate-x-1/2 -translate-y-1/2 transition-all duration-1000 ease-in-out"
          style={toPercent(driver)}
        >
          <div className="flex h-11 w-11 items-center justify-center rounded-2xl rounded-md border-2 border-white bg-primary text-primary-foreground shadow-lg shadow-black/40">
            <CarFront className="h-6 w-6" />
          </div>
        </div>
      )}
    </div>
  );
}
