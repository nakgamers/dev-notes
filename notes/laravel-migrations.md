# Migration Laravel yang nyangkut

## `table already exists` padahal `migrate:status` bilang `No`

Ini terjadi ketika migration sudah berhasil membuat tabel, lalu proses berhenti
di tengah jalan (Ctrl+C, timeout, atau error di migration berikutnya) sebelum
Laravel mencatat baris ke tabel `migrations`. Akibatnya keadaan basis data dan
catatan migration tidak sinkron:

```
$ php artisan migrate
SQLSTATE[42S01]: Base table or view already exists: 1050 Table 'grades' already exists

$ php artisan migrate:status
| No | 2026_05_02_090000_create_grades_table |
```

Jangan menjalankan `migrate:fresh` di basis data yang sudah berisi data nyata —
itu menghapus semuanya. Perbaiki catatannya saja.

### Perbaikan: tambal baris di tabel `migrations`

Cari nomor batch tertinggi, lalu masukkan baris untuk migration yang sudah
benar-benar dijalankan:

```sql
SELECT MAX(batch) FROM migrations;

INSERT INTO migrations (migration, batch)
VALUES ('2026_05_02_090000_create_grades_table', 12);
```

Nama pada kolom `migration` harus sama persis dengan nama berkas tanpa `.php`.
Setelah itu `migrate:status` menampilkan `Yes` dan `migrate` bisa lanjut ke
migration berikutnya.

### Cara menghindarinya

Bungkus operasi skema yang berisiko di dalam transaksi bila mesin basis data
mendukung DDL transaksional, atau pecah satu migration besar menjadi beberapa
berkas kecil sehingga kegagalan di tengah hanya menyisakan satu langkah untuk
ditambal.

## Enum semester 1-6 untuk SMK tiga tahun

Sistem nilai bawaan biasanya mengasumsikan dua semester per tahun ajaran.
Untuk jenjang tiga tahun, menyimpan semester sebagai angka 1-6 jauh lebih
sederhana daripada memasangkan kolom `year` dan `semester`:

```php
$table->unsignedTinyInteger('semester');   // 1..6
$table->string('academic_year', 9);        // contoh: 2025/2026
```

Tahun ke berapa siswa berada dihitung dari nomor semester, bukan disimpan ulang:

```php
$tahunKe = (int) ceil($semester / 2);   // semester 5 dan 6 -> tahun ke-3
```

## `academic_year` sebagai nilai turunan

Menyuruh pengguna mengisi tahun ajaran di setiap baris nilai membuka peluang
salah ketik. Karena setiap nilai sudah terhubung ke siswa, tahun ajaran bisa
diambil dari relasi tersebut saat menyimpan:

```php
protected static function booted(): void
{
    static::saving(function (self $grade) {
        if (blank($grade->academic_year)) {
            $grade->academic_year = $grade->student->academic_year;
        }
    });
}
```

Dengan begitu satu-satunya sumber kebenaran adalah data siswa, dan laporan
transkrip tidak pernah menampilkan tahun ajaran yang saling bertentangan.
