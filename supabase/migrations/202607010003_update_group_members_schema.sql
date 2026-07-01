alter table public.group_members
  add column if not exists group_id uuid,
  add column if not exists user_id uuid,
  add column if not exists invited_by uuid,
  add column if not exists role text not null default 'member',
  add column if not exists status text not null default 'active',
  add column if not exists joined_at timestamptz,
  add column if not exists left_at timestamptz,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create unique index if not exists group_members_group_user_unique_idx
  on public.group_members(group_id, user_id);

create index if not exists group_members_group_id_idx
  on public.group_members(group_id);

create index if not exists group_members_user_id_idx
  on public.group_members(user_id);

create index if not exists group_members_status_idx
  on public.group_members(status);

alter table public.group_members enable row level security;

drop policy if exists "Users can view group members" on public.group_members;
drop policy if exists "Users can insert group members" on public.group_members;
drop policy if exists "Users can update group members" on public.group_members;
drop policy if exists "Users can delete group members" on public.group_members;

create policy "Users can view group members"
  on public.group_members
  for select
  to anon, authenticated
  using (true);

create policy "Users can insert group members"
  on public.group_members
  for insert
  to anon, authenticated
  with check (true);

create policy "Users can update group members"
  on public.group_members
  for update
  to anon, authenticated
  using (true)
  with check (true);

create policy "Users can delete group members"
  on public.group_members
  for delete
  to anon, authenticated
  using (true);
