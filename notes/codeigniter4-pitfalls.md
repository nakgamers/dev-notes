# Jebakan CodeIgniter 4 yang gagal tanpa pesan error

Empat hal berikut saya temukan saat membangun aplikasi undangan digital. Semuanya
membuat kode *terlihat* berjalan padahal data tidak pernah tersimpan.

## 1. Model tanpa `$table` menebak nama tabel dengan salah

CI4 tidak melakukan pluralisasi cerdas seperti Eloquent. Kalau `$table` tidak diisi,
query bisa mengarah ke tabel yang tidak ada dan Anda hanya mendapat hasil kosong.

```php
class InvitationModel extends Model
{
    protected $table = 'invitations';   // WAJIB, jangan diandalkan tebakan
    protected $primaryKey = 'id';
}
```

## 2. `$allowedFields` kosong membuat insert/update gagal DIAM-DIAM

Ini yang paling berbahaya: `insert()` mengembalikan nilai yang tampak sukses,
tidak ada exception, tetapi kolom yang tidak terdaftar dibuang begitu saja.

```php
protected $allowedFields = ['user_id', 'slug', 'title', 'event_date', 'status'];
```

Aturan praktis: setiap kali menambah kolom di migration, tambahkan juga di
`$allowedFields` pada commit yang sama.

## 3. `where('slug', ...)` menjadi ambigu ketika query memakai JOIN

Jika dua tabel yang di-join sama-sama punya kolom `slug`, MySQL menolak dengan
`Column 'slug' in where clause is ambiguous`. Selalu kualifikasikan nama kolom
begitu ada JOIN:

```php
$builder->join('users', 'users.id = invitations.user_id')
        ->where('invitations.slug', $slug);   // bukan where('slug', $slug)
```

## 4. Entity CI4 tidak mengimplementasikan `ArrayAccess`

Mengakses entity dengan sintaks array memicu fatal error, bukan warning:

```php
$inv = $model->find($id);
echo $inv['title'];   // Fatal error: Cannot use object of type ... as array
echo $inv->title;     // benar
```

Kalau memang butuh array, minta secara eksplisit lewat `$model->asArray()->find($id)`
atau panggil `$inv->toRawArray()`.

## Cara cepat memastikan penyebabnya

Aktifkan query log dan lihat SQL yang benar-benar dikirim:

```php
// setelah operasi yang dicurigai
echo $model->db->getLastQuery();
```

Kalau kolom yang Anda kirim tidak muncul di SQL tersebut, penyebabnya hampir pasti
poin nomor 2.
