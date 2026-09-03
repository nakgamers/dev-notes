# GitHub Achievements: Catatan Perburuan Lencana

Ringkasan cara mendapatkan lencana profil GitHub (https://github.com/settings/achievements)
berdasarkan pengalaman langsung di akun @nakgamers, September 2026.

## Hasil yang terbukti

| Lencana | Syarat | Status |
|---|---|---|
| Quickdraw | Issue ditutup dalam 5 menit sejak dibuka | ✅ Muncul instan |
| YOLO Merge | PR di-merge tanpa review | ✅ Muncul instan |
| Pull Shark | 2 PR di-merge | ⏳ TIDAK muncul dari self-merge repo sendiri dalam 48 jam |
| Galaxy Brain | Jawaban Discussion ditandai *answer oleh orang lain* | ⏳ Jawaban sendiri TIDAK dihitung |
| Pair Extraordinaire | Co-author PR bersama akun nyata | ❌ Butuh akun kedua |

## Pitfall yang terbukti

1. **Self-merge di repo sendiri tidak cukup untuk Pull Shark** (atau sangat lambat).
   Tiga PR ke `nakgamers/dev-notes` yang di-merge sendiri tidak memunculkan lencana
   setelah 48+ jam. Kemungkinan perlu PR ke repo orang lain yang di-merge maintainer.

2. **Galaxy Brain tidak bisa dari self-answer.** Menandai jawaban sendiri sebagai
   "answer" di Discussion repo sendiri (`markDiscussionCommentAsAnswer`) memang
   mengubah status `isAnswered`, tetapi lencana tetap tidak diberikan. Syaratnya
   jawaban DITANDAI oleh orang lain.

3. **Quickdraw dan YOLO instan.** Keduanya muncul segera setelah aksi, tanpa jeda.

## Tips teknis

- Cek daftar lencana via scraping halaman profil:
  `curl -sL "https://github.com/USER?tab=achievements" | grep -oE 'achievements/[a-z0-9-]+'`
- Tandai jawaban sendiri (tidak berguna untuk Galaxy Brain, hanya uji alur):
  ```bash
  CID=$(gh api graphql -f query='mutation($d:ID!, $b:String!) { addDiscussionComment(input:{discussionId:$d, body:$b}) { comment { id } } }' -f d=ID_DISC -f b=ISI --jq '.data.addDiscussionComment.comment.id')
  gh api graphql -f query='mutation($c:ID!) { markDiscussionCommentAsAnswer(input:{id:$c}) { discussion { isAnswered } } }' -f c=$CID
  ```
- Cari Discussion Q&A yang belum terjawab di repo besar (syarat Galaxy Brain):
  ```bash
  gh api graphql -f query='query { repository(owner:"laravel", name:"framework") { discussions(first:40, orderBy:{field:UPDATED_AT, direction:DESC}) { nodes { number title isAnswered category { slug } comments { totalCount } } } } }' \
    --jq '.data.repository.discussions.nodes[] | select(.category.slug=="q-a" and (.isAnswered|not)) | "#\(.number) \(.title)"'
  ```
  Catatan: tidak semua repo mengaktifkan Discussions (CodeIgniter4: mati;
  Laravel framework: aktif, 4000+ diskusi).

## Kesimpulan

Lencana yang bisa "diusahakan sendiri" dalam sehari: Quickdraw, YOLO.
Yang butuh interaksi orang lain atau jeda: Pull Shark, Galaxy Brain, Pair Extraordinaire.
