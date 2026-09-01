# gh CLI di Windows

## Login tanpa menyerahkan password dan kode 2FA

Cara paling aman menghubungkan `gh` ke akun adalah **OAuth device flow**. Yang berpindah
tangan hanya kode enam karakter yang berlaku 15 menit, bukan kata sandi, dan kode 2FA
tidak pernah diminta karena otorisasi terjadi di sesi peramban yang sudah masuk.

Minta kode perangkat memakai client id resmi milik gh:

```bash
RESP=$(curl -s -X POST -H "Accept: application/json" \
  -d "client_id=178c6fc778ccc68e1d6a&scope=repo,read:org,gist,workflow" \
  https://github.com/login/device/code)
echo "$RESP" | tr ',' '\n' | grep user_code
```

Buka <https://github.com/login/device>, masukkan kode tersebut, lalu tukarkan
`device_code` menjadi token:

```bash
curl -s -X POST -H "Accept: application/json" \
  -d "client_id=178c6fc778ccc68e1d6a&device_code=${DEVICE_CODE}&grant_type=urn:ietf:params:oauth:grant-type:device_code" \
  https://github.com/login/oauth/access_token
```

Selama pengguna belum menekan Authorize, jawabannya `authorization_pending` — itu normal,
lanjutkan polling sesuai nilai `interval`. Bila muncul `slow_down`, tambah interval 5 detik.

Salurkan token langsung ke gh tanpa pernah mencetaknya ke layar:

```bash
printf '%s' "$TOKEN" | gh auth login --with-token
gh auth setup-git
gh auth status
```

## gh tidak ada di PATH setelah install lewat winget

Pemasangan `winget install --id GitHub.cli -e` menaruh berkasnya di
`C:\Program Files\GitHub CLI`, tetapi PATH shell yang sedang berjalan tidak diperbarui.
Tambahkan sendiri pada sesi tersebut:

```bash
export PATH="$PATH:/c/Program Files/GitHub CLI"
```

Agar permanen di Git Bash, masukkan baris yang sama ke `~/.bashrc`.

## Cakupan token yang diperlukan

| Pekerjaan | Cakupan |
|---|---|
| Baca/tulis repo, issue, pull request | `repo` |
| Menyunting berkas di `.github/workflows` | `workflow` |
| Repo milik organisasi | `read:org` |
| Membuat dan menjawab Discussions | `write:discussion` |
| Membaca daftar alamat surel akun | `user` |

Menambah cakupan setelah login tidak perlu mengulang seluruh proses:

```bash
gh auth refresh -h github.com -s write:discussion
```

## Discussions hanya bisa lewat GraphQL

REST API tidak menyediakan endpoint Discussions. Aktifkan fiturnya lewat REST,
lalu kerjakan sisanya di GraphQL:

```bash
gh api -X PATCH repos/OWNER/REPO -F has_discussions=true

gh api graphql -f query='
{
  repository(owner:"OWNER", name:"REPO") {
    id
    discussionCategories(first:20) { nodes { id slug isAnswerable } }
  }
}'
```

Hanya kategori dengan `isAnswerable: true` (bawaannya `q-a`) yang menerima
`markDiscussionCommentAsAnswer`. Mencoba menandai jawaban di kategori lain akan ditolak.
