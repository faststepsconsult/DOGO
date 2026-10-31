type Props = {
  /** 0 to 1 progress of the rider along the main route */
  progress?: number;
  className?: string;
};

/**
 * Stylized map backdrop rendered as SVG: road grid, blocks, water,
 * animated route line, moving rider marker and pulsing pins.
 */
export function DogoMap({ progress, className }: Props) {
  const routeD = "M 60 520 C 180 470, 200 340, 320 300 S 520 260, 620 140";

  return (
    <div className={className}>
      <svg viewBox="0 0 720 620" className="h-full w-full" preserveAspectRatio="xMidYMid slice" aria-hidden>
        <defs>
          <linearGradient id="mapbg" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="var(--map-background-start)" />
            <stop offset="100%" stopColor="var(--map-background-end)" />
          </linearGradient>
          <linearGradient id="routegrad" x1="0" y1="1" x2="1" y2="0">
            <stop offset="0%" stopColor="var(--brand)" />
            <stop offset="100%" stopColor="var(--gold)" />
          </linearGradient>
        </defs>

        <rect width="720" height="620" fill="url(#mapbg)" />

        {/* water */}
        <path
          d="M 0 560 C 140 540, 260 600, 400 580 C 540 560, 640 610, 720 585 L 720 620 L 0 620 Z"
          fill="var(--map-water)"
        />

        {/* city blocks */}
        {Array.from({ length: 26 }).map((_, i) => {
          const x = (i * 137) % 660;
          const y = (i * 211) % 520;
          const w = 40 + ((i * 37) % 70);
          const h = 30 + ((i * 53) % 60);
          return (
            <rect
              key={i}
              x={x}
              y={y}
              width={w}
              height={h}
              rx="8"
              fill="var(--map-block)"
              stroke="var(--map-block-border)"
            />
          );
        })}

        {/* roads */}
        {[70, 170, 270, 370, 470, 570].map((y) => (
          <line key={y} x1="0" y1={y} x2="720" y2={y} stroke="var(--map-road)" strokeWidth="10" />
        ))}
        {[80, 220, 360, 500, 640].map((x) => (
          <line key={x} x1={x} y1="0" x2={x} y2="620" stroke="var(--map-road)" strokeWidth="10" />
        ))}

        {/* route */}
        <path d={routeD} fill="none" stroke="color-mix(in oklab, var(--brand) 25%, transparent)" strokeWidth="12" strokeLinecap="round" />
        <path
          d={routeD}
          fill="none"
          stroke="url(#routegrad)"
          strokeWidth="5"
          strokeLinecap="round"
          strokeDasharray="18 14"
          className="animate-route"
        />

        {/* secondary routes */}
        <path
          d="M 640 520 C 540 500, 480 420, 380 430 S 200 470, 120 400"
          fill="none"
          stroke="color-mix(in oklab, var(--gold) 45%, transparent)"
          strokeWidth="3"
          strokeDasharray="10 12"
          className="animate-route"
        />

        {/* pins */}
        <g>
          <circle cx="60" cy="520" r="18" fill="color-mix(in oklab, var(--brand) 30%, transparent)" className="animate-ping-soft" />
          <circle cx="60" cy="520" r="8" fill="var(--brand)" stroke="var(--map-marker)" strokeWidth="2.5" />
          <circle cx="620" cy="140" r="18" fill="color-mix(in oklab, var(--gold) 30%, transparent)" className="animate-ping-soft" />
          <circle cx="620" cy="140" r="8" fill="var(--gold)" stroke="var(--map-marker)" strokeWidth="2.5" />
        </g>

         {/* other riders */}
        {[
          { x: 240, y: 210 },
          { x: 470, y: 360 },
          { x: 150, y: 400 },
        ].map((p) => (
          <circle key={`${p.x}-${p.y}`} cx={p.x} cy={p.y} r="5" fill="var(--map-courier)" />
        ))}

         {/* active rider marker */}
        <circle r="11" fill="var(--map-marker)" stroke="var(--brand)" strokeWidth="4">
          {progress === undefined ? (
            <animateMotion dur="9s" repeatCount="indefinite" path={routeD} rotate="auto" />
          ) : (
            <animateMotion
              dur="0.001s"
              fill="freeze"
              keyPoints={`${progress};${progress}`}
              keyTimes="0;1"
              calcMode="linear"
              path={routeD}
            />
          )}
        </circle>
      </svg>
    </div>
  );
}
