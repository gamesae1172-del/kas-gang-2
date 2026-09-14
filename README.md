# KasWarga - Flutter Starter

Aplikasi Android lokal-first untuk manajemen kas dan iuran RT/Komunitas.

## Demo login
- Admin: `admin` / `admin123`
- Warga: `warga` / `warga123`

## Fitur yang sudah ada
- Role Admin / Warga
- Dashboard saldo
- CRUD warga untuk Admin
- Pencarian warga
- Iuran bulanan Jan-Des
- Catat lunas dengan tanggal bayar otomatis
- Buku kas pemasukan/pengeluaran
- Saldo real-time
- Filter bulan transaksi
- Laporan PDF buku kas
- Kirim tagihan melalui WhatsApp
- Penyimpanan lokal dengan SharedPreferences
- Backup JSON dan restore dari file melalui dialog Android

## Menjalankan
1. Install Flutter SDK.
2. Jalankan:
   flutter pub get
3. Hubungkan perangkat Android atau buka emulator.
4. Jalankan:
   flutter run

## Membuat APK
Untuk APK debug:
flutter build apk --debug

Untuk APK release:
flutter build apk --release

File release biasanya berada di:
build/app/outputs/flutter-apk/app-release.apk

Tidak perlu Play Store. APK dapat dipasang langsung di perangkat Android dengan izin instalasi dari sumber yang sesuai.

## Catatan produksi
Versi starter ini sengaja memakai penyimpanan lokal sederhana agar mudah dijalankan. Untuk produksi sebaiknya migrasikan database ke Drift/SQLite, password ke hashing yang aman, credential ke secure storage, dan backup Google Drive memakai OAuth/API resmi.