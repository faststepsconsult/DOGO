create type public.verification_status as enum ('pending','approved','rejected');

create table public.rider_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  license_number text not null,
  nin text,
  license_photo text,
  status public.verification_status not null default 'pending',
  reject_reason text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null,
  service public.trip_service not null,
  model text not null,
  plate text not null,
  color text,
  photo text,
  status public.verification_status not null default 'pending',
  reject_reason text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

grant select, insert, update, delete on public.rider_verifications to authenticated;
grant all on public.rider_verifications to service_role;
grant select, insert, update, delete on public.vehicles to authenticated;
grant all on public.vehicles to service_role;

alter table public.rider_verifications enable row level security;
alter table public.vehicles enable row level security;

create policy "rider sees own or staff"
  on public.rider_verifications for select to authenticated
  using (user_id = auth.uid() or public.has_role(auth.uid(),'dispatcher') or public.has_role(auth.uid(),'admin'));
create policy "rider submits own"
  on public.rider_verifications for insert to authenticated
  with check (user_id = auth.uid());
create policy "staff reviews rider"
  on public.rider_verifications for update to authenticated
  using (public.has_role(auth.uid(),'dispatcher') or public.has_role(auth.uid(),'admin') or (user_id = auth.uid() and status = 'pending'));
create policy "rider withdraws pending"
  on public.rider_verifications for delete to authenticated
  using (user_id = auth.uid() and status = 'pending');

create policy "vehicle sees own or staff"
  on public.vehicles for select to authenticated
  using (owner_id = auth.uid() or public.has_role(auth.uid(),'dispatcher') or public.has_role(auth.uid(),'admin'));
create policy "vehicle submits own"
  on public.vehicles for insert to authenticated
  with check (owner_id = auth.uid());
create policy "staff reviews vehicle"
  on public.vehicles for update to authenticated
  using (public.has_role(auth.uid(),'dispatcher') or public.has_role(auth.uid(),'admin') or (owner_id = auth.uid() and status = 'pending'));
create policy "vehicle withdraws pending"
  on public.vehicles for delete to authenticated
  using (owner_id = auth.uid() and status = 'pending');

-- Riders must be verified and have an approved vehicle before claiming trips.
create or replace function public.accept_trip(_trip uuid)
 returns void language plpgsql security definer set search_path to 'public'
as $$
begin
  if not public.has_role(auth.uid(),'driver') then raise exception 'Only drivers can accept trips'; end if;
  if not exists (select 1 from public.rider_verifications where user_id = auth.uid() and status = 'approved') then
    raise exception 'Your rider verification has not been approved yet';
  end if;
  if not exists (select 1 from public.vehicles where owner_id = auth.uid() and status = 'approved') then
    raise exception 'You need an approved vehicle before accepting trips';
  end if;
  update public.trips set assigned_to = auth.uid(), status='accepted', updated_at=now()
    where id=_trip and status='pending' and assigned_to is null and payment_status='paid';
  if not found then raise exception 'Trip already taken or not yet paid'; end if;
end $$;

create policy "crew uploads verification docs" on storage.objects for insert to authenticated
  with check (bucket_id='verification-docs' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "owner reads verification docs" on storage.objects for select to authenticated
  using (bucket_id='verification-docs' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_staff(auth.uid())));