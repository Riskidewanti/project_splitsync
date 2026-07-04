create table if not exists public.personal_expense_debts (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  debtor_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric not null check (amount > 0),
  currency text not null default 'IDR',
  note text,
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'cancelled')),
  debtor_name text,
  debtor_handle text,
  debtor_avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  paid_at timestamptz,
  cancelled_at timestamptz
);

create index if not exists personal_expense_debts_requester_id_idx
  on public.personal_expense_debts(requester_id);

create index if not exists personal_expense_debts_debtor_id_idx
  on public.personal_expense_debts(debtor_id);

create index if not exists personal_expense_debts_status_created_at_idx
  on public.personal_expense_debts(status, created_at desc);

alter table public.personal_expense_debts enable row level security;

drop policy if exists "Users can view their personal debts"
  on public.personal_expense_debts;
drop policy if exists "Users can create personal debt requests"
  on public.personal_expense_debts;
drop policy if exists "Users can update their personal debts"
  on public.personal_expense_debts;

create policy "Users can view their personal debts"
  on public.personal_expense_debts
  for select
  to authenticated, anon
  using (true);

create policy "Users can create personal debt requests"
  on public.personal_expense_debts
  for insert
  to authenticated, anon
  with check (true);

create policy "Users can update their personal debts"
  on public.personal_expense_debts
  for update
  to authenticated, anon
  using (true)
  with check (true);
