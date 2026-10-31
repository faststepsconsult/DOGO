<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

- Keep public vehicle choices in `src/data/dogo.ts` so booking and rider registration offer the same Bike and Tricycle options.
- BookingDialog takes a `service` prop: rides offer only `service: "ride"` vehicles (Taxi, Tricycle), dispatch offers only bike parcels; this keeps parcel fields out of the ride flow.
- Keep historical shipments intact when a vehicle is discontinued, but show a neutral legacy label through `vehicleLabel` so past orders remain accessible.
- Keep retired commerce and hub routes absent from the route tree; DOGO's public experience is passenger rides only.
- Keep the rider workspace at `/rider` gated by the rider account role, and keep sample offer decisions and trip progress local to that view; no demo action may imply live dispatch or payouts.
