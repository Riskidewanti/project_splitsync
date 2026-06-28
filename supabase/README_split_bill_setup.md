# Setup tabel `split_bill`

Error `Could not find the table 'public.split_bill'` berarti migration belum dijalankan di Supabase remote.

## Cara jalankan

1. Buka Supabase Dashboard.
2. Masuk ke project `mkdacnbbvjgekosdhevw`.
3. Buka **SQL Editor**.
4. Copy seluruh isi file:
   `supabase/migrations/202606250001_create_split_bill.sql`
5. Klik **Run**.

Setelah berhasil, restart aplikasi Flutter lalu coba tombol **Konfirmasi** lagi.

## Tabel yang dibuat

- `split_bill`
- `split_bill_items`
- `split_bill_participants`

Migration ini tidak menghapus atau mengubah tabel `settlements`.
