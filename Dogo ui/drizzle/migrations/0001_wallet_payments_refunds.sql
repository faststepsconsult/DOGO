ALTER TABLE public.trips
  ADD COLUMN distance_km numeric NOT NULL DEFAULT 0,
  ADD COLUMN payment_status text NOT NULL DEFAULT 'unpaid',
  ADD COLUMN paid_at timestamptz,
  ADD COLUMN goods_photo_url text,
  ADD COLUMN distance_covered_km numeric,
  ADD COLUMN refund_amount integer,
  ADD COLUMN moved_at timestamptz;

CREATE OR REPLACE FUNCTION public.accept_trip(_trip uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
begin
  if not public.has_role(auth.uid(),'driver') then raise exception 'Only drivers can accept trips'; end if;
  update public.trips set assigned_to = auth.uid(), status='accepted', updated_at=now()
    where id=_trip and status='pending' and assigned_to is null and payment_status='paid';
  if not found then raise exception 'Trip already taken or not yet paid'; end if;
end $$;

CREATE OR REPLACE FUNCTION public.trips_guard()
 RETURNS trigger LANGUAGE plpgsql SET search_path TO 'public'
AS $$
begin
  if new.status in ('accepted','en_route','picked_up','completed') and new.payment_status <> 'paid' then
    raise exception 'Customer must pay before the service starts';
  end if;
  if new.status in ('en_route','picked_up') and new.moved_at is null then new.moved_at := now(); end if;
  return new;
end $$;
CREATE TRIGGER trips_guard BEFORE INSERT OR UPDATE ON public.trips FOR EACH ROW EXECUTE FUNCTION public.trips_guard();

CREATE OR REPLACE FUNCTION public.mark_trip_paid(_trip uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
begin
  if not public.has_role(auth.uid(),'dispatcher') then raise exception 'Only dispatchers'; end if;
  update public.trips set payment_status='paid', paid_at=now(), updated_at=now() where id=_trip and payment_status='unpaid';
end $$;

CREATE OR REPLACE FUNCTION public.cancel_trip(_trip uuid, _covered_km numeric)
 RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
declare t public.trips; r integer;
begin
  select * into t from public.trips where id=_trip;
  if not found then raise exception 'Trip not found'; end if;
  if not (public.has_role(auth.uid(),'dispatcher') or t.assigned_to = auth.uid()) then raise exception 'Not allowed'; end if;
  if t.status in ('completed','cancelled') then raise exception 'Trip already closed'; end if;
  if t.payment_status <> 'paid' then
    r := 0;
  elsif t.moved_at is null or coalesce(_covered_km,0) <= 0 then
    r := floor(t.fare * 0.9);
  elsif t.distance_km > 0 then
    r := greatest(0, floor(t.fare * (1 - least(_covered_km, t.distance_km) / t.distance_km)));
  else
    r := 0;
  end if;
  update public.trips set status='cancelled', distance_covered_km=coalesce(_covered_km,0), refund_amount=r,
    payment_status = case when payment_status='paid' then 'refunded' else payment_status end, updated_at=now()
    where id=_trip;
  return r;
end $$;

CREATE OR REPLACE FUNCTION public.my_wallet()
 RETURNS TABLE(balance integer, trips_done integer, today integer)
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$
  select
    coalesce(sum(floor((fare - coalesce(refund_amount,0)) * 0.7)),0)::int,
    (count(*) filter (where status='completed'))::int,
    coalesce(sum(floor((fare - coalesce(refund_amount,0)) * 0.7)) filter (where updated_at::date = now()::date),0)::int
  from public.trips
  where assigned_to = auth.uid()
    and (status='completed' or (status='cancelled' and moved_at is not null));
$$;

CREATE POLICY "staff upload goods photos" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id='goods-photos' AND public.is_staff(auth.uid()));
CREATE POLICY "staff read goods photos" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id='goods-photos' AND public.is_staff(auth.uid()));