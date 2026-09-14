

## MEMBUAT APK OTOMATIS DENGAN GITHUB

1. Buat repository baru di GitHub, misalnya `kas-warga-rt`.
2. Upload seluruh isi folder project ini ke repository tersebut.
3. Pastikan file `.github/workflows/build-apk.yml` ikut ter-upload.
4. Buka tab **Actions** di repository.
5. Pilih workflow **Build Kas Warga RT APK**.
6. Tekan **Run workflow**.
7. Setelah selesai dan statusnya hijau, buka hasil workflow tersebut.
8. Pada bagian **Artifacts**, download **KasWargaRT-APK**.
9. Ekstrak ZIP hasil download. Di dalamnya ada `KasWargaRT.apk`.
10. Kirim APK ke HP Android dan instal.

APK ini dibuat sebagai release APK untuk instal langsung, bukan melalui Play Store.
