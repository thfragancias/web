-- TH Fragancias: panel de administración
-- Ejecutar una sola vez en Supabase > SQL Editor.
-- Después crear un usuario en Authentication > Users y agregar su UUID en admin_users.

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  meta text not null default '',
  price integer not null check (price >= 0),
  category text not null default '100ml' check (category in ('100ml','extractos')),
  image_url text,
  gender text not null default 'Unisex' check (gender in ('Masculino','Femenino','Unisex')),
  aromas text[] not null default '{}',
  seasons text[] not null default '{}',
  description text not null default '',
  top_notes text not null default '',
  heart_notes text not null default '',
  base_notes text not null default '',
  occasion text not null default '',
  format text not null default '',
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  in_stock boolean not null default true,
  duration text not null default '',
  sillage text not null default ''
);

-- Estado de disponibilidad para marcar productos agotados sin ocultarlos.
alter table public.products add column if not exists in_stock boolean not null default true;
alter table public.products add column if not exists duration text not null default '';
alter table public.products add column if not exists sillage text not null default '';

create unique index if not exists products_name_lower_unique
  on public.products (lower(name));

create or replace function public.is_th_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users
    where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_th_admin() from public;
grant execute on function public.is_th_admin() to authenticated;

alter table public.admin_users enable row level security;
revoke all on table public.admin_users from anon, authenticated;

alter table public.products enable row level security;
revoke all on table public.products from anon, authenticated;
grant select on table public.products to anon;
grant select, insert, update, delete on table public.products to authenticated;

drop policy if exists "Public can view active products" on public.products;
create policy "Public can view active products"
  on public.products for select to anon
  using (active = true);

drop policy if exists "Visitors and admins can view active products" on public.products;
create policy "Visitors and admins can view active products"
  on public.products for select to authenticated
  using (active = true or (select public.is_th_admin()));

drop policy if exists "Admins can insert products" on public.products;
create policy "Admins can insert products"
  on public.products for insert to authenticated
  with check ((select public.is_th_admin()));

drop policy if exists "Admins can update products" on public.products;
create policy "Admins can update products"
  on public.products for update to authenticated
  using ((select public.is_th_admin()))
  with check ((select public.is_th_admin()));

drop policy if exists "Admins can delete products" on public.products;
create policy "Admins can delete products"
  on public.products for delete to authenticated
  using ((select public.is_th_admin()));

-- Bucket público para que las fotos de los perfumes se vean en la tienda.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg','image/png','image/webp']::text[]
)
on conflict (id) do update
set public = true,
    file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg','image/png','image/webp']::text[];

drop policy if exists "Public can view TH product images" on storage.objects;
create policy "Public can view TH product images"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'product-images');

drop policy if exists "Admins can upload TH product images" on storage.objects;
create policy "Admins can upload TH product images"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'product-images' and (select public.is_th_admin()));

drop policy if exists "Admins can update TH product images" on storage.objects;
create policy "Admins can update TH product images"
  on storage.objects for update to authenticated
  using (bucket_id = 'product-images' and (select public.is_th_admin()))
  with check (bucket_id = 'product-images' and (select public.is_th_admin()));

drop policy if exists "Admins can delete TH product images" on storage.objects;
create policy "Admins can delete TH product images"
  on storage.objects for delete to authenticated
  using (bucket_id = 'product-images' and (select public.is_th_admin()));

-- Productos que hoy figuran en la web. Las fotos actuales se conservan como respaldo
-- en la página hasta que cargues una foto nueva desde el panel.
insert into public.products
  (name, meta, price, category, gender, aromas, seasons, description,
   top_notes, heart_notes, base_notes, occasion, format, sort_order, active)
select
  'Perfume G5 9pm Afnan',
  'Masculino · 100 ml',
  45000,
  '100ml',
  'Masculino',
  array['Dulce','Intenso'],
  array['Otoño','Invierno'],
  'Una fragancia dulce, frutal y especiada. La manzana y la canela se mezclan con un corazón floral y un fondo cálido de vainilla, ámbar y haba tonka.',
  'Bergamota, lavandín, canela y manzana.',
  'Muguete y flor de azahar.',
  'Pachulí, ámbar, vainilla y haba tonka.',
  'Salidas, encuentros y noches; especialmente en clima fresco.',
  '100 ml · Eau de Parfum',
  1,
  true
where not exists (select 1 from public.products where lower(name)=lower('Perfume G5 9pm Afnan'));

insert into public.products
  (name, meta, price, category, gender, aromas, seasons, description,
   top_notes, heart_notes, base_notes, occasion, format, sort_order, active)
select
  'Perfume G5 Odyssey Mandarin Sky',
  'Unisex · 100 ml',
  39900,
  '100ml',
  'Unisex',
  array['Fresco','Dulce'],
  array['Primavera','Verano'],
  'Un aroma cítrico y dulce que combina la frescura de la mandarina y la naranja con un corazón de caramelo y haba tonka. El fondo amaderado le aporta calidez.',
  'Salvia, mandarina, naranja y azafrán.',
  'Caramelo, haba tonka y tagetes.',
  'Vetiver, cedro y ambroxan.',
  'Uso diario, planes casuales y salidas; versátil durante todo el año.',
  '100 ml · Eau de Parfum',
  2,
  true
where not exists (select 1 from public.products where lower(name)=lower('Perfume G5 Odyssey Mandarin Sky'));
