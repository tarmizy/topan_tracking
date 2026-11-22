# Rilis APK ke Google Drive

Workflow **Build Android APK** tetap membuat APK uji coba saat ada push ke `build/android-apk`. Saat tag seperti `android-v1.0.1` didorong, workflow menggunakan keystore rilis, memverifikasi tanda tangan, lalu memperbarui file Drive yang sama. Nomor build Android mengikuti nomor run GitHub Actions.

## Sambungkan Google Drive sekali

1. Di [Google Cloud Console](https://console.cloud.google.com/), pilih project, aktifkan **Google Drive API**, lalu buat **OAuth client ID** dengan tipe **Desktop app**. Unduh file JSON ke luar repo. Untuk akun Gmail pribadi, gunakan audience **External** dan ubah publishing status ke **In production** sebelum memberi izin. Pada status **Testing**, refresh token untuk Drive kedaluwarsa setelah tujuh hari. [Dokumentasi Google](https://developers.google.com/identity/protocols/oauth2#expiration)
2. Pada komputer yang memiliki Python 3.11 atau lebih baru dan GitHub CLI, jalankan perintah berikut dari checkout branch `build/android-apk`. Ganti lokasi kedua file dengan lokasi JSON OAuth dan APK awal yang sah.

```bash
gh auth login --hostname github.com
python3 -m venv ../topan-drive-venv
. ../topan-drive-venv/bin/activate
python -m pip install google-api-python-client==2.202.0 google-auth-oauthlib==1.5.0
python scripts/drive_release.py setup \
  --client-secrets ../client_secret.json \
  --apk ../topan-tracking-login.apk \
  --repo tarmizy/topan_tracking
```

Skrip meminta izin **drive.file**, membuat atau menemukan kembali file `topan-tracking.apk` yang dibuat untuk repo ini, lalu mengatur secret `TOPAN_DRIVE_OAUTH` dan variable `TOPAN_DRIVE_FILE_ID` di GitHub. Simpan OAuth client yang sama untuk setup ulang agar akses ke file dan link yang sama tetap berlaku.

Untuk unduhan tanpa login, buka file dari tautan yang dicetak skrip, lalu pilih **Bagikan → Akses umum → Siapa saja yang memiliki link → Pelihat**. Siapa pun yang mendapat tautan bisa mengunduh APK. Salin tautan dari Drive untuk QR code. Workflow hanya memperbarui isi file Drive sehingga pengaturan akses dan tautannya tetap berlaku.

## Siapkan tanda tangan Android sekali

Gunakan keystore rilis yang sudah ada jika tersedia. Jika belum ada, jalankan `keytool` sekali dan simpan cadangan keystore serta kata sandinya di tempat yang aman.

```bash
keytool -genkeypair -storetype PKCS12 -keystore ../topan-release.p12 \
  -alias topan-release -keyalg RSA -keysize 3072 -validity 10000
base64 < ../topan-release.p12 | gh secret set TOPAN_ANDROID_KEYSTORE_B64 --repo tarmizy/topan_tracking
gh secret set TOPAN_ANDROID_STORE_PASSWORD --repo tarmizy/topan_tracking
gh secret set TOPAN_ANDROID_KEY_ALIAS --repo tarmizy/topan_tracking
gh secret set TOPAN_ANDROID_KEY_PASSWORD --repo tarmizy/topan_tracking
```

Masukkan alias dari keystore saat mengisi `TOPAN_ANDROID_KEY_ALIAS`. Jika membuat keystore PKCS12 dengan perintah di atas, gunakan kata sandi keystore yang sama untuk `TOPAN_ANDROID_KEY_PASSWORD`. Jika APK sebelumnya ditandatangani dengan kunci berbeda, pengguna perlu memasang ulang saat pindah ke APK bertanda tangan rilis. Gunakan keystore yang sama untuk pembaruan berikutnya.

## Kirim rilis pertama

Setelah setup Drive dan keystore selesai, tandai commit dari branch yang berisi workflow dan kode yang ingin dirilis.

```bash
git fetch origin build/android-apk
git tag -a android-v1.0.1 origin/build/android-apk -m "Topan Tracking Android 1.0.1"
git push origin refs/tags/android-v1.0.1
```

Buka tab [Actions](https://github.com/tarmizy/topan_tracking/actions), lalu cek job **publish-drive**. Job memverifikasi checksum APK setelah diunggah. Build lama yang dijalankan ulang akan dilewati bila Drive sudah memiliki nomor build yang lebih baru. Jika izin Google dicabut, jalankan kembali setup dengan OAuth client yang sama.
