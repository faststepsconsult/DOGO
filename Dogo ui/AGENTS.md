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

## Architecture rules
- Staff-only app: all crew pages live under `src/routes/_authenticated/` (client-side session gate); access to data is enforced by RLS roles (`user_roles` + `has_role`), never in the UI alone.
- Roles: first signup becomes admin+dispatcher; dispatchers grant driver/dispatcher via the `set_member_role` RPC. Drivers claim trips only through the `accept_trip` RPC to avoid double-booking.
- Customer chat lives in `trip_messages` (`sender_kind`: customer | staff | customer_log) so the customer app can share the same backend.
