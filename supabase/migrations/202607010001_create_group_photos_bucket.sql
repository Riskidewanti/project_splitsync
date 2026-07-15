insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'group-photos',
  'group-photos',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Group photos are publicly readable" on storage.objects;
drop policy if exists "Users can upload group photos" on storage.objects;
drop policy if exists "Users can update group photos" on storage.objects;
drop policy if exists "Users can delete group photos" on storage.objects;

create policy "Group photos are publicly readable"
  on storage.objects
  for select
  to anon, authenticated
  using (bucket_id = 'group-photos');

create policy "Users can upload group photos"
  on storage.objects
  for insert
  to anon, authenticated
  with check (bucket_id = 'group-photos');

create policy "Users can update group photos"
  on storage.objects
  for update
  to anon, authenticated
  using (bucket_id = 'group-photos')
  with check (bucket_id = 'group-photos');

create policy "Users can delete group photos"
  on storage.objects
  for delete
  to anon, authenticated
  using (bucket_id = 'group-photos');
