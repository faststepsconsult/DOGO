create type public.app_role as enum ('admin','dispatcher','driver');
create type public.trip_service as enum ('taxi','keke','bike');
create type public.trip_status as enum ('pending','accepted','en_route','picked_up','completed','cancelled');

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  role app_role not null,
  unique (user_id, role)
);
grant select on public.user_roles to authenticated;
grant all on public.user_roles to service_role;
alter table public.user_roles enable row level security;

create or replace function public.has_role(_user_id uuid, _role app_role)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles where user_id = _user_id and role = _role)
$$;
create or replace function public.is_staff(_user_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles where user_id = _user_id and role in ('dispatcher','driver','admin'))
$$;

create policy "own roles or dispatcher reads" on public.user_roles for select to authenticated
  using (user_id = auth.uid() or public.has_role(auth.uid(),'dispatcher'));

create table public.profiles (
  id uuid primary key,
  full_name text not null default '',
  phone text,
  vehicle text,
  created_at timestamptz not null default now()
);
grant select, insert, update on public.profiles to authenticated;
grant all on public.profiles to service_role;
alter table public.profiles enable row level security;
create policy "self or staff read profiles" on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_staff(auth.uid()));
create policy "self update profile" on public.profiles for update to authenticated using (id = auth.uid());
create policy "self insert profile" on public.profiles for insert to authenticated with check (id = auth.uid());

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)), new.raw_user_meta_data->>'phone');
  if not exists (select 1 from public.user_roles) then
    insert into public.user_roles (user_id, role) values (new.id,'admin'),(new.id,'dispatcher');
  end if;
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- dispatchers approve team members
create or replace function public.set_member_role(_user uuid, _role app_role, _grant boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.has_role(auth.uid(),'dispatcher') then raise exception 'Not allowed'; end if;
  if _role = 'admin' then raise exception 'Not allowed'; end if;
  if _grant then
    insert into public.user_roles(user_id, role) values (_user,_role) on conflict do nothing;
  else
    delete from public.user_roles where user_id=_user and role=_role;
  end if;
end $$;

create or replace function public.list_members()
returns table(id uuid, full_name text, phone text, vehicle text, roles text[], created_at timestamptz)
language sql stable security definer set search_path = public as $$
  select p.id, p.full_name, p.phone, p.vehicle,
    coalesce(array_agg(r.role::text) filter (where r.role is not null), '{}'), p.created_at
  from public.profiles p left join public.user_roles r on r.user_id = p.id
  where public.has_role(auth.uid(),'dispatcher')
  group by p.id order by p.created_at desc
$$;

create table public.trips (
  id uuid primary key default gen_random_uuid(),
  code text not null unique default upper(substr(md5(random()::text),1,6)),
  service trip_service not null,
  status trip_status not null default 'pending',
  customer_name text not null,
  customer_phone text not null,
  pickup text not null,
  dropoff text not null,
  fare integer not null default 0,
  notes text,
  assigned_to uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
grant select, insert, update on public.trips to authenticated;
grant all on public.trips to service_role;
alter table public.trips enable row level security;
create policy "dispatchers all trips" on public.trips for all to authenticated
  using (public.has_role(auth.uid(),'dispatcher')) with check (public.has_role(auth.uid(),'dispatcher'));
create policy "drivers see open and own" on public.trips for select to authenticated
  using (public.has_role(auth.uid(),'driver') and ((status='pending' and assigned_to is null) or assigned_to = auth.uid()));
create policy "drivers update own" on public.trips for update to authenticated
  using (public.has_role(auth.uid(),'driver') and assigned_to = auth.uid())
  with check (assigned_to = auth.uid());

create or replace function public.accept_trip(_trip uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.has_role(auth.uid(),'driver') then raise exception 'Only drivers can accept trips'; end if;
  update public.trips set assigned_to = auth.uid(), status='accepted', updated_at=now()
    where id=_trip and status='pending' and assigned_to is null;
  if not found then raise exception 'Trip already taken'; end if;
end $$;

create table public.trip_messages (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  sender_id uuid,
  sender_kind text not null default 'staff',
  body text not null,
  created_at timestamptz not null default now()
);
grant select, insert on public.trip_messages to authenticated;
grant all on public.trip_messages to service_role;
alter table public.trip_messages enable row level security;
create or replace function public.can_see_trip(_trip uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.trips t where t.id=_trip and (
    public.has_role(auth.uid(),'dispatcher') or (public.has_role(auth.uid(),'driver') and t.assigned_to=auth.uid())))
$$;
create policy "read messages" on public.trip_messages for select to authenticated using (public.can_see_trip(trip_id));
create policy "send messages" on public.trip_messages for insert to authenticated
  with check (public.can_see_trip(trip_id) and sender_id = auth.uid() and sender_kind in ('staff','customer_log'));

alter publication supabase_realtime add table public.trips;
alter publication supabase_realtime add table public.trip_messages;

insert into public.trips (service, customer_name, customer_phone, pickup, dropoff, fare, notes) values
 ('taxi','Amaka Obi','+2348031234567','Allen Avenue, Ikeja','Murtala Muhammed Airport T2',6500,'Has two suitcases'),
 ('keke','Tunde Bakare','+2348059876543','Yaba Bus Stop','UNILAG Main Gate',1200,null),
 ('bike','Chioma Eze','+2348092223344','Lekki Phase 1, Admiralty Way','Victoria Island, Adeola Odeku',2800,'Fragile package — documents'),
 ('taxi','Ibrahim Musa','+2348114445566','Wuse 2, Abuja','Jabi Lake Mall',3500,null);
insert into public.trip_messages (trip_id, sender_kind, body)
 select id, 'customer', 'Hello, please call when you are close.' from public.trips where customer_name='Amaka Obi';