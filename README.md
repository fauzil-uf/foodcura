# 🥗 FoodCura — Smart Nutrition Tracker & Food Waste Reducer

FoodCura adalah aplikasi mobile cerdas berbasis Flutter yang menggabungkan pencatatan nutrisi harian (*Nutrition Tracker*), manajemen stok dapur (*Pantry & Expiry Tracker*), serta integrasi kecerdasan buatan (**Google Gemini AI**) untuk menjaga kesehatan sekaligus mencegah pemborosan makanan (*Zero Food Waste*).

---

## ✨ Fitur Utama Aplikasi

### 1. 🏠 Smart Daily Dashboard
* **Ringkasan Nutrisi Harian**: Visualisasi interaktif asupan kalori (target 2.000 kkal) dan 4 pilar makronutrisi (Protein, Karbohidrat, Lemak, Kolesterol).
* **AI Daily Nutrition Coach**: Tombol konsultasi instan bertenaga Gemini AI untuk mendapatkan saran pola makan dan menu berikutnya.
* **Status Pantry Urgent**: Notifikasi visual langsung untuk bahan makanan yang mendekati kedaluwarsa (≤2 hari).
* **Pelacak Streak & Eco Points**: Menampilkan konsistensi hari aktif dan total poin reward penyelamatan makanan.

### 2. 🥗 Nutrition & Meal Tracker
* **Pencatatan Makanan Terstruktur**: Log makanan harian berdasarkan 4 kategori waktu makan (*Sarapan, Makan Siang, Makan Malam, Camilan*).
* **Katalog Makanan Indonesia**: Database nutrisi lokal lengkap dengan rincian kalori, makronutrisi, foto ilustrasi, dan porsi.
* **Kalender & Riwayat Harian**: Navigasi tanggal fleksibel (*Hari Ini, Kemarin, Besok, atau tanggal lampau*) untuk memantau tren gizi harian.
* **Detail & Catatan Makanan**: Modal detail untuk melihat komposisi nutrisi, menambah catatan personal, atau menghapus log.

### 3. 📦 Smart Pantry & Expiry Tracker (Zero Food Waste)
* **Manajemen Stok Dapur**: Inventarisasi bahan makanan mentah/kemasan (Sayuran, Buah, Daging, Bumbu, dll).
* **Indikator Urgensi Otomatis**: Pengelompokan visual berbasis sisa hari kadaluwarsa:
  * 🔴 **Urgent**: Kedaluwarsa dalam ≤2 hari.
  * 🟡 **Segera**: Kedaluwarsa dalam 3–5 hari.
  * 🟢 **Aman**: Kedaluwarsa dalam >5 hari.
* **Tandai Habis & Reward Eco Impact**: Mengonversi bahan yang berhasil dimasak sebelum basi menjadi **Eco Points** serta kalkulasi reduksi emisi karbon (kg CO₂e) dan estimasi rupiah terhemat.

### 4. 🤖 Asisten Cerdas Google Gemini AI
* **AI Nutrition Coach**: Analisis real-time keseimbangan makronutrisi harian dan rekomendasi solusi makanan sehat.
* **AI Eco Impact Calculator**: Narasi motivasi dan perhitungan dampak penyelamatan bahan makanan bagi kelestarian bumi.
* **AI Interactive Mini Quiz**: Pembuatan 5 kuis pilihan ganda edukatif dinamis seputar gizi dan food waste dengan opsi seimbang (*dilengkapi Curated Offline Pool*).

### 5. 📚 Food Info & Edukasi Gizi
* **Artikel & Panduan Praktis**: Kumpulan artikel edukatif seputar gizi seimbang, tips penyimpanan sayuran/daging di kulkas, hingga teknik *meal prep* hemat biaya.
* **Pencarian Artikel**: Filter kategori dan fitur pencarian cepat untuk artikel gizi dan tips *food waste recovery*.

### 6. 👤 Profil Pengguna & Pusat Bantuan
* **Bento Stats Grid**: Ringkasan performa pengguna (*Total Eco Points, Streak Hari Aktif, Bahan Terselamatkan, Estimasi Biaya Terhemat*).
* **Pusat Bantuan Interaktif**: FAQ terstruktur (Umum, Nutrisi, Food Waste, Akun & Keamanan), live search bantuan, dan kontak dukungan.

### 7. 🔔 Smart Local Notifications
* Pengingat otomatis stok makanan yang mendekati kedaluwarsa.
* Peringatan cerdas saat asupan nutrisi tertentu (seperti lemak melebihi 67g) melebihi batas aman harian.

### 8. 🔐 Autentikasi & Onboarding
* Splash screen interaktif & halaman onboarding pengenalan 3 pilar FoodCura.
* Autentikasi lengkap (Login, Registrasi akun baru, dan Reset Password) dengan validasi form ketat dan sesi SQLite lokal.

---

## 🏛️ Arsitektur Proyek (MVC Pattern)

Aplikasi ini dibangun menggunakan arsitektur **Model-View-Controller (MVC)** yang bersih dan terisolasi:

```
lib/
├── constants/          # Design tokens (AppColors, AppTypography, AppDecorations, AppImages, AppDateFormatter, ApiConstants)
├── controllers/        # State & Business Logic layer (ChangeNotifier)
│   ├── auth_controller.dart
│   ├── dashboard_controller.dart
│   ├── food_tracker_controller.dart
│   ├── pantry_controller.dart
│   ├── notification_controller.dart
│   └── quiz_controller.dart
├── database/           # SQLite DBHelper & Reactive Notifiers
├── models/             # Immutable data models & entities (UserModel, FoodItem, FoodLog, PantryItem, dll)
├── services/           # External API integrations (Google Gemini AI Service)
└── views/              # Pure UI Presentation layer (Feature-Grouped)
    ├── auth/           # Login, Register, Forgot Password
    ├── dashboard/      # DashboardScreen & widgets (EcoImpactModal, QuizModal)
    ├── food_info/      # FoodInfoScreen & widgets (ArticleDetailModal)
    ├── food_tracker/   # FoodTrackerScreen & widgets (AddFoodModal, AllCatalogModal, FoodDetailModal)
    ├── navigation/     # MainNavigationScreen (5 tabs bottom bar)
    ├── notification/   # NotificationScreen
    ├── onboarding/     # SplashScreen, OnboardingScreen
    ├── pantry/         # PantryScreen & widgets (AddPantryItemModal, PantryItemDetailModal)
    ├── profile/        # ProfileScreen, HelpCenterScreen
    └── widgets/        # Common reusable components (AppFoodImage, AppLogo, AppTextField)
```

---

## 🤖 Integrasi Fitur Google Gemini AI

FoodCura mengintegrasikan **Google Gemini AI Service** ([gemini_service.dart](lib/services/gemini_service.dart)) pada 3 pilar fitur:
1. **AI Interactive Quiz** ([quiz_modal.dart](lib/views/dashboard/widgets/quiz_modal.dart)):
   - Generator kuis dinamis 5 soal pilihan ganda interaktif bertema gizi, batas konsumsi gula/garam, dan penyimpanan makanan dengan Structured JSON mode & panjang opsi seimbang.
2. **AI Daily Nutrition Coach** ([dashboard_controller.dart](lib/controllers/dashboard_controller.dart)):
   - Analisis otomatis asupan harian (kalori, protein, karbohidrat, lemak, dan kolesterol) dengan rekomendasi menu makanan personal secara real-time.
3. **AI Eco Impact & Carbon Savings** ([pantry_controller.dart](lib/controllers/pantry_controller.dart)):
   - Kalkulasi narasi apresiasi dampak lingkungan (estimasi kg CO₂e dicegah dan estimasi pengeluaran dapur dihemat) saat pengguna menyelamatkan bahan makanan dari kulkas.
4. **Multi-Model Fallback Chain**:
   - Mendukung model: `gemini-3.5-flash`, `gemini-3.7-flash`, `gemini-3.1-flash-lite`, dan `gemini-flash-latest`.
   - Dilengkapi *Curated Offline Pool Fallback* sehingga fitur tetap dapat berjalan 100% lancar saat tanpa koneksi internet atau kuota API habis.

---

## 🚀 Cara Menjalankan Aplikasi

### 1. Prasyarat
- Flutter SDK (>= 3.12.2)
- Android Studio / VS Code
- Koneksi Internet (opsional untuk Google Gemini AI)

### 2. Instalasi Dependensi
```bash
flutter pub get
```

### 3. Menjalankan Aplikasi (Debug)
```bash
# Menjalankan standar (dengan default/offline fallback)
flutter run

# Menjalankan dengan custom Google Gemini AI API Key
flutter run --dart-define=GEMINI_API_KEY="AIzaSy..."
```

---

## 🧪 Validasi Kualitas Kode & Testing

Proyek ini dilengkapi dengan pipeline pengujian dan analisis otomatis:

### 1. Formatter Otomatis
```bash
dart format .
```

### 2. Static Analysis & Lint Check (0 Error / 0 Warning)
```bash
flutter analyze
```

### 3. Automated Unit & Widget Tests
```bash
flutter test
```
* **Coverage**: 16/16 Test Passed (AuthController, FoodTrackerController, PantryController, QuizController, AppDateFormatter, Typography & Widget Test).

---

## 📋 Changelog

### **v2.0.0** — Major Architectural Redesign (MVC), Gemini AI & Complete Feature Suite (Current)
#### [Added]
- **Fitur AI Gemini & Edukasi Interaktif**:
  - **AI Mini Quiz** ([food_info_screen.dart](lib/views/food_info/food_info_screen.dart) & [quiz_modal.dart](lib/views/dashboard/widgets/quiz_modal.dart)): Kuis edukasi gizi dan food waste berbasis AI Structured JSON mode.
  - **AI Nutrition Coach**: Analisis asupan makronutrisi dan saran menu di Dashboard.
  - **AI Eco Impact Calculator**: Narasi kalkulasi jejak karbon saat menyelamatkan stok makanan di Pantry.
  - Integrasi **Google Gemini AI Service** ([gemini_service.dart](lib/services/gemini_service.dart)) dengan multi-model chain (`gemini-3.5-flash`, `gemini-3.7-flash`, `gemini-3.1-flash-lite`, `gemini-flash-latest`) & Structured JSON mode.
- **Fitur Profil Pengguna & Eco Points** ([profile_screen.dart](lib/views/profile/profile_screen.dart)):
  - Avatar dinamis Google Account-style berbasis inisial huruf dengan color palette modulo.
  - Tracking Eco Points, Streak harian, form edit profil, dan manajemen sesi login/logout.
- **Fitur Pusat Bantuan** ([help_center_screen.dart](lib/views/profile/help_center_screen.dart)):
  - Live search bar bantuan, accordion FAQ terstruktur (Umum, Nutrisi, Food Waste, Akun & Keamanan), dan tombol Hubungi Kami.
- **Arsitektur MVC & Grouping Berbasis Fitur**:
  - Pemisahan 6 Controller murni: `AuthController`, `DashboardController`, `FoodTrackerController`, `PantryController`, `NotificationController`, `QuizController`.
  - Restrukturisasi sub-folder `views` terisolasi per-fitur (`auth`, `dashboard`, `food_tracker`, `pantry`, `food_info`, `profile`, `notification`, `onboarding`, `navigation`).
- **Ekspansi Test Suites**:
  - Penambahan [controllers_test.dart](test/controllers_test.dart), [date_formatter_test.dart](test/date_formatter_test.dart), dan integrasi widget tests (16/16 tests passed).
- **Aset & Utilitas Baru**:
  - Desain token [app_decorations.dart](lib/constants/app_decorations.dart) dan Google SVG Vector Icon (`assets/icons/google.svg`).
  - Model domain baru: `ArticleModel`, `QuizQuestion`, dan reactive `EcoPointsNotifier`.

#### [Changed]
- **Navigasi Utama 5 Tab**: Peningkatan [MainNavigationScreen](lib/views/navigation/main_navigation_screen.dart) mengintegrasikan Dashboard, Tracker, Pantry, Info Edukasi, dan Profil.
- **Refactoring Clean Code & Desain Tokens**:
  - Migrasi seluruh `.withOpacity(...)` usang ke `.withValues(alpha: ...)`.
  - Sentralisasi konsisten pada `AppColors`, `AppTextStyles`, `AppDecorations`, dan `AppImages`.
  - Penyesuaian `DBHelper` dengan optimasi query dan reaktifitas stream.

#### [Fixed]
- Menghapus file legacy yang tidak terpakai: `lib/login.dart`.
- Memperbaiki bug kalkulasi streak berturut-turut pada database SQLite.
- Mengatasi inkonsistensi styling dan margin widget di seluruh modal.

---

### **v1.1.0** — Pantry Expiry Tracker, Notifications & Splash Screen *(Commit `297d3a7`)*
#### [Added]
- Fitur Pantry & Expiry Tracker (`pantry_items`) dengan sistem indikator urgensi (*Urgent*, *Segera*, *Aman*).
- Modul Notifikasi lokal (`notifications`) untuk pengingat masa kadaluwarsa dan peringatan batas nutrisi.
- Layar Splash Screen dengan animasi dinamis.
- Modal penambahan bahan dapur (`AddPantryItemModal`).
#### [Changed]
- Peningkatan parser tanggal bahasa Indonesia di `AppDateFormatter`.
- Pembaruan skema `DBHelper` untuk mengelola tabel `pantry_items` dan `notifications`.

---

### **v1.0.0** — Initial Release *(Commit `c5ac194`)*
#### [Added]
- Inisialisasi arsitektur proyek FoodCura berbasis Flutter.
- Sistem autentikasi pengguna (Login, Register, Forgot Password, Onboarding).
- Database SQLite lokal (`users`, `foods`, `food_logs`).
- Modul Food Tracker dan Dashboard ringkasan nutrisi harian.
- Katalog makanan lokal dan modal pencatatan makanan harian.
