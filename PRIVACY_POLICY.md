# Kebijakan Privasi FoodCura

**Terakhir Diperbarui:** 31 Agustus 2026  
**Versi:** 2.1.0  

FoodCura ("kami", "aplikasi") menghargai dan berkomitmen untuk melindungi privasi serta keamanan data pribadi Anda. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, melindungi, dan menghapus informasi pribadi Anda saat menggunakan aplikasi mobile FoodCura ("Layanan").

Dengan mengunduh, mendaftar, atau menggunakan Layanan kami, Anda memahami dan menyetujui praktik pengelolaan data yang dijelaskan dalam dokumen ini.

---

## 1. Pendahuluan dan Kepatuhan Hukum

Kebijakan Privasi ini disusun dan tunduk pada peraturan perundang-undangan yang berlaku di Republik Indonesia, termasuk **Undang-Undang Nomor 27 Tahun 2022 tentang Pelindungan Data Pribadi (UU PDP)**, **Undang-Undang Nomor 1 Tahun 2024 tentang Perubahan Kedua atas UU No. 11/2008 tentang Informasi dan Transaksi Elektronik (UU ITE)**, serta peraturan pelaksana terkait sistem elektronik.

Kami bertindak sebagai Pengendali Data Pribadi (*Data Controller*) yang bertanggung jawab atas pengelolaan dan perlindungan data yang diproses melalui aplikasi ini.

---

## 2. Informasi yang Kami Kumpulkan

Kami mengumpulkan informasi yang diperlukan untuk menyediakan fungsi pelacak nutrisi harian dan pengelolaan inventaris bahan makanan secara optimal:

### a. Data yang Anda Berikan Secara Langsung
* **Informasi Akun:** Nama lengkap atau nama pengguna, alamat surat elektronik (*email*), dan kredensial kata sandi saat pendaftaran lokal atau informasi profil dasar saat masuk melalui akun Google.
* **Catatan Nutrisi dan Pola Makan (Data Spesifik Kesehatan):** Log asupan makanan harian, takaran porsi, estimasi kalori, dan rincian makronutrisi (Protein, Karbohidrat, Lemak, Kolesterol) yang Anda catat secara mandiri.
* **Inventaris Bahan Makanan (Pantry):** Nama bahan makanan, jumlah/satuan, kategori penyimpanan (*Kulkas, Freezer, Suhu Ruang*), dan perkiraan tanggal kedaluwarsa.
* **Aktivitas dan Gamifikasi:** Catatan konsistensi hari aktif (*streak*) dan poin reward (*Eco Points*) yang diperoleh dari kuis edukasi.

### b. Informasi yang Dikumpulkan Secara Otomatis
* **Informasi Perangkat:** Model perangkat, versi sistem operasi, resolusi layar, dan bahasa sistem.
* **Data Diagnostik:** Catatan performa dan laporan *crash* non-identifikasi untuk pemeliharaan dan peningkatan stabilitas aplikasi.

---

## 3. Dasar Hukum dan Tujuan Penggunaan Informasi

Pemrosesan data pribadi Anda dilakukan berdasarkan persetujuan sukarela yang Anda berikan (*consent*) serta kebutuhan operasional penyediaan Layanan. Kami menggunakan informasi tersebut untuk:

1. Menghitung asupan nutrisi harian dan membandingkannya dengan standar Angka Kecukupan Gizi (AKG).
2. Memantau persediaan bahan makanan di dapur dan memberikan pengingat sebelum bahan makanan kedaluwarsa guna mengurangi limbah pangan (*food waste*).
3. Mengirimkan notifikasi pengingat jadwal makan harian secara lokal di perangkat Anda.
4. Menyediakan saran nutrisi yang dipersonalisasi dan pertanyaan kuis melalui bantuan kecerdasan buatan (*AI Coach*).
5. Mengamankan akun dan mencegah akses yang tidak sah ke dalam aplikasi.

---

## 4. Keamanan dan Penyimpanan Data

Kami menerapkan langkah-langkah keamanan teknis dan organisasional yang ketat untuk melindungi data pribadi Anda dari akses tidak sah, pengubahan, pengungkapan, atau penghapusan yang tidak sah:

* **Penyimpanan Lokal (*Offline-First*):** Basis data utama catatan makanan, inventaris, dan preferensi Anda disimpan secara lokal pada perangkat Anda menggunakan SQLite yang aman dan terisolasi per akun pengguna (*Scoped User ID*).
* **Enkripsi Kata Sandi Kriptografis:** Kata sandi akun Anda diacak secara permanen menggunakan algoritma *one-way cryptographic hash* **SHA-256 dengan secret salt**. Teks asli kata sandi Anda tidak pernah disimpan dalam sistem.
* **Enkripsi Saluran Komunikasi:** Seluruh komunikasi jaringan dengan layanan eksternal dienkripsi menggunakan protokol standar industri (TLS 1.3 / HTTPS).

---

## 5. Pembagian Data dan Layanan Pihak Ketiga

Kami **tidak pernah menjual, menyewakan, atau memperdagangkan** data pribadi Anda kepada pihak ketiga mana pun untuk tujuan periklanan atau pemasaran komersial.

Aplikasi kami menggunakan beberapa layanan pihak ketiga terpercaya dengan batasan pemrosesan yang ketat:

* **Google Play Services & Firebase Authentication:** Digunakan untuk autentikasi masuk dengan akun Google secara aman tanpa menyimpan kata sandi Google Anda di aplikasi kami. Kebijakan Privasi Google dapat dibaca di: [https://policies.google.com/privacy](https://policies.google.com/privacy).
* **Google Gemini AI REST API:** Digunakan untuk fitur evaluasi nutrisi dan generator kuis gizi. Permintaan yang dikirimkan ke model AI **hanya berisi data numerik gizi agregat dan nama bahan makanan anonim tanpa identitas pribadi (Non-PII)**. Nama, email, atau identitas Anda tidak pernah dikirimkan ke model AI.

---

## 6. Hak-Hak Anda atas Data Pribadi (Kendali Penuh Mandiri)

Karena FoodCura mengadopsi arsitektur *Offline-First*, **seluruh data Anda tersimpan secara lokal di perangkat Anda sendiri**. Tim Pengembang maupun pihak ketiga tidak memiliki akses jarak jauh (*remote access*) ke database lokal perangkat Anda dan tidak menyimpan basis data log makanan Anda di peladen (*server*) pusat. 

Sesuai dengan ketentuan Undang-Undang Pelindungan Data Pribadi (UU PDP), Anda memiliki kendali penuh secara mandiri atas data Anda:

1. **Hak Akses dan Informasi:** Anda memiliki akses langsung kapan saja untuk melihat, memeriksa, dan membaca seluruh riwayat nutrisi, inventaris *pantry*, dan data profil Anda secara langsung di dalam aplikasi.
2. **Hak Koreksi dan Pembaruan:** Anda dapat mengubah nama, email, kata sandi, maupun menyunting porsi serta takaran log makanan secara langsung melalui menu yang tersedia.
3. **Hak Penghapusan (*Right to Erasure*):** Anda berhak menghapus entri log makanan, item *pantry*, atau memusnahkan seluruh basis data lokal kapan pun tanpa memerlukan persetujuan manual dari admin.
4. **Hak Penarikan Persetujuan:** Anda berhak menghentikan pemrosesan data dengan cara keluar dari akun (*sign out*), mencabut otorisasi akun Google, atau mencopot pemasangan aplikasi dari perangkat Anda.
5. **Hak Portabilitas Data:** Seluruh catatan konsumsi dan nutrisi tersaji transparan di layar aplikasi untuk Anda tinjau atau catat secara mandiri kapan saja.

---

## 7. Retensi dan Penghapusan Data

* Data pribadi Anda disimpan di perangkat selama akun Anda aktif pada aplikasi FoodCura.
* Saat Anda menghapus entri log makanan atau item *pantry*, data tersebut seketika dihapus dari penyimpanan basis data lokal.
* Apabila Anda melakukan pembersihan data aplikasi (*Clear App Data*) atau menghapus instalan (*uninstall*) aplikasi, seluruh basis data lokal beserta catatan terkait akan terhapus dan musnah secara permanen dari perangkat Anda.

---

## 8. Privasi Anak

Layanan FoodCura tidak ditujukan untuk anak di bawah usia 13 (tiga belas) tahun tanpa bimbingan dan persetujuan dari orang tua atau wali yang sah. Kami tidak dengan sengaja mengumpulkan informasi pribadi dari anak-anak di bawah batas usia tersebut. Jika Anda mengetahui bahwa anak Anda telah memberikan data pribadi tanpa izin, silakan hubungi kami agar kami dapat segera mengambil tindakan penghapusan data.

---

## 9. Pemberitahuan Insiden Keamanan

Meskipun sebagian besar data disimpan secara *offline* di perangkat Anda, apabila terjadi kegagalan perlindungan data pribadi pada layanan terintegrasi yang berpotensi memengaruhi pengguna, kami berkomitmen untuk menyampaikan pemberitahuan resmi tertulis maksimal **3 x 24 jam** kepada pihak terdampak dan otoritas terkait sesuai ketentuan hukum yang berlaku.

---

## 10. Perubahan Kebijakan Privasi

Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu untuk menyesuaikan dengan perubahan operasional aplikasi atau regulasi perundang-undangan. Setiap perubahan akan diberitahukan dengan memperbarui tanggal "Terakhir Diperbarui" pada dokumen ini dan melalui notifikasi di dalam aplikasi.

---

## 11. Hubungi Kami

Jika Anda memiliki pertanyaan, saran, atau ingin mengajukan permohonan pelaksanaan hak data pribadi Anda, Anda dapat menghubungi kami melalui:

* **Email:** fauzil3710@gmail.com
* **GitHub Repository:** [https://github.com/fauzil-uf/foodcura](https://github.com/fauzil-uf/foodcura)
* **Pusat Bantuan & Isu:** [https://github.com/fauzil-uf/foodcura/issues](https://github.com/fauzil-uf/foodcura/issues)
