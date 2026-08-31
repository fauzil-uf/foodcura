import 'package:flutter/foundation.dart';

import '../models/article_model.dart';

// Daftar artikel edukasi gizi & food waste
const List<ArticleModel> _kArticles = [
  ArticleModel(
    id: 1,
    title: 'Cara Membuat Piring Makan Lebih Seimbang',
    category: 'GIZI',
    readTime: '4 menit membaca',
    date: '14 Agustus 2026',
    summary:
        'Kenali cara sederhana mengatur makanan agar kebutuhan nutrisi harian lebih seimbang.',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAFypRau3lSWeJML66J3XDOAGRgZkwEVIja4NCxr2fHa2MP9dG95HEE3wZ04yV1AL53mVPnYG7CWP_PKIzW7YY1-OH5lPjIZo96suRCJbpbdX_qgAQS8FKjt9xbLt-TB4geM1p74O210lAXfAdzBHU_-ayKZPiS1FXhE0seLOZ8lXAOtRf7bJON0qRj5QklhzCydZ9heWLE-ME24-JhVTo5ViFNKvMLVSvEz3Rz3NFzlsZLNoZ_Up3GMA',
    content:
        'Prinsip "Piring Makanku" yang dianjurkan oleh Kementerian Kesehatan RI adalah cara termudah untuk memastikan setiap makanan yang kamu konsumsi sudah seimbang secara nutrisi.\n\nPrinsip dasarnya sederhana: bagi piringmu menjadi empat bagian utama.\n\n1. Sayur dan Buah (setengah piring) — pilih sayuran berwarna-warni seperti brokoli, wortel, bayam, dan tomat untuk memastikan variasi vitamin dan mineral.\n2. Karbohidrat Kompleks (seperempat piring) — pilih nasi merah, kentang rebus, jagung, atau roti gandum yang lebih lambat dicerna sehingga rasa kenyang bertahan lebih lama.\n3. Protein (seperempat piring) — bisa dari hewani seperti ikan, ayam tanpa kulit, dan telur; atau nabati seperti tahu, tempe, dan kacang-kacangan.\n4. Cairan Cukup — minum 1 gelas air putih setiap kali makan untuk membantu penyerapan nutrisi.\n\nHindari kebiasaan makan sambil menonton layar karena dapat membuat kamu tidak sadar sudah makan terlalu banyak. Makan dengan sadar (mindful eating) membantu tubuh memberi sinyal kenyang lebih akurat.',
  ),
  ArticleModel(
    id: 2,
    title: '5 Cara Menyimpan Sayur Agar Tidak Cepat Terbuang',
    category: 'FOOD WASTE',
    readTime: '3 menit',
    date: '12 Agustus 2026',
    summary:
        'Trik mudah memelihara kesegaran sayuran di rumah untuk menekan jumlah makanan terbuang.',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCkd5YZnJ4hUnMb-HxaixYEw_vOBNcO_Zj4tE9_b0ahx5zINTEVODspecfoHIV48CbxeXoHxU85GTwJpx34jFSlW-0EhBqdVuvPpkXagFnRD5frHFxx4jBVHGX7Xy0urszwbirAkaJt-9hImPlZ3L5f5q5lL6mvQpbEtCvz1fJO2o0xcdPIqz9--p3sD2b0vzWHQZMVDyRqif3VAxsPwPyY_pnQKWZj4qSH8BJ6az3LgTE_Fq2TilVrXg',
    content:
        'Sayuran adalah bahan makanan yang paling cepat rusak jika tidak disimpan dengan benar. Data menunjukkan hampir 30% sayuran yang dibeli rumah tangga berakhir sebagai sampah karena metode penyimpanan yang salah.\n\nBerikut 5 cara mudah menjaga sayuran tetap segar lebih lama:\n\n1. Sayuran Hijau — bungkus kangkung, bayam, atau selada dengan tisu dapur kering sebelum dimasukkan ke wadah kedap udara. Tisu menyerap kelembaban berlebih yang menjadi penyebab utama pembusukan.\n2. Wortel dan Kentang — simpan di tempat sejuk, kering, dan gelap seperti laci bawah rak dapur. Hindari sinar matahari langsung karena mempercepat pertunasan.\n3. Cabai — lepaskan tangkainya, keringkan permukaannya, lalu beri alas tisu di dalam wadah sebelum dimasukkan kulkas. Tangkai yang dibiarkan bisa menjadi titik masuk jamur.\n4. Pisahkan buah penghasil etilen — apel, pisang, dan pir mengeluarkan gas etilen alami yang mempercepat pematangan bahan di sekitarnya. Simpan terpisah dari sayuran.\n5. Terapkan sistem FIFO — letakkan bahan yang lebih lama dibeli di bagian depan kulkas agar digunakan terlebih dahulu, sehingga tidak ada yang terlupakan di pojok belakang.',
  ),
  ArticleModel(
    id: 3,
    title: 'Protein: Apa Fungsinya untuk Tubuh?',
    category: 'NUTRISI',
    readTime: '4 menit',
    date: '11 Agustus 2026',
    summary:
        'Memahami peran krusial protein untuk perbaikan sel, imunitas, dan pembentukan massa otot.',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBZjjGPawQfLVj_M0Cp6Z1dw6PKCawGj2vpdslF8VHU3rKQAmKiHij3ZUfB_WoT7R9H2L-2xLtPB6YvVkLcqBWsW6pei5hiZDpwxvIPfkt7z36H5eKDi5U5PT3yAd3sSfikMmsJrZd8y9093Guq64WRc9W_fVn0uOK103AtmBFiGq_G_WL3HOjtxrpdI7LEqEIpiaFmi710I8ty51QkPNnbgH4bq4zGIUPcre5_677K0Pc6cfU2-vdfeA',
    content:
        'Protein adalah salah satu dari tiga makronutrien penting bersama karbohidrat dan lemak. Namun, protein memiliki peran yang sangat unik karena berfungsi sebagai "bata bangunan" bagi hampir seluruh struktur tubuh.\n\nFungsi utama protein dalam tubuh:\n\n1. Regenerasi sel — setiap sel di tubuhmu memiliki usia hidup tertentu. Protein digunakan untuk membangun sel-sel baru menggantikan yang mati, termasuk sel darah merah yang diganti setiap 120 hari.\n2. Produksi hormon dan enzim — hormon seperti insulin dan enzim pencernaan sepenuhnya tersusun dari protein. Kekurangan protein dapat mengganggu metabolisme secara keseluruhan.\n3. Kekebalan tubuh — antibodi yang melawan infeksi bakteri dan virus juga merupakan protein. Pola makan rendah protein bisa menurunkan daya tahan tubuh secara signifikan.\n4. Pembentukan otot — saat berolahraga, serat otot mengalami robekan kecil. Protein membantu memperbaiki dan memperkuat serat tersebut sehingga otot tumbuh lebih kuat.\n\nKebutuhan protein harian untuk orang dewasa rata-rata adalah 0,8 gram per kilogram berat badan. Untuk yang aktif berolahraga, kebutuhan bisa meningkat hingga 1,2 sampai 1,6 gram per kilogram.\n\nSumber protein berkualitas tinggi: dada ayam, ikan salmon, telur, tahu, tempe, edamame, dan kacang hitam.',
  ),
  ArticleModel(
    id: 4,
    title: 'Trik Menyimpan Daging & Ikan di Freezer Hingga 3 Bulan',
    category: 'STORAGE',
    readTime: '5 menit',
    date: '10 Agustus 2026',
    summary:
        'Panduan pembekuan daging sapi, ayam, dan ikan agar kualitas nutrisinya tetap terjaga.',
    imageUrl:
        'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=600&auto=format&fit=crop&q=80',
    content:
        'Membekukan daging dan ikan adalah cara paling efisien untuk menghemat pengeluaran belanja bulanan sekaligus mengurangi food waste. Jika dilakukan dengan benar, kualitas nutrisi daging yang dibekukan hampir sama dengan yang segar.\n\nLangkah-langkah membekukan protein hewani dengan benar:\n\n1. Potong sesuai porsi sekali masak — jangan bekukan dalam satu blok besar karena akan sulit dipotong saat beku dan memaksa kamu mencairkan lebih banyak dari yang dibutuhkan.\n2. Keringkan permukaannya — tepuk-tepuk daging dengan tisu dapur sebelum dikemas. Kelembaban berlebih pada permukaan daging menyebabkan kristal es besar yang merusak tekstur serat.\n3. Gunakan kantong ziplock freezer atau wadah vakum — buang udara sebanyak mungkin sebelum menutup. Udara yang terperangkap adalah penyebab utama freezer burn yang membuat daging kering dan pucat.\n4. Beri label tanggal — tulis tanggal pembekuan dengan spidol permanen. Panduan umum: daging sapi dan kambing tahan 3-4 bulan, ayam 2-3 bulan, dan ikan 1-2 bulan.\n5. Cairkan di kulkas, bukan di suhu ruang — memindahkan daging dari freezer ke rak kulkas (4°C) semalam sebelum dimasak adalah cara paling aman. Mencairkan di suhu ruang meningkatkan risiko pertumbuhan bakteri berbahaya.',
  ),
  ArticleModel(
    id: 5,
    title: 'Resep Nasi Goreng Rescue: Manfaatkan Sisa Bahan Dapur',
    category: 'RESEP RECOVERY',
    readTime: '6 menit',
    date: '09 Agustus 2026',
    summary:
        'Solusi kreatif mengolah sisa nasi dan potongan sayur menjadi hidangan lezat dan bernutrisi.',
    imageUrl:
        'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=600&auto=format&fit=crop&q=80',
    content:
        'Nasi goreng adalah "penyelamat dapur" paling fleksibel. Hidangan ini lahir memang dari tradisi memanfaatkan sisa nasi dan bahan-bahan yang hampir habis masa pakainya.\n\nMengapa nasi sisa lebih baik untuk nasi goreng?\n\nNasi yang baru matang memiliki kadar air tinggi sehingga mudah lengket dan menggumpal saat digoreng. Nasi dingin semalam sudah kehilangan sebagian besar kadar airnya dan butiran nasinya lebih mudah terpisah di wajan.\n\nBahan-bahan yang bisa kamu selamatkan:\n\n1. Sayuran sisa — wortel setengah, buncis 4-5 batang, atau potongan kol bisa langsung dicincang kasar dan ditumis bersama nasi.\n2. Protein sisa — potongan ayam goreng kemarin, telur yang hampir kedaluwarsa, atau udang beku bisa ditambahkan langsung.\n3. Bumbu darurat — bawang putih, kecap manis, dan sedikit garam sudah cukup. Tambahkan cabai rawit kalau suka pedas.\n\nCara membuat:\n\n1. Panaskan wajan dengan api sedang-tinggi, tambahkan 2 sendok makan minyak.\n2. Tumis bawang putih cincang sampai harum (30 detik).\n3. Masukkan sayuran keras seperti wortel, tumis 2 menit.\n4. Tambahkan protein, aduk rata.\n5. Masukkan nasi dingin, tekan-tekan dengan spatula agar butiran terpisah.\n6. Tambahkan kecap manis, garam, dan merica secukupnya.\n7. Buat lubang di tengah, masukkan telur dan orak-arik, lalu campur dengan nasi.',
  ),
  ArticleModel(
    id: 6,
    title: 'Mengenal Pembagian Zona Suhu Ideal di Dalam Kulkas',
    category: 'STORAGE',
    readTime: '4 menit',
    date: '08 Agustus 2026',
    summary:
        'Pahami mana rak kulkas paling dingin dan di mana letak terbaik menyimpan produk olahan susu.',
    imageUrl:
        'https://images.unsplash.com/photo-1584992236310-6edddc08acff?w=600&auto=format&fit=crop&q=80',
    content:
        'Banyak orang menyimpan makanan di kulkas sembarangan dan bertanya-tanya kenapa makanan tetap cepat basi. Rahasianya ada pada zona suhu yang berbeda di setiap bagian kulkas.\n\nPeta zona suhu kulkas standar:\n\n1. Rak paling atas (suhu paling stabil, sekitar 3-4°C) — ideal untuk makanan siap santap, sisa masakan dalam wadah tertutup, dan minuman.\n2. Rak tengah (sekitar 4°C) — cocok untuk produk olahan susu seperti keju, yogurt, dan susu UHT yang sudah dibuka.\n3. Rak paling bawah (paling dingin, sekitar 0-2°C) — simpan daging mentah, unggas, dan ikan mentah di sini.\n4. Crisper drawer (laci dengan kelembaban tinggi) — dirancang khusus untuk sayuran dan buah.\n5. Rak pintu (suhu paling hangat, sekitar 5-8°C) — hanya untuk bahan yang tahan suhu sedikit lebih tinggi seperti saus, selai, dan minuman.',
  ),
  ArticleModel(
    id: 7,
    title: 'Cara Mengawetkan Bumbu Dapur & Daun Aromatik Agar Segar',
    category: 'FOOD WASTE',
    readTime: '3 menit',
    date: '07 Agustus 2026',
    summary:
        'Tips menyimpan serai, daun jeruk, dan jahe agar tidak mengering dan tetap harum.',
    imageUrl:
        'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&auto=format&fit=crop&q=80',
    content:
        'Bumbu dapur seperti jahe, kunyit, serai, dan daun salam sering dibeli dalam jumlah banyak namun hanya terpakai sedikit.\n\n1. Jahe dan kunyit segar — simpan dalam wadah berisi sedikit air di kulkas, atau kupas, iris tipis, lalu bekukan dalam kantong ziplock.\n2. Serai — ikat beberapa batang bersama, bungkus dengan plastik wrap, dan simpan di freezer.\n3. Daun salam dan daun jeruk purut — cuci, keringkan sempurna, lalu simpan dalam kantong ziplock di freezer. Tahan hingga 6 bulan.\n4. Bawang putih kupas — rendam dalam minyak zaitun di dalam jar kaca, simpan di kulkas.\n5. Cabai segar — bekukan utuh tanpa perlu dipotong.',
  ),
  ArticleModel(
    id: 8,
    title: 'Serat & Pencernaan: Mengapa Tubuh Butuh 25g Serat Harian?',
    category: 'NUTRISI',
    readTime: '5 menit',
    date: '06 Agustus 2026',
    summary:
        'Manfaat serat makanan dalam mencegah sembelit, menjaga gula darah, dan kesehatan usus.',
    imageUrl:
        'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600&auto=format&fit=crop&q=80',
    content:
        'Serat adalah bagian tanaman yang tidak dapat dicerna oleh tubuh manusia, namun justru di situlah keajaibannya.\n\n1. Serat larut (soluble fiber) — larut dalam air dan membentuk gel di dalam usus, memperlambat penyerapan gula darah.\n2. Serat tidak larut (insoluble fiber) — berfungsi seperti sikat untuk membersihkan dinding usus dan mencegah sembelit.\n\nWHO merekomendasikan minimal 25 gram serat per hari untuk orang dewasa.',
  ),
  ArticleModel(
    id: 9,
    title: 'Cara Mengolah Buah Terlalu Matang Menjadi Smoothie & Selai',
    category: 'FOOD WASTE',
    readTime: '4 menit',
    date: '05 Agustus 2026',
    summary:
        'Jangan buang pisang atau mangga yang sudah lembek! Ubah menjadi camilan manis yang nikmat.',
    imageUrl:
        'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=600&auto=format&fit=crop&q=80',
    content:
        'Buah yang terlalu matang seringkali langsung dibuang karena tampilannya tidak menarik lagi.\n\n1. Banana bread — pisang berbintik cokelat adalah saat terbaik membuatnya menjadi banana bread.\n2. Smoothie beku — potong-potong pisang atau mangga yang sudah lembek, bekukan dalam kantong ziplock.\n3. Selai buah rumahan — rebus potongan buah dengan sedikit gula dan perasan lemon hingga mengental.\n4. Overnight oats topping — hancurkan buah yang sudah lunak sebagai topping alami.\n5. Nice cream — blender pisang beku hingga creamy, tambahkan sedikit susu.',
  ),
  ArticleModel(
    id: 10,
    title: 'Batas Aman Konsumsi Garam & Gula Menurut Kemenkes',
    category: 'GIZI',
    readTime: '4 menit',
    date: '04 Agustus 2026',
    summary:
        'Aturan G4-G1-L5: Batas konsumsi harian Gula 4 sendok makan, Garam 1 sendok teh, Lemak 5 sendok makan.',
    imageUrl:
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=600&auto=format&fit=crop&q=80',
    content:
        'Kementerian Kesehatan RI mengeluarkan panduan G4-G1-L5 sebagai patokan konsumsi harian yang aman.\n\n1. G4 — Gula maksimal 4 sendok makan per hari (setara 50 gram).\n2. G1 — Garam maksimal 1 sendok teh per hari (setara 2.000 mg natrium).\n3. L5 — Lemak maksimal 5 sendok makan per hari (setara 67 gram).',
  ),
  ArticleModel(
    id: 11,
    title: 'Trik Meal Prep Efektif untuk Pekerja Kantoran Sibuk',
    category: 'GIZI',
    readTime: '5 menit',
    date: '03 Agustus 2026',
    summary:
        'Hemat waktu dan uang dengan mempersiapkan bahan makanan seminggu sekali di hari Minggu.',
    imageUrl:
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop&q=80',
    content:
        'Meal prep adalah strategi menyiapkan sebagian atau seluruh komponen makanan di satu hari khusus.\n\n1. Pilih 2-3 protein utama.\n2. Siapkan karbohidrat base.\n3. Potong sayuran dan simpan mentah di kulkas.\n4. Buat saus serbaguna.\n5. Gunakan wadah ukuran porsi untuk kontrol kalori.',
  ),
  ArticleModel(
    id: 12,
    title: 'Minyak Goreng: Kapan Harus Dibuang & Risiko Pakai Berulang',
    category: 'STORAGE',
    readTime: '4 menit',
    date: '02 Agustus 2026',
    summary:
        'Kenali tanda minyak goreng jelantah yang merusak organ tubuh dan cara membuangnya dengan benar.',
    imageUrl:
        'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=600&auto=format&fit=crop&q=80',
    content:
        'Memakai minyak goreng berulang-ulang menghasilkan asam lemak trans dan radikal bebas yang berbahaya.\n\nTanda minyak sudah tidak layak pakai:\n1. Warna sudah cokelat tua hingga kehitaman.\n2. Berbusa berlebihan saat dipanaskan.\n3. Berbau tengik atau tidak segar.\n4. Berasap pada suhu rendah.',
  ),
  ArticleModel(
    id: 13,
    title: 'Sup Kaldu Sayur dari Sisa Batang & Kulit Umbi',
    category: 'RESEP RECOVERY',
    readTime: '5 menit',
    date: '01 Agustus 2026',
    summary:
        'Ubah sisa batang brokoli, kulit wortel, dan seledri menjadi kaldu sayur alami kaya rasa.',
    imageUrl:
        'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&auto=format&fit=crop&q=80',
    content:
        'Batang brokoli, ujung wortel, batang seledri, dan kulit bawang bombay sering berakhir di tempat sampah.\n\n1. Kumpulkan sisa potongan sayur bersih dalam kantong ziplock di freezer selama seminggu.\n2. Rebus dengan 2 liter air, daun salam, merica utuh, dan bawang putih geprek selama 45-60 menit.\n3. Saring dan simpan dalam jar kaca di kulkas (tahan 5 hari) atau bekukan dalam cetakan es batu.',
  ),
  ArticleModel(
    id: 14,
    title: 'Pancake Pisang 2 Bahan: Olah Pisang Terlalu Lembek',
    category: 'RESEP RECOVERY',
    readTime: '4 menit',
    date: '30 Juli 2026',
    summary:
        'Resep sarapan kilat sehat hanya dengan 2 butir telur dan 1 buah pisang matang tanpa tepung.',
    imageUrl:
        'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=600&auto=format&fit=crop&q=80',
    content:
        'Pisang yang kulitnya sudah berbintik cokelat adalah bahan baku sempurna untuk pancake alami bebas gluten.\n\nBahan: 1 pisang matang, 2 butir telur.\n\nCara membuat:\n1. Haluskan pisang dengan garpu.\n2. Kocok bersama telur.\n3. Masak di wajan anti-lengket 2 menit per sisi.',
  ),
  ArticleModel(
    id: 15,
    title: 'Mikronutrien Penting: Zat Besi, Kalsium & Seng',
    category: 'NUTRISI',
    readTime: '4 menit',
    date: '28 Juli 2026',
    summary:
        'Mengenal mineral esensial penjaga stamina, pembentukan sel darah, dan ketahanan imun.',
    imageUrl:
        'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600&auto=format&fit=crop&q=80',
    content:
        'Tiga mineral penting yang sering terabaikan:\n\n1. Zat Besi — komponen utama hemoglobin pembawa oksigen. Sumber: bayam, hati ayam, daging sapi.\n2. Kalsium — penting untuk kepadatan tulang dan kontraksi otot jantung. Sumber: teri kering, tahu, tempe, brokoli.\n3. Seng — mineral kunci untuk sintesis DNA dan penyembuhan luka. Sumber: telur, biji labu, kacang mete.',
  ),
  ArticleModel(
    id: 16,
    title: 'Panduan Membaca Label: Best Before vs Use By',
    category: 'FOOD WASTE',
    readTime: '3 menit',
    date: '26 Juli 2026',
    summary:
        'Pahami perbedaan tanggal batas rasa dan keamanan makanan agar tidak terburu-buru membuang makanan layak.',
    imageUrl:
        'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop&q=80',
    content:
        'Perbedaan mendasar:\n\n1. "Best Before" — mengacu pada KUALITAS. Makanan biasanya masih aman setelah tanggal ini jika kemasan utuh dan tidak berbau.\n2. "Use By" — mengacu pada KEAMANAN. Jangan konsumsi setelah tanggal ini.\n\nPrinsip 3S: Lihat (Sight), Cium (Smell), Cicipi sedikit (Taste).',
  ),
];

// Controller edukasi Food Info (filter kategori & pencarian artikel)
class FoodInfoController extends ChangeNotifier {
  static const List<String> categories = [
    'Semua',
    'GIZI',
    'FOOD WASTE',
    'NUTRISI',
    'STORAGE',
    'RESEP RECOVERY',
  ];

  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  bool _showAllArticles = false;

  // Getters
  int get selectedCategoryIndex => _selectedCategoryIndex;
  String get searchQuery => _searchQuery;
  bool get showAllArticles => _showAllArticles;

  /// Semua artikel yang sudah difilter berdasarkan kategori dan query pencarian.
  List<ArticleModel> get filteredArticles {
    List<ArticleModel> list = _kArticles;

    // Filter berdasarkan kategori chip yang dipilih.
    if (_selectedCategoryIndex > 0 &&
        _selectedCategoryIndex < categories.length) {
      final selectedCat = categories[_selectedCategoryIndex];
      list = list.where((a) => a.category == selectedCat).toList();
    }

    // Filter berdasarkan kecocokan judul, kategori, atau ringkasan.
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.category.toLowerCase().contains(q) ||
            a.summary.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  /// Artikel pertama dari hasil filter sebagai banner unggulan (Hero Card).
  ArticleModel? get featuredArticle =>
      filteredArticles.isNotEmpty ? filteredArticles.first : null;

  /// Artikel selain banner unggulan untuk daftar 'Artikel Terbaru'.
  List<ArticleModel> get latestArticles =>
      filteredArticles.length > 1 ? filteredArticles.sublist(1) : [];

  /// Artikel yang ditampilkan — dibatasi 2 jika belum expand, semua jika sudah expand.
  List<ArticleModel> get displayedLatestArticles =>
      _showAllArticles ? latestArticles : latestArticles.take(2).toList();

  /// Mengubah filter kategori artikel.
  void setCategory(int index) {
    if (_selectedCategoryIndex == index) return;
    _selectedCategoryIndex = index;
    // Reset expand saat kategori berubah agar tampilan konsisten.
    _showAllArticles = false;
    notifyListeners();
  }

  /// Mengubah kata kunci pencarian artikel.
  void setSearchQuery(String query) {
    _searchQuery = query;
    _showAllArticles = false;
    notifyListeners();
  }

  /// Toggle tampilkan semua artikel vs hanya 2 artikel pertama.
  void toggleShowAll() {
    _showAllArticles = !_showAllArticles;
    notifyListeners();
  }
}
