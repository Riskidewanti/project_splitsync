alter table public.groups
  add column if not exists description text,
  add column if not exists photo_url text,
  add column if not exists created_by uuid,
  add column if not exists archived_at timestamptz,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create index if not exists groups_created_by_idx
  on public.groups(created_by);

create index if not exists groups_archived_at_idx
  on public.groups(archived_at);

alter table public.groups enable row level security;

drop policy if exists "Users can view groups" on public.groups;
drop policy if exists "Users can insert groups" on public.groups;
drop policy if exists "Users can update groups" on public.groups;
drop policy if exists "Users can delete groups" on public.groups;

create policy "Users can view groups"
  on public.groups
  for select
  to anon, authenticated
  using (true);

create policy "Users can insert groups"
  on public.groups
  for insert
  to anon, authenticated
  with check (true);

create policy "Users can update groups"
  on public.groups
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Users can delete groups"
  on public.groups
  for delete
  to anon, authenticated
  using (true);
