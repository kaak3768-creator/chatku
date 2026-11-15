# ChatKu Tahap 2: Cara Memperbarui

Yang baru: **balas pesan**, **hapus pesan untuk semua**, **sematkan chat**, **hapus chat**,
**info kontak** (foto besar, info, username, tanggal bergabung), dan **foto profil**.

> **Penting:** jangan ganti `config.js` di repo kamu. File itu sudah berisi URL dan kunci Supabase yang benar.
> Di paket ini hanya ada dua file yang perlu dipakai: `supabase-tahap2.sql` dan `index.html`.

## Langkah 1: Jalankan SQL tahap 2 (di Supabase)

1. Buka project `chatdemo` di Supabase, lalu **SQL Editor > New query**.
2. Buka `supabase-tahap2.sql`, salin semua isinya, tempel, lalu klik **Run**.
3. Hasil yang benar: **Success. No rows returned**.
4. Cek: **Storage** di menu kiri sekarang harus punya bucket bernama **avatars**.

Jalankan **satu kali saja**. Kalau muncul error `already exists` atau `already defined`, berarti sudah pernah dijalankan.

## Langkah 2: Ganti `index.html` di GitHub

1. Buka repo `chatdemo` di GitHub, klik file `index.html`, lalu klik ikon **pensil** (Edit).
2. Klik di area kode, tekan **Ctrl+A** lalu **Delete** untuk mengosongkan isinya.
3. Buka `index.html` dari paket tahap 2 dengan Notepad, tekan **Ctrl+A**, **Ctrl+C**, lalu tempel di GitHub (**Ctrl+V**).
4. Klik **Commit changes...**, lalu **Commit changes** sekali lagi.

Atau: **Add file > Upload files**, seret `index.html` baru (nama harus sama persis, supaya menimpa yang lama), lalu Commit.

## Langkah 3: Tunggu dan tes

1. Tunggu 1 sampai 2 menit sampai deployment Vercel berstatus **Ready**.
2. Buka alamat Vercel dan tekan **Ctrl+F5**.
3. Daftar atau login seperti biasa. Akun dan chat lama tetap ada.

## Cara memakai fitur barunya

| Fitur | Caranya |
|---|---|
| **Balas pesan** | Klik **kanan** pada bubble (di HP: tekan lama), pilih **Balas**. Kutipan muncul di atas kolom ketik. |
| **Hapus pesan** | Klik kanan pada pesan milikmu, pilih **Hapus untuk semua**. Pesan jadi "Pesan ini telah dihapus" di kedua sisi. |
| **Salin pesan** | Klik kanan, pilih **Salin**. |
| **Sematkan chat** | Ikon 📌 di header chat, atau lewat info kontak. Chat tersemat naik ke paling atas. |
| **Hapus chat** | Ikon 🗑️ di header chat. Riwayat hanya hilang dari tampilanmu. Chat muncul lagi kalau ada pesan baru. |
| **Info kontak** | Klik **foto atau nama** di header chat. Klik foto besarnya untuk melihat layar penuh. |
| **Foto profil** | Klik avatar kamu di kiri atas, lalu klik tombol 📷. Pilih foto, geser dan zoom, lalu **Simpan foto**. |

## Masalah yang sering muncul

| Gejala | Solusi |
|---|---|
| "Gagal memuat kontak. Sudah menjalankan SQL tahap 2?" | Langkah 1 belum dijalankan atau gagal. Ulangi dan lihat pesan error-nya. |
| Foto gagal diunggah ("new row violates row-level security") | Bucket `avatars` atau policy storage belum terbuat. Jalankan ulang bagian nomor 4 di SQL tahap 2. |
| Foto tersimpan tapi tidak tampil | Muat ulang dengan Ctrl+F5. Foto hanya diterima dari alamat bucket `avatars` milik project ini. |
| Foto temanmu belum berubah di layarmu | Foto kontak diperbarui saat halaman dimuat ulang. |
| Fitur lama masih tampil | Browser masih menyimpan versi lama. Tekan Ctrl+F5. |

## Batasan tahap 2

- "Hapus untuk semua" bisa dilakukan kapan saja pada pesan milikmu sendiri.
- Foto profil disimpan di Supabase Storage. Cek batas penyimpanan gratisnya di halaman harga Supabase.
- Belum ada: reaksi, edit pesan, pesan berbintang, kirim foto di chat, grup, telepon suara, dan APK. Itu rencana tahap berikutnya.
