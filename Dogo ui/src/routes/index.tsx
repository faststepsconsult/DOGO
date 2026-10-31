import { createFileRoute, redirect } from "@tanstack/react-router";
import { supabase } from "@/integrations/supabase/client";

export const Route = createFileRoute("/")({
  ssr: false,
  head: () => ({
    meta: [
      { title: "DOGO Crew — Driver & dispatcher console" },
      { name: "description", content: "Staff-only console for DOGO Rides drivers and dispatchers." },
      { property: "og:title", content: "DOGO Crew — Driver & dispatcher console" },
      { property: "og:description", content: "Staff-only console for DOGO Rides drivers and dispatchers." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  beforeLoad: async () => {
    const { data } = await supabase.auth.getSession();
    throw redirect({ to: data.session ? "/board" : "/auth" });
  },
});
