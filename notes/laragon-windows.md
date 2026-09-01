# Laragon di Windows: yang perlu diingat

## Apache tidak selalu di port 80

Di mesin saya Laragon menjalankan Apache di **port 1103** (plus SSL di 443), bukan 80.
Akibatnya `http://localhost/proyek` gagal, dan yang benar adalah `http://localhost:1103/proyek`.

Cek port yang sedang dipakai:

```bash
netstat -ano | grep LISTENING | grep -E ':(80|443|1103)\s'
```

Kalau port 80 direbut proses lain (IIS, Skype lama, atau `System` lewat HTTP.sys),
jangan matikan paksa — ubah saja port Laragon di `Menu > Apache > httpd.conf` pada
direktif `Listen`.

## Root web dan vhost

- Root web: `C:/laragon/www`
- Vhost dibuat otomatis di `C:/laragon/etc/apache2/sites-enabled/`

Setiap folder baru di `www` mendapat vhost sendiri setelah **Menu > Apache > Reload**.
Kalau muncul error SSL padahal tidak diminta, biasanya karena vhost `*:443` sudah dibuat
tapi sertifikat self-signed belum di-trust. Selama pengembangan cukup akses lewat `http://`
dengan port eksplisit, atau jalankan **Menu > Apache > SSL > Regenerate**.

## Menjalankan MySQL 8.4 secara manual

Kadang service MySQL bawaan Laragon menolak start tanpa pesan jelas. Menjalankannya
langsung di konsol menampilkan error sesungguhnya:

```bash
C:/laragon/bin/mysql/mysql-8.4.3-winx64/bin/mysqld.exe \
  --defaults-file=C:/laragon/bin/mysql/mysql-8.4.3-winx64/my.ini \
  --console
```

Biarkan jendela ini terbuka; baris pertama yang berwarna `[ERROR]` adalah penyebab akar.
Penyebab tersering: `datadir` menunjuk ke folder hasil versi MySQL lain, sehingga perlu
`--initialize-insecure` di direktori data yang baru dan kosong.

## Server bawaan PHP sebagai jalan pintas

Untuk proyek yang tidak butuh Apache (misalnya CodeIgniter 4 saat pengembangan),
`php -S` jauh lebih cepat dinyalakan dan tidak menyentuh konfigurasi Laragon:

```bash
php -S localhost:8123 -t public
```

Perhatikan bahwa `php -S` bersifat single-threaded: satu permintaan yang menggantung
akan memblokir seluruh aplikasi. Jangan pakai untuk mengukur performa.
