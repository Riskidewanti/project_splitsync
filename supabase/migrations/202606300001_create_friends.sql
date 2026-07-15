create table if not exists public.friends (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  friend_id uuid not null,
  friend_request_id uuid,
  created_at timestamptz not null default now(),
  constraint friends_user_friend_unique unique (user_id, friend_id),
  constraint friends_no_self_friend check (user_id <> friend_id)
);

alter table public.friends
  add column if not exists user_id uuid,
  add column if not exists friend_id uuid,
  add column if not exists friend_request_id uuid,
  add column if not exists created_at timestamptz not null default now();

create unique index if not exists friends_user_friend_unique_idx
  on public.friends(user_id, friend_id);

create index if not exists friends_user_id_idx
  on public.friends(user_id);

create index if not exists friends_friend_id_idx
  on public.friends(friend_id);

create index if not exists friends_request_id_idx
  on public.friends(friend_request_id);

alter table public.friends enable row level security;

drop policy if exists "Users can view their friends" on public.friends;
drop policy if exists "Users can insert their friends" on public.friends;
drop policy if exists "Users can delete their friends" on public.friends;

create policy "Users can view their friends"
  on public.friends
  for select
  to anon, authenticated
  using (true);

create policy "Users can insert their friends"
  on public.friends
  for insert
  to anon, authenticated
  with check (true);

create policy "Users can delete their friends"
  on public.friends
  for delete
  to anon, authenticated
  using (true);

insert into public.friends (user_id, friend_id, friend_request_id, created_at)
select requester_id, addressee_id, id, coalesce(created_at, now())
from public.friend_requests
where status = 'accepted'
on conflict (user_id, friend_id) do nothing;

insert into public.friends (user_id, friend_id, friend_request_id, created_at)
select addressee_id, requester_id, id, coalesce(created_at, now())
from public.friend_requests
where status = 'accepted'
on conflict (user_id, friend_id) do nothing;
