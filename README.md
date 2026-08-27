<div align="center">

<img src="assets/images/logo.png" alt="FoodCura Logo" width="120" />

# FoodCura
### *Smart Nutrition Tracker & Food Waste Reducer*

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![SQLite](https://img.shields.io/badge/sqlite-%2307405E.svg?style=for-the-badge&logo=sqlite&logoColor=white)
![Gemini AI](https://img.shields.io/badge/Google%20Gemini%20AI-8E75B2?style=for-the-badge&logo=google%20gemini&logoColor=white)
![Tests](https://img.shields.io/badge/Tests-37%20Passed-success?style=for-the-badge)

**Aplikasi Mobile Cerdas Berbasis Flutter untuk Pelacak Nutrisi Harian, Manajemen Bahan Dapur (Zero Food Waste), dan Asisten AI Google Gemini.**

[Fitur Utama](#-fitur-utama-aplikasi) • [Teknologi](#-teknologi--dependensi) • [Arsitektur](#-arsitektur-proyek-mvc-pattern) • [Keamanan](#-keamanan--autentikasi-berlapis) • [Integrasi AI](#-integrasi-fitur-google-gemini-ai) • [Panduan Instalasi](#-cara-menjalankan-aplikasi) • [Testing](#-validasi-kualitas-kode--testing) • [Changelog Lengkap](#-changelog)

</div>

---

## 📖 Tentang FoodCura

**FoodCura** hadir sebagai solusi komprehensif untuk dua tantangan utama gaya hidup modern: **menjaga pola makan bergizi seimbang** dan **mencegah pemborosan bahan makanan rumah tangga (*Zero Food Waste*)**.

Dengan mengintegrasikan tabel komposisi pangan Indonesia (TKPI), pelacak masa kedaluwarsa bahan dapur (*Pantry Expiry Tracker*), sistem apresiasi *Eco Points*, serta kecerdasan buatan **Google Gemini AI**, FoodCura mendampingi pengguna hidup lebih sehat sekaligus melestarikan lingkungan dan menghemat pengeluaran belanja pangan harian.

---

## ✨ Fitur Utama Aplikasi

### 1. 🏠 Smart Daily Dashboard
* **Ringkasan Nutrisi Harian**: Visualisasi interaktif asupan kalori (target harian 2.000 kkal) dan 4 pilar makronutrisi (*Protein, Karbohidrat, Lemak, Kolesterol*).
* **AI Daily Nutrition Coach**: Rekomendasi menu makan sehat berikutnya dan evaluasi gizi secara real-time bertenaga Gemini AI.
* **Status Pantry Urgent**: Indikator *live badge* untuk bahan makanan yang mendekati kedaluwarsa (≤2 hari).
* **Pelacak Streak & Eco Points**: Menghitung konsistensi hari aktif dan total poin reward penyelamatan makanan.

### 2. 🥗 Nutrition & Meal Tracker
* **Pencatatan Makanan Terstruktur**: Log makanan berdasarkan 4 waktu makan (*Sarapan, Makan Siang, Makan Malam, Camilan*).
* **Katalog Makanan Indonesia**: Database nutrisi lokal lengkap dengan rincian kalori, makronutrisi, foto ilustrasi, dan takaran porsi.
* **Navigasi Riwayat Kalender**: Fleksibilitas memilih tanggal (*Hari Ini, Kemarin, Besok, atau tanggal lampau*) untuk memantau tren gizi harian.
* **Detail & Catatan Personal**: Modal interaktif untuk memeriksa komposisi gizi, menambahkan catatan khusus, atau menghapus log.

### 3. 📦 Smart Pantry & Expiry Tracker (*Zero Food Waste*)
* **Manajemen Stok Dapur**: Inventarisasi bahan mentah dan kemasan (Sayuran, Buah, Daging, Bumbu, dll).
* **Indikator Urgensi Berbasis Warna**:
  * 🔴 **Urgent**: Kedaluwarsa dalam ≤2 hari.
  * 🟡 **Segera**: Kedaluwarsa dalam 3–5 hari.
  * 🟢 **Aman**: Kedaluwarsa dalam >5 hari.
* **Tandai Habis & Reward Eco Impact**: Mengonversi bahan yang dimasak tepat waktu menjadi **Eco Points**, estimasi emisi karbon yang dicegah (kg CO₂e), serta estimasi rupiah yang berhasil dihemat.

### 4. 🤖 Asisten Cerdas Google Gemini AI
* **AI Nutrition Coach**: Analisis keseimbangan gizi harian dan solusi variasi menu makanan sehat.
* **AI Eco Impact Calculator**: Narasi motivasi dan perhitungan dampak penyelamatan bahan makanan bagi kelestarian bumi.
* **AI Interactive Mini Quiz**: Generator 5 soal kuis pilihan ganda edukatif seputar gizi dan *food waste* dengan Structured JSON mode (*dilengkapi Curated Offline Pool*).

### 5. 📚 Food Info & Edukasi Gizi
* **Artikel & Panduan Praktis**: Kumpulan artikel edukasi gizi seimbang, tips penyimpanan bahan makanan di kulkas, dan panduan *meal prep* hemat.
* **Pencarian Cepat**: Filter kategori dan fitur pencarian dinamis untuk menemukan artikel yang relevan.

### 6. 👤 Profil Pengguna & Pusat Bantuan
* **Bento Stats Grid**: Statistik performa akun (*Total Eco Points, Streak Aktif, Bahan Terselamatkan, Estimasi Biaya Terhemat*).
* **Avatar Dinamis Google Account-Style**: Avatar inisial dengan palet warna modern dinamis.
* **Pusat Bantuan Interaktif**: FAQ terstruktur (Umum, Nutrisi, Food Waste, Akun & Keamanan), live search bar bantuan, dan kontak dukungan.

### 7. 🔔 Smart Local Notifications
* Pengingat otomatis untuk bahan makanan dapur yang mendekati batas kedaluwarsa.
* Peringatan cerdas saat asupan nutrisi tertentu (seperti lemak >67g) melebihi batas aman harian.

---

## 🛠️ Teknologi & Dependensi

| Kategori | Teknologi / Paket | Versi | Kegunaan |
| :--- | :--- | :--- | :--- |
| **Framework & Bahasa** | Flutter & Dart SDK | `>= 3.12.2` | Core mobile cross-platform framework |
| **Local Database** | `sqflite` & `path` | `^2.4.3` | Database relasional lokal SQLite (Offline First) |
| **State Management** | `ChangeNotifier` & `Provider` pattern | Native | Reactive unidirectional data flow (MVC) |
| **Cloud & Autentikasi** | `firebase_core` & `firebase_auth` | `^3.12.0` / `^5.5.0` | Inisialisasi Firebase & manajemen akun cloud |
| **Google Sign-In** | `google_sign_in` | `^6.2.2` | Otentikasi OAuth 2.0 via Google Account |
| **Kriptografi & Keamanan** | `crypto` | `^3.0.6` | Hashing SHA-256 + Salt pada password SQLite |
| **Kecerdasan Buatan** | Google Gemini REST API | Multi-Model | Model `gemini-3.5-flash`, `gemini-3.7-flash`, `gemini-3.1-flash-lite` |
| **Local Storage** | `shared_preferences` | `^2.3.4` | Penyimpanan sesi aktif dan user preferences |
| **Local Notifications** | `flutter_local_notifications` | `^18.0.1` | Pengingat jadwal makan & peringatan masa kedaluwarsa |
| **UI & Vector** | `flutter_svg`, `cupertino_icons` | `^2.0.9` / `^1.0.8` | Rendering ikon SVG dan aset desain modern |
| **Formatting** | `intl` | `^0.19.0` | Format mata uang rupiah dan tanggal multibahasa |

---

## 🔒 Keamanan & Autentikasi Berlapis

FoodCura menerapkan arsitektur keamanan multi-layer untuk melindungi integritas akun pengguna:

| Lapisan Keamanan | Implementasi | Perlindungan |
| :--- | :--- | :--- |
| **Google Sign-In & Firebase Auth** | OAuth 2.0 via Google Play Services & Firebase Authentication | Kredensial tidak pernah disimpan di aplikasi; kebal dari *reverse engineering*; dilengkapi `disconnect()` saat logout untuk pemilihan akun fleksibel. |
| **Password Hashing Lokal** | **SHA-256 + Secret Salt** ([SecurityHelper](file:///d:/project/foodcura/lib/utils/security_helper.dart)) | Password di SQLite disimpan dalam format *one-way cryptographic hash* 64 karakter hex, mencegah kebocoran data jika HP di-*root*. |
| **Auto-Migration Keamanan** | Backward Compatibility Engine ([DBHelper](file:///d:/project/foodcura/lib/database/db_helper.dart)) | Akun lama yang belum di-hash secara otomatis di-upgrade ke hash SHA-256 saat berhasil login tanpa mengganggu kenyamanan pengguna. |
| **Data Isolation** | SQLite Scoped User ID (`userId`) | Setiap pengguna memiliki data terisolasi secara mandiri pada tabel `food_logs`, `pantry_items`, dan `notifications`. |

---

## 🏛️ Arsitektur Proyek (MVC Pattern)

Aplikasi dibangun menggunakan pola arsitektur **Model-View-Controller (MVC)** yang bersih, terisolasi, dan mudah dirawat:

```
lib/
├── constants/          # Design tokens & konstanta (AppColors, AppTextStyles, AppTheme, AppImages, AppConstants, AppDateFormatter)
├── controllers/        # Business Logic & State layer (ChangeNotifier & Reactive State)
│   ├── auth_controller.dart
│   ├── dashboard_controller.dart
│   ├── food_info_controller.dart
│   ├── food_tracker_controller.dart
│   ├── notification_controller.dart
│   ├── pantry_controller.dart
│   ├── profile_controller.dart
│   └── quiz_controller.dart
├── database/           # SQLite DBHelper, schema DAO, & pantry grocery catalog
│   ├── db_helper.dart
│   └── pantry_grocery_catalog.dart
├── models/             # Pure Data models & entity definitions (UserModel, FoodItemModel, FoodLogModel, PantryItemModel, QuizModel, ArticleModel, dll)
├── services/           # External service integration & domain managers
│   ├── app_notifiers.dart         # Global Reactive Notifiers (Sync State antar-tab)
│   ├── auth_service.dart          # Firebase Auth & Google Sign-In
│   ├── gemini_service.dart        # Google Gemini AI Service & Fallback Chain
│   ├── notification_service.dart  # Local Push Notifications
│   ├── nutrition_service.dart     # Standar AKG & Nutrition Thresholds
│   ├── preference_handler.dart    # SharedPreferences Local Storage
│   ├── reminder_service.dart      # Meal Reminder Scheduler
│   └── streak_service.dart        # Dynamic Streak Calculation Engine
├── utils/              # Helper utilitas keamanan
│   └── security_helper.dart       # SHA-256 + Salt Password Hasher
├── views/              # UI Presentation layer (Feature-Grouped)
│   ├── auth/           # LoginScreen, RegisterScreen, ForgotPasswordScreen
│   ├── dashboard/      # DashboardScreen & widgets (QuizModal)
│   ├── food_info/      # FoodInfoScreen & widgets (ArticleDetailModal)
│   ├── food_tracker/   # FoodTrackerScreen & widgets (AddFoodModal, AllCatalogModal, FoodDetailModal, FoodSummaryCard)
│   ├── navigation/     # MainNavigationScreen (5 tabs bottom navigation bar)
│   ├── notification/   # NotificationScreen
│   ├── onboarding/     # SplashScreen, OnboardingScreen
│   ├── pantry/         # PantryScreen & widgets (AddPantryItemModal, PantryItemDetailModal)
│   ├── profile/        # ProfileScreen, HelpCenterScreen & modals
│   └── widgets/        # Shared Reusable Widgets (AppTextField, AppTopBar, AppFoodImage, AppFilterChipRow, AppCircularProgress)
├── firebase_options.dart # Konfigurasi platform Firebase
└── main.dart           # Entry point aplikasi & inisialisasi modul
```

---

## 🤖 Integrasi Fitur Google Gemini AI

FoodCura memanfaatkan **Google Gemini AI Service** ([gemini_service.dart](file:///d:/project/foodcura/lib/services/gemini_service.dart)) pada 3 pilar fitur:

1. **AI Interactive Quiz** ([quiz_modal.dart](file:///d:/project/foodcura/lib/views/dashboard/widgets/quiz_modal.dart)):
   - Generator kuis dinamis 5 soal pilihan ganda interaktif dengan Structured JSON mode dan panjang opsi pilihan seimbang.
2. **AI Daily Nutrition Coach** ([dashboard_controller.dart](file:///d:/project/foodcura/lib/controllers/dashboard_controller.dart)):
   - Analisis otomatis asupan harian dengan rekomendasi menu makanan personal secara real-time.
3. **AI Eco Impact & Carbon Savings** ([pantry_controller.dart](file:///d:/project/foodcura/lib/controllers/pantry_controller.dart)):
   - Narasi dampak lingkungan (kg CO₂e dicegah & rupiah dihemat) saat menandai bahan makanan termasak.
4. **Multi-Model Fallback Chain**:
   - Mendukung rangkaian model: `gemini-3.5-flash`, `gemini-3.7-flash`, `gemini-3.1-flash-lite`, dan `gemini-flash-latest`.
   - Dilengkapi *Curated Offline Pool Fallback* sehingga aplikasi tetap berfungsi normal tanpa koneksi internet atau saat kuota API habis.

---

## 🚀 Cara Menjalankan Aplikasi

### 1. Prasyarat Sistem
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi `^3.12.2` atau lebih baru)
* [Android Studio](https://developer.android.com/studio) / [VS Code](https://code.visualstudio.com/) dengan plugin Flutter & Dart
* Emulator Android (API level 24+) atau Perangkat Fisik

### 2. Kloning Repository & Instalasi Dependensi
```bash
# Clone repository
git clone https://github.com/fauzil-uf/foodcura.git

# Masuk ke direktori proyek
cd foodcura

# Unduh semua paket dependensi
flutter pub get
```

### 3. Menjalankan Aplikasi
```bash
# Mode Standar (Menggunakan fallback cerdas offline & SQLite)
flutter run

# Mode Online Gemini AI (Menyertakan API Key kustom)
flutter run --dart-define=GEMINI_API_KEY="AIzaSy..."
```

### 4. Membangun APK Release yang Ringan (~18 MB)
```bash
# Build APK terpisah per arsitektur HP untuk ukuran minimal
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
```

---

## 🧪 Validasi Kualitas Kode & Testing

Proyek FoodCura menerapkan standar pengujian otomatis dan analisis kode bebas peringatan:

```bash
# 1. Format kode otomatis
dart format .

# 2. Analisis statis & pemeriksaan lint (0 issues)
flutter analyze

# 3. Eksekusi seluruh rangkaian Unit & Widget Test (37 Passed)
flutter test
```

### Rangkuman Test Coverage (37/37 Tests Passed):
* ✅ `security_helper_test.dart`: Pengujian Hashing SHA-256, Salt Avalanche, verifikasi hash, dan backward compatibility.
* ✅ `controllers_test.dart`: Validasi alur state `AuthController`, `DashboardController`, `FoodTrackerController`, `NotificationController`, `PantryController`, dan `QuizController`.
* ✅ `profile_controller_test.dart`: Pengujian state profil, pembaruan data pengguna, dan validasi pergantian kata sandi.
* ✅ `streak_test.dart`: Logika perhitungan streak hari aktif dan *boundary checking*.
* ✅ `services_test.dart`: Verifikasi standar batas gizi AKG dan scheduler notifikasi.
* ✅ `date_formatter_test.dart`: Parser tanggal multibahasa (Indonesian locale & ISO strings).
* ✅ `widget_test.dart`: Pengujian render UI tema, tipografi, dan interaksi layar bantuan.

---

## 📋 Changelog

### **v2.1.0** — Security Architecture, Password Hashing & Google Account Switch *(Current)*
#### [Added]
* **Sistem Keamanan Hashing Password (SHA-256 + Salt)**:
  - Pembuatan utilitas [SecurityHelper](file:///d:/project/foodcura/lib/utils/security_helper.dart) untuk mengubah kata sandi teks biasa menjadi kode hash kriptografi 64-karakter hex.
  - Penambahan dependensi resmi [`crypto: ^3.0.6`](file:///d:/project/foodcura/pubspec.yaml#L47).
  - Mekanisme **Auto-Migration**: Akun *legacy* yang sebelumnya tersimpan dalam *plain text* secara otomatis di-upgrade ke format hash aman saat berhasil login.
* **Test Suite Kriptografi & Keamanan**:
  - Penambahan [security_helper_test.dart](file:///d:/project/foodcura/test/security_helper_test.dart) yang menguji hashing SHA-256, determinisme, *avalanche effect (salting)*, verifikasi kecocokan, dan *backward compatibility* (meningkatkan total test menjadi **37/37 Tests Passed**).
* **Penyempurnaan Google Sign-In & Logout Multi-Akun**:
  - Penambahan `_googleSignIn.disconnect()` pada [AuthService.signOut()](file:///d:/project/foodcura/lib/services/auth_service.dart#L100-L109) untuk memutus cache otorisasi Google sehingga dialog pemilih akun (*Account Chooser / Ganti Akun*) selalu muncul saat login ulang.
  - Memanggil `AuthService.instance.signOut()` dari [ProfileController.logout()](file:///d:/project/foodcura/lib/controllers/profile_controller.dart#L147-L155) agar sesi lokal dan cloud terputus secara sinkron.
* **Penyelarasan Branding & UI Dialog**:
  - Pembaruan visual pada [AboutFoodCuraDialog](file:///d:/project/foodcura/lib/views/profile/widgets/about_foodcura_dialog.dart) dengan logo resmi [AppImages.logo](file:///d:/project/foodcura/lib/constants/app_images.dart#L6) dan versi `v2.1.0`.
  - Penambahan banner logo resmi pada header [README.md](file:///d:/project/foodcura/README.md).

#### [Changed]
* **Database Layer CRUD**:
  - Refactor `DBHelper.registerUser()`, `DBHelper.loginUser()`, dan `DBHelper.changePassword()` untuk menggunakan fungsi hashing dan verifikasi dari `SecurityHelper`.
* **Pembaruan Versi Proyek**:
  - Menaikkan versi proyek di [pubspec.yaml](file:///d:/project/foodcura/pubspec.yaml#L19) menjadi `version: 2.1.0+3`.

#### [Fixed]
* Memperbaiki bug *auto-login* Google Sign-In yang otomatis masuk ke akun sebelumnya tanpa opsi pemilihan akun lain.
* Menghilangkan celah kerentanan kata sandi berformat *plain text* pada database SQLite lokal.

---

### **v2.0.0** — Major Architectural Redesign (MVC), Gemini AI & Bento Profile
#### [Added]
* **Fitur AI Gemini & Edukasi Interaktif**:
  - **AI Mini Quiz** ([food_info_screen.dart](file:///d:/project/foodcura/lib/views/food_info/food_info_screen.dart) & [quiz_modal.dart](file:///d:/project/foodcura/lib/views/dashboard/widgets/quiz_modal.dart)): Kuis edukasi gizi dan food waste berbasis AI Structured JSON mode.
  - **AI Nutrition Coach**: Analisis asupan makronutrisi dan saran menu di Dashboard.
  - **AI Eco Impact Calculator**: Narasi kalkulasi jejak karbon saat menyelamatkan stok makanan di Pantry.
  - Integrasi **Google Gemini AI Service** ([gemini_service.dart](file:///d:/project/foodcura/lib/services/gemini_service.dart)) dengan multi-model chain (`gemini-3.5-flash`, `gemini-3.7-flash`, `gemini-3.1-flash-lite`, `gemini-flash-latest`) & Structured JSON mode.
* **Fitur Profil Pengguna & Eco Points** ([profile_screen.dart](file:///d:/project/foodcura/lib/views/profile/profile_screen.dart)):
  - Avatar dinamis Google Account-style berbasis inisial huruf dengan color palette modulo.
  - Tracking Eco Points, Streak harian, form edit profil, dan manajemen sesi login/logout.
* **Fitur Pusat Bantuan** ([help_center_screen.dart](file:///d:/project/foodcura/lib/views/profile/help_center_screen.dart)):
  - Live search bar bantuan, accordion FAQ terstruktur (Umum, Nutrisi, Food Waste, Akun & Keamanan), dan tombol Hubungi Kami.
* **Arsitektur MVC & Grouping Berbasis Fitur**:
  - Pemisahan 8 Controller murni: `AuthController`, `DashboardController`, `FoodInfoController`, `FoodTrackerController`, `NotificationController`, `PantryController`, `ProfileController`, `QuizController`.
  - Restrukturisasi sub-folder `views` terisolasi per-fitur (`auth`, `dashboard`, `food_tracker`, `pantry`, `food_info`, `profile`, `notification`, `onboarding`, `navigation`).
* **Ekspansi Test Suites**:
  - Penambahan [controllers_test.dart](file:///d:/project/foodcura/test/controllers_test.dart), [profile_controller_test.dart](file:///d:/project/foodcura/test/profile_controller_test.dart), [services_test.dart](file:///d:/project/foodcura/test/services_test.dart), [streak_test.dart](file:///d:/project/foodcura/test/streak_test.dart), [date_formatter_test.dart](file:///d:/project/foodcura/test/date_formatter_test.dart), dan integrasi widget tests.
* **Aset & Utilitas Baru**:
  - Desain token [app_theme.dart](file:///d:/project/foodcura/lib/constants/app_theme.dart) dan Google SVG Vector Icon (`assets/icons/google.svg`).
  - Model domain baru: `ArticleModel`, `QuizQuestion`, dan reactive notifiers.

#### [Changed]
* **Navigasi Utama 5 Tab**: Peningkatan [MainNavigationScreen](file:///d:/project/foodcura/lib/views/navigation/main_navigation_screen.dart) mengintegrasikan Dashboard, Tracker, Pantry, Info Edukasi, dan Profil.
* **Refactoring Clean Code & Desain Tokens**:
  - Migrasi seluruh `.withOpacity(...)` usang ke `.withValues(alpha: ...)`.
  - Sentralisasi konsisten pada `AppColors`, `AppTextStyles`, `AppTheme`, dan `AppImages`.
  - Penyesuaian `DBHelper` dengan optimasi query dan reaktifitas stream.

#### [Fixed]
* Menghapus file legacy yang tidak terpakai: `lib/login.dart`.
* Memperbaiki bug kalkulasi streak berturut-turut pada database SQLite.
* Mengatasi inkonsistensi styling dan margin widget di seluruh modal.

---

### **v1.1.0** — Pantry Expiry Tracker, Notifications & Splash Screen *(Commit `297d3a7`)*
#### [Added]
* Fitur Pantry & Expiry Tracker (`pantry_items`) dengan sistem indikator urgensi (*Urgent*, *Segera*, *Aman*).
* Modul Notifikasi lokal (`notifications`) untuk pengingat masa kadaluwarsa dan peringatan batas nutrisi.
* Layar Splash Screen dengan animasi dinamis.
* Modal penambahan bahan dapur (`AddPantryItemModal`).

#### [Changed]
* Peningkatan parser tanggal bahasa Indonesia di `AppDateFormatter`.
* Pembaruan skema `DBHelper` untuk mengelola tabel `pantry_items` dan `notifications`.

---

### **v1.0.0** — Initial Release *(Commit `c5ac194`)*
#### [Added]
* Inisialisasi arsitektur proyek FoodCura berbasis Flutter.
* Sistem autentikasi pengguna (Login, Register, Forgot Password, Onboarding).
* Database SQLite lokal (`users`, `foods`, `food_logs`).
* Modul Food Tracker dan Dashboard ringkasan nutrisi harian.
* Katalog makanan lokal dan modal pencatatan makanan harian.

---

## 📄 Lisensi & Hak Cipta

Proyek ini dikembangkan untuk tujuan edukasi dan peningkatan kualitas hidup sehat melalui pemanfaatan teknologi.
Dikembangkan dengan ❤️ oleh Tim **FoodCura**.
