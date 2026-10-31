import { Outlet, createFileRoute } from "@tanstack/react-router";

/**
 * Pathless layout for the rider (customer) app. It only mounts children —
 * each rider screen is its own route under /rider.
 */
export const Route = createFileRoute("/rider")({
  component: () => <Outlet />,
});
