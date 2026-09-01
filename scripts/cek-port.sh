#!/usr/bin/env bash
# cek-port.sh - menampilkan proses yang menahan port tertentu di Windows (Git Bash / MSYS)
#
# Dipakai saat Laragon atau php -S menolak start dengan pesan
# "address already in use" tetapi tidak menyebut siapa pemakainya.
#
# Pemakaian:
#   ./cek-port.sh 80 443 1103 3306 8123

set -uo pipefail

if [ "$#" -eq 0 ]; then
  echo "Pemakaian: $0 <port> [port...]" >&2
  echo "Contoh:    $0 80 443 1103 3306" >&2
  exit 64
fi

if ! command -v netstat >/dev/null 2>&1; then
  echo "netstat tidak tersedia di PATH." >&2
  exit 69
fi

nama_proses() {
  # tasklist mengeluarkan CSV; ambil kolom pertama dan buang tanda kutip.
  #
  # Catatan MSYS/Git Bash: pakai /FI dan /FO apa adanya. Penulisan //FI yang
  # biasa dipakai untuk menghindari konversi path justru ditolak tasklist bila
  # MSYS_NO_PATHCONV aktif, dengan pesan "Invalid argument/option - '//FI'".
  local pid="$1"
  tasklist /FI "PID eq ${pid}" /FO CSV /NH 2>/dev/null \
    | head -1 | cut -d',' -f1 | tr -d '"' | tr -d '\r'
}

status_keseluruhan=0

for port in "$@"; do
  if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo "Port tidak valid, dilewati: ${port}" >&2
    status_keseluruhan=1
    continue
  fi

  # cocokkan hanya alamat lokal yang diakhiri :<port> dan berstatus LISTENING
  baris=$(netstat -ano | awk -v p=":${port}" '
    $1 ~ /^(TCP|UDP)$/ && index($2, p) == length($2) - length(p) + 1 {
      if ($1 == "UDP" || $4 == "LISTENING") print
    }')

  if [ -z "$baris" ]; then
    printf 'port %-6s bebas\n' "$port"
    continue
  fi

  printf 'port %-6s DIPAKAI\n' "$port"
  while IFS= read -r b; do
    pid=$(echo "$b" | awk '{print $NF}')
    proto=$(echo "$b" | awk '{print $1}')
    lokal=$(echo "$b" | awk '{print $2}')
    if [ "$pid" = "0" ]; then
      # PID 0 berarti port dipegang kernel, biasanya lewat HTTP.sys
      printf '    %-4s %-24s pid=%-6s %s\n' "$proto" "$lokal" "$pid" \
        "kernel/HTTP.sys - lepaskan dengan: net stop http"
    else
      printf '    %-4s %-24s pid=%-6s %s\n' "$proto" "$lokal" "$pid" \
        "$(nama_proses "$pid")"
    fi
  done <<< "$baris"
done

exit "$status_keseluruhan"
