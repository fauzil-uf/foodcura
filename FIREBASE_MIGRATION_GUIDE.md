# FoodCura — Panduan & Status Migrasi Firebase (Branch `firebase`)

Dokumen ini adalah ringkasan serah terima (handover) agar pengerjaan integrasi Firebase Cloud Firestore dapat dilanjutkan kapan saja dengan mulus setelah sesi ditutup.

---

## 1. Status Git & Branch
- **Branch Aktif**: `firebase` (Sudah di-push ke GitHub: `origin/firebase`)
- **Branch `main`**: Aman, stabil, dan bersih di commit `88b8764`.
- **Status Working Tree**: Bersih (`clean`), semua 81 unit & widget test lulus 100%.

### Riwayat Commit di Branch `firebase`:
1. `092f1c5`: Setup awal dependensi Firebase & konfigurasi `firebase.json`
2. `16379f7`: Upgrade ekosistem pustaka Firebase ke versi terbaru (`cloud_firestore: ^6.1.0`, `firebase_core: ^4.0.0`, `firebase_auth: ^6.0.0`)
3. `6491152`: Membuat `FirestoreService` & mapping model Firestore (Fase 1)
4. `3ab4881`: Sinkronisasi katalog makanan master (`foods`) dengan offline-first fallback (Fase 2)
5. `71993c7`: Sinkronisasi profil pengguna, streak, dan Eco Points ke Firestore (Fase 3)
6. `b875bd9`: Sinkronisasi CRUD inventaris dapur (`pantry_items`) ke subcollection Firestore (Fase 4)
7. `afb2a42`: Sinkronisasi catatan makan harian (`food_logs`) ke subcollection Firestore (Fase 5)
8. `0ac30c4`: Aturan keamanan `firestore.rules` dan link di `firebase.json` (Fase 6)

---

## 2. Arsitektur Data Firestore

```
firestore
├── foods/{foodId}                        (Global Collection - Read-only publik)
│   ├── name, calories, protein, carbs, fat, cholesterol, category, image_path
│
└── users/{userId}                        (User Document)
    ├── uid, name, email, eco_points, streak_count, last_active_at
    │
    ├── pantry_items/{itemId}             (Subcollection)
    │   ├── name, quantity, unit, storage, expiry_date, is_used, created_at
    │
    ├── food_logs/{logId}                 (Subcollection)
    │   ├── food_name, meal_type, calories, protein, carbs, fat, date, time, note
    │
    └── notifications/{notifId}           (Subcollection)
        ├── title, message, type, icon_type, is_read, created_at
```

---

## 3. Langkah Lanjutan Saat Menyalakan Komputer Kembali

### Opsi A: Melanjutkan di Chat Ini
- Saat Antigravity IDE dibuka kembali, chat ini masih tersimpan otomatis di riwayat chat panel. Cukup ketik:
  > *"Lanjutkan pengujian Firebase"* atau *"Deploy rules ke Firebase console"*

### Opsi B: Membuka Chat Baru
Jika membuka tab chat baru, cukup ketik instruksi singkat:
> *"Saya ingin melanjutkan pekerjaan di branch `firebase`. Lihat file `FIREBASE_MIGRATION_GUIDE.md` untuk status terakhir."*

### Opsi C: Menjalankan Aplikasi & Uji Coba di HP / Emulator
1. Pastikan branch berada di `firebase`:
   ```powershell
   git checkout firebase
   ```
2. Pastikan database Firestore di [Firebase Console](https://console.firebase.google.com/) (`foodcura-c2a5c`) sudah dibuat (klik *"Create database"* jika belum).
3. Jalankan aplikasi seperti biasa:
   ```powershell
   flutter run
   ```
4. Jalankan pengujian:
   ```powershell
   flutter test
   ```

---

## 4. Batasan & Catatan Penting
- File `lib/services/gemini_service.dart` **TIDAK BOLEH dimodifikasi**.
- Pendekatan aplikasi adalah **Offline-First**: SQLite lokal tetap aktif agar aplikasi berjalan instan (0ms) tanpa internet, lalu otomatis sinkron ke Firestore saat ada koneksi.
