create table if not exists public.split_bill (
  id uuid primary key default gen_random_uuid(),
  expense_item_id uuid not null,
  user_id uuid,
  share_quantity numeric,
  share_percentage numeric,
  exact_amount numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_paid boolean not null default false,
  paid_at timestamptz,
  category text,
  currency text not null default 'IDR'
);

alter table public.split_bill
  add column if not exists expense_item_id uuid,
  add column if not exists user_id uuid,
  add column if not exists share_quantity numeric,
  add column if not exists share_percentage numeric,
  add column if not exists exact_amount numeric,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists is_paid boolean not null default false,
  add column if not exists paid_at timestamptz,
  add column if not exists category text,
  add column if not exists currency text not null default 'IDR';

alter table public.split_bill
  alter column expense_item_id set not null;

create index if not exists split_bill_expense_item_id_idx
  on public.split_bill(expense_item_id);

create index if not exists split_bill_user_id_idx
  on public.split_bill(user_id);

create index if not exists split_bill_is_paid_created_at_idx
  on public.split_bill(is_paid, created_at);

alter table public.split_bill enable row level security;

drop policy if exists "Users can view their split bills" on public.split_bill;
drop policy if exists "Users can create their split bills" on public.split_bill;
drop policy if exists "Users can update their split bills" on public.split_bill;
drop policy if exists "Users can view split bill rows" on public.split_bill;
drop policy if exists "Users can insert split bill rows" on public.split_bill;
drop policy if exists "Users can update their split bill rows" on public.split_bill;

create policy "Users can view split bill rows"
  on public.split_bill
  for select
  to anon, authenticated
  using (true);

create policy "Users can insert split bill rows"
  on public.split_bill
  for insert
  to anon, authenticated
  with check (true);

create policy "Users can update their split bill rows"
  on public.split_bill
  for update
  to anon, authenticated
  using (true)
  with check (true);
