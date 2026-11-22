#!/usr/bin/env bash
# Buat keystore rilis Android Topan dan isi 4 secret GitHub Actions secara otomatis.
#
# Jalankan SEKALI di komputer Anda (Linux, macOS, atau Git Bash di Windows):
#   bash scripts/setup_android_signing.sh
#
# Butuh: keytool (dari Java/JDK), openssl, dan GitHub CLI (gh) yang sudah login
# (`gh auth login`). Opsi:
#   --repo OWNER/NAME   repo tujuan (default: tarmizy/topan_tracking)
#   --dry-run           buat keystore saja, tanpa mengisi secret GitHub
set -euo pipefail

REPO="tarmizy/topan_tracking"
DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Opsi tidak dikenal: $1" >&2; exit 2 ;;
  esac
done

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ '$1' belum terpasang. $2" >&2; exit 1; }; }
need keytool "Pasang Java JDK 17 (mis. Temurin) lalu coba lagi."
need openssl "Pasang OpenSSL (sudah ada di Git Bash / macOS / Linux)."
if ! $DRY_RUN; then
  need gh "Pasang GitHub CLI: https://cli.github.com lalu jalankan 'gh auth login'."
  gh auth status >/dev/null 2>&1 || { echo "❌ Jalankan 'gh auth login' dulu." >&2; exit 1; }
fi

OUT="${TOPAN_SIGNING_DIR:-$HOME/topan-android-signing}"
KEYSTORE="$OUT/topan-release.jks"
ALIAS="topan"
mkdir -p "$OUT"
chmod 700 "$OUT"

if [[ -e "$KEYSTORE" ]]; then
  echo "❌ $KEYSTORE sudah ada. Keystore rilis tidak boleh diganti setelah aplikasi"
  echo "   diunggah ke Play Store. Hapus/pindahkan file itu hanya jika belum pernah dipakai."
  exit 1
fi

# Password acak 32 karakter (PKCS12: password keystore = password key).
PASSWORD="$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | cut -c1-32)"

echo "🔐 Membuat keystore rilis di $KEYSTORE ..."
keytool -genkeypair -noprompt \
  -keystore "$KEYSTORE" -storetype PKCS12 \
  -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PASSWORD" -keypass "$PASSWORD" \
  -dname "CN=Topan, O=Hydracore Digitech, L=Bogor, ST=Jawa Barat, C=ID" >/dev/null 2>&1
chmod 600 "$KEYSTORE"

umask 077
cat > "$OUT/CADANGAN-PENTING.txt" <<EOF
Keystore rilis Android Topan — SIMPAN DI TEMPAT AMAN (mis. password manager).
Jika hilang, update aplikasi di Play Store tidak bisa dikirim sampai Google
mereset kunci upload.

File keystore : $KEYSTORE
Alias         : $ALIAS
Password      : $PASSWORD   (password keystore = password key)
Dibuat        : $(date '+%Y-%m-%d %H:%M')

SHA-1 / SHA-256 sertifikat:
$(keytool -list -v -keystore "$KEYSTORE" -storepass "$PASSWORD" -alias "$ALIAS" 2>/dev/null | grep -E 'SHA1:|SHA256:')
EOF

if $DRY_RUN; then
  echo "✅ Keystore dibuat (dry-run, secret GitHub tidak diisi)."
else
  echo "⬆️  Mengisi secret di $REPO ..."
  openssl base64 -A -in "$KEYSTORE" | gh secret set TOPAN_ANDROID_KEYSTORE_B64 --repo "$REPO"
  printf '%s' "$PASSWORD" | gh secret set TOPAN_ANDROID_STORE_PASSWORD --repo "$REPO"
  printf '%s' "$ALIAS"    | gh secret set TOPAN_ANDROID_KEY_ALIAS --repo "$REPO"
  printf '%s' "$PASSWORD" | gh secret set TOPAN_ANDROID_KEY_PASSWORD --repo "$REPO"
  echo "✅ 4 secret terisi di $REPO."
fi

unset PASSWORD
echo
echo "📁 Cadangan tersimpan di: $OUT"
echo "   - topan-release.jks"
echo "   - CADANGAN-PENTING.txt (berisi password)"
echo "   Salin keduanya ke tempat aman (password manager / drive terenkripsi)."
echo
echo "Langkah berikutnya: GitHub > Actions > Build Android > Run workflow (branch main)."
