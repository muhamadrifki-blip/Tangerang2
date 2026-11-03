# Sales Daily Performance Management System

Aplikasi web Sales Daily Performance Management System yang dimigrasikan dari Claude Artifact ke **GitHub Pages + Supabase**.

## Fitur yang dipertahankan

- Daily Plan dan Daily Result
- Target aktivitas berdasarkan profil New Joiner / Junior / Senior / Custom
- Dashboard Manager dan Sales
- Team Performance, target vs realisasi, funnel akuisisi, tren, dan ranking
- Pipeline prospek dan next action
- Coaching Manager
- Historical Report dengan filter periode
- Export CSV dan Excel
- Import/format teks WhatsApp untuk Plan/Result
- Draft sementara di browser dan penyimpanan cloud ke Supabase
- Tampilan responsif desktop dan mobile

## 1. Siapkan Supabase

1. Buat project di [Supabase](https://supabase.com/).
2. Buka **SQL Editor**.
3. Jalankan seluruh isi `supabase/schema.sql`.
4. Buka **Project Settings → API**. Salin **Project URL** dan **anon/public key**.
5. Buka file `config.js`, lalu isi:

```js
window.SUPABASE_CONFIG = {
  url: "https://PROJECT_ID.supabase.co",
  anonKey: "SUPABASE_ANON_PUBLIC_KEY"
};
```

Gunakan anon/public key saja. **Jangan pernah memasukkan `service_role` key** ke file HTML/JS, GitHub, atau browser.

## 2. Buat akun Manager pertama

1. Jalankan aplikasi setelah konfigurasi, lalu pilih **Daftar akun**.
2. Daftarkan email Manager dan password.
3. Jika konfirmasi email Supabase aktif, buka email verifikasi terlebih dahulu.
4. Di Supabase → SQL Editor, jalankan query berikut dan ganti email dengan email Manager:

```sql
update public.profiles p
set role = 'manager', active = true, updated_at = now()
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('email-manager@perusahaan.com');

delete from public.signup_requests r
using auth.users u
where r.user_id = u.id
  and lower(u.email) = lower('email-manager@perusahaan.com');
```

5. Login ulang. Akun tersebut sekarang memiliki menu Manager.

## 3. Publikasikan ke GitHub Pages

1. Buat repository GitHub baru, misalnya `sales-daily-performance`.
2. Upload seluruh isi folder repository ini. Pastikan `index.html`, `config.js`, dan folder `supabase` berada di root repository.
3. Di GitHub buka **Settings → Pages**.
4. Pada **Build and deployment**, pilih **Deploy from a branch**.
5. Pilih branch `main` dan folder `/ (root)`, lalu klik **Save**.
6. Tunggu proses deployment selesai. Buka URL GitHub Pages yang diberikan GitHub.

## 4. Daftarkan Sales

1. Sales membuka URL GitHub Pages dan membuat akun melalui menu **Daftar akun**.
2. Profil Sales otomatis tercatat dengan status nonaktif.
3. Manager login, buka **User Management**, aktifkan Sales, lalu pilih profil dan isi area.
4. Sales login kembali / refresh halaman. Menu Daily Plan dan Daily Result akan tersedia.

## 5. Pengaturan Auth yang disarankan

Di Supabase → **Authentication → URL Configuration**:

- Set **Site URL** ke URL GitHub Pages, misalnya `https://USERNAME.github.io/sales-daily-performance/`.
- Tambahkan URL tersebut ke **Redirect URLs**.
- Untuk produksi, gunakan password yang kuat dan aktifkan email confirmation sesuai kebijakan perusahaan.

## Hak akses data

- Sales: hanya dapat membaca dan menulis dokumen dengan user ID miliknya.
- Manager aktif: dapat membaca data tim, mengelola profil Sales, dan menulis catatan coaching.
- Pembatasan dijalankan di database menggunakan Row Level Security (RLS), bukan hanya disembunyikan di tampilan.

## Catatan teknis

- Data utama disimpan di tabel `app_documents` sebagai JSONB agar struktur data aplikasi asli tetap kompatibel selama migrasi.
- Tabel `profiles` dan `signup_requests` mengatur identitas, role, aktivasi, profil target, dan area.
- Sinkronisasi tampilan Manager melakukan polling berkala (15 detik) untuk membaca perubahan data.
- Draft yang belum disubmit tetap disimpan sementara di browser Sales. Data yang sudah disubmit dikirim ke Supabase.
- Library XLSX dan Supabase JS dimuat dari CDN, sehingga browser membutuhkan koneksi internet.
- Jika repository bersifat publik, `config.js` akan terlihat publik. Hal itu normal untuk anon/public key selama RLS aktif dan policy SQL tidak diubah menjadi akses terbuka. Jangan masukkan rahasia lain ke file frontend.

## Struktur repository

```text
sales-dpms-github/
├── index.html
├── config.js
├── README.md
└── supabase/
    └── schema.sql
```
