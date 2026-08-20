import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../database/db_helper.dart';
import '../../models/article_model.dart';
import '../dashboard/widgets/quiz_modal.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_top_bar.dart';
import 'widgets/article_detail_modal.dart';

class FoodInfoScreen extends StatefulWidget {
  const FoodInfoScreen({super.key});

  @override
  State<FoodInfoScreen> createState() => _FoodInfoScreenState();
}

class _FoodInfoScreenState extends State<FoodInfoScreen> {
  int _selectedCategory =
      0; // 0=Semua, 1=GIZI, 2=FOOD WASTE, 3=NUTRISI, 4=STORAGE, 5=RESEP RECOVERY
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _unreadNotifCount = 0;

  final List<String> _categories = [
    'Semua',
    'GIZI',
    'FOOD WASTE',
    'NUTRISI',
    'STORAGE',
    'RESEP RECOVERY',
  ];

  final List<ArticleModel> _allArticles = const [
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
          'Banyak orang menyimpan makanan di kulkas sembarangan dan bertanya-tanya kenapa makanan tetap cepat basi. Rahasianya ada pada zona suhu yang berbeda di setiap bagian kulkas.\n\nPeta zona suhu kulkas standar:\n\n1. Rak paling atas (suhu paling stabil, sekitar 3-4°C) — ideal untuk makanan siap santap, sisa masakan dalam wadah tertutup, dan minuman. Suhu di sini paling konsisten karena jarang terkena paparan langsung saat pintu dibuka.\n2. Rak tengah (sekitar 4°C) — cocok untuk produk olahan susu seperti keju, yogurt, dan susu UHT yang sudah dibuka. Juga tempat ideal untuk telur (meski rak pintu sering punya slot telur, suhunya kurang stabil).\n3. Rak paling bawah (paling dingin, sekitar 0-2°C) — simpan daging mentah, unggas, dan ikan mentah di sini. Jika ada tetesan cairan dari daging mentah, tidak akan mencemari makanan di bawahnya karena rak ini paling bawah.\n4. Crisper drawer (laci dengan kelembaban tinggi) — dirancang khusus untuk sayuran dan buah. Beberapa kulkas modern punya dua laci dengan pengaturan kelembaban berbeda untuk buah vs sayuran.\n5. Rak pintu (suhu paling hangat, sekitar 5-8°C) — hanya untuk bahan yang tahan suhu sedikit lebih tinggi seperti saus, selai, dan minuman.',
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
          'Bumbu dapur seperti jahe, kunyit, serai, dan daun salam sering dibeli dalam jumlah banyak namun hanya terpakai sedikit. Sisanya mengering dan akhirnya dibuang. Padahal dengan teknik yang tepat, semua bumbu ini bisa awet berminggu-minggu hingga berbulan-bulan.\n\nPanduan penyimpanan per jenis bumbu:\n\n1. Jahe dan kunyit segar — simpan dalam wadah berisi sedikit air di kulkas, atau kupas, iris tipis, lalu bekukan dalam kantong ziplock. Jahe beku bisa langsung diparut dari keadaan beku tanpa perlu dicairkan dulu.\n2. Serai — ikat beberapa batang bersama, bungkus dengan plastik wrap, dan simpan di freezer. Serai beku bisa langsung dimasukkan ke masakan tanpa dipotong terlebih dahulu.\n3. Daun salam dan daun jeruk purut — cuci, keringkan sempurna, lalu simpan dalam kantong ziplock di freezer. Tahan hingga 6 bulan dan aromanya tetap kuat.\n4. Bawang putih kupas — rendam dalam minyak zaitun di dalam jar kaca, simpan di kulkas. Berlaku selama 2 minggu dan minyaknya pun jadi beraroma bawang yang nikmat.\n5. Cabai segar — bekukan utuh tanpa perlu dipotong. Saat akan digunakan, ambil seperlunya dan iris langsung dalam kondisi setengah beku untuk hasil irisan yang lebih rapi.',
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
          'Serat adalah bagian tanaman yang tidak dapat dicerna oleh tubuh manusia, namun justru di situlah keajaibannya. Serat memainkan peran penting dalam menjaga kesehatan sistem pencernaan dan metabolisme secara keseluruhan.\n\nAda dua jenis serat dengan manfaat yang berbeda:\n\n1. Serat larut (soluble fiber) — larut dalam air dan membentuk gel di dalam usus. Gel ini memperlambat penyerapan gula darah sehingga kadar gula lebih stabil. Juga membantu menurunkan kadar kolesterol LDL. Sumber utama: oatmeal, apel, jeruk, kacang polong, dan biji chia.\n2. Serat tidak larut (insoluble fiber) — tidak larut dalam air dan berfungsi seperti sikat untuk membersihkan dinding usus. Memperlancar gerakan usus dan mencegah sembelit. Sumber utama: gandum utuh, brokoli, wortel, dan kulit buah.\n\nKenapa 25 gram per hari?\n\nOrganisasi Kesehatan Dunia (WHO) merekomendasikan minimal 25 gram serat per hari untuk orang dewasa. Namun survei menunjukkan rata-rata orang hanya mengonsumsi 13-15 gram per hari. Kekurangan serat jangka panjang dikaitkan dengan risiko kanker usus besar, diabetes tipe 2, dan penyakit jantung.\n\nCara mudah memenuhi kebutuhan serat harian: tambahkan sayuran ke setiap makan utama, pilih buah utuh daripada jus, dan ganti nasi putih dengan nasi merah minimal 3 kali seminggu.',
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
          'Buah yang terlalu matang seringkali langsung dibuang karena tampilannya tidak menarik lagi. Padahal buah yang sudah lunak justru memiliki kandungan gula alami yang lebih tinggi dan rasa yang lebih manis, menjadikannya bahan yang sempurna untuk berbagai olahan.\n\nIde olahan buah overripe:\n\n1. Banana bread — pisang yang kulitnya sudah menghitam adalah saat terbaik membuatnya menjadi banana bread. Teksturnya lebih lembab dan manis tanpa perlu menambah banyak gula.\n2. Smoothie beku — potong-potong pisang atau mangga yang sudah lembek, bekukan dalam kantong ziplock. Stok smoothie beku ini bisa tahan 2-3 bulan dan siap diblender kapan saja.\n3. Selai buah rumahan — rebus potongan buah (stroberi, mangga, atau jambu) dengan sedikit gula dan perasan lemon hingga mengental. Simpan dalam jar steril, tahan 2 minggu di kulkas.\n4. Overnight oats topping — hancurkan buah yang sudah lunak sebagai topping alami untuk oatmeal atau yogurt. Tidak perlu tambahan gula sama sekali.\n5. Nice cream — blender pisang beku hingga creamy, tambahkan sedikit susu. Hasilnya seperti es krim namun 100% dari buah tanpa lemak tambahan.',
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
          'Kementerian Kesehatan RI mengeluarkan panduan G4-G1-L5 sebagai patokan konsumsi harian yang aman untuk mencegah tiga penyakit tidak menular paling umum: hipertensi, diabetes mellitus, dan penyakit jantung koroner.\n\nPenjelasan detail setiap komponen:\n\n1. G4 — Gula maksimal 4 sendok makan per hari (setara 50 gram). Ingat bahwa gula tersembunyi juga ada di dalam minuman kemasan, saus, roti, dan camilan. Baca label nutrisi dengan teliti.\n2. G1 — Garam maksimal 1 sendok teh per hari (setara 2.000 mg natrium). Garam tersembunyi banyak ditemukan dalam makanan olahan, mie instan, dan kerupuk. Satu bungkus mie instan saja sudah mengandung hampir 1.500 mg natrium.\n3. L5 — Lemak maksimal 5 sendok makan per hari (setara 67 gram). Prioritaskan lemak tidak jenuh dari minyak zaitun, alpukat, dan kacang-kacangan. Batasi lemak jenuh dari gorengan dan produk hewani berlemak tinggi.\n\nTips praktis menerapkan G4-G1-L5:\n\n1. Kurangi minuman manis — ganti teh manis dan sirup dengan air putih atau infused water.\n2. Masak sendiri lebih sering — makanan rumahan jauh lebih mudah dikontrol kandungan gula, garam, dan lemaknya.\n3. Gunakan rempah sebagai pengganti garam — kunyit, jahe, serai, dan ketumbar bisa membuat masakan kaya rasa tanpa harus ditambah banyak garam.',
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
          'Meal prep adalah strategi menyiapkan sebagian atau seluruh komponen makanan di satu hari khusus (biasanya akhir pekan) sehingga sepanjang minggu kerja kamu hanya perlu merakit atau memanaskan makanan.\n\nMengapa meal prep efektif?\n\nPenelitian menunjukkan orang yang melakukan meal prep secara rutin menghabiskan 40% lebih sedikit untuk makanan, makan lebih bervariasi dan bergizi, serta jarang tergoda jajan sembarangan karena sudah ada makanan siap saji di rumah.\n\nPanduan meal prep untuk pemula:\n\n1. Pilih 2-3 protein utama — misalnya rebus 6 telur, panggang 500 gram dada ayam, dan goreng tempe. Simpan dalam wadah terpisah di kulkas.\n2. Siapkan karbohidrat base — nasi merah bisa dimasak dalam jumlah besar dan disimpan di kulkas hingga 4 hari. Kentang kukus atau ubi rebus juga bisa jadi alternatif.\n3. Potong sayuran — cuci dan potong brokoli, wortel, kacang panjang lalu simpan mentah di kulkas. Tumis atau kukus saat akan dimakan agar nutrisi tidak hilang.\n4. Buat saus serbaguna — satu batch bumbu balado atau saus teriyaki bisa mengubah rasa protein yang sama menjadi berbeda setiap hari.\n5. Gunakan wadah ukuran porsi — menggunakan meal prep container yang sudah dibagi-bagi membantu mengontrol porsi makan dan mempermudah pengambilan saat pagi yang buru-buru.',
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
          'Memakai minyak goreng berulang-ulang adalah kebiasaan umum di rumah tangga Indonesia untuk menghemat pengeluaran. Namun di balik penghematan itu tersimpan risiko kesehatan yang serius yang jarang disadari.\n\nApa yang terjadi pada minyak saat dipanaskan berulang kali?\n\nSetiap kali minyak dipanaskan, struktur molekulnya berubah. Proses oksidasi menghasilkan asam lemak trans dan radikal bebas yang berbahaya bagi sel tubuh. Semakin sering dipanaskan, semakin banyak senyawa berbahaya yang terakumulasi.\n\nTanda minyak sudah tidak layak pakai:\n\n1. Warna sudah cokelat tua hingga kehitaman — minyak segar berwarna kuning pucat atau jernih. Perubahan warna menandakan kerusakan molekul yang parah.\n2. Berbusa berlebihan saat dipanaskan — gelembung yang tidak wajar menandakan kontaminasi dan perubahan kimia minyak.\n3. Berbau tengik atau tidak segar — bau asam atau seperti cat adalah tanda oksidasi lanjutan.\n4. Berasap pada suhu rendah — minyak yang sudah rusak memiliki smoke point yang jauh lebih rendah dari normalnya.\n\nPanduan aman penggunaan minyak:\n\n1. Maksimal pakai 2-3 kali untuk minyak sawit, maksimal 1-2 kali untuk minyak kanola atau bunga matahari.\n2. Saring minyak setelah digunakan dengan saringan halus untuk membuang sisa remah yang mempercepat kerusakan.\n3. Jangan buang minyak jelantah ke saluran air — kumpulkan dalam botol bekas dan bawa ke bank sampah atau depo daur ulang terdekat.',
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
          'Batang brokoli, ujung wortel, batang seledri, dan kulit bawang bombay sering berakhir di tempat sampah. Padahal bagian-bagian ini mengandung konsentrasi mineral dan rasa gurih alami yang sangat tinggi.\n\nCara membuat kaldu sayur zero-waste:\n\n1. Kumpulkan sisa potongan sayur bersih dalam kantong ziplock di freezer selama seminggu.\n2. Ketika kantong sudah penuh, masukkan semua potongan sayur beku ke dalam panci besar.\n3. Tambahkan 2 liter air, 2 lembar daun salam, beberapa butir merica utuh, dan 1 siung bawang putih geprek.\n4. Rebus dengan api kecil (simmer) selama 45-60 menit hingga air menyusut dan berwarna keemasan.\n5. Saring kaldu sayur, buang ampasnya, dan simpan kaldunya dalam jar kaca di kulkas (tahan 5 hari) atau bekukan dalam cetakan es batu (tahan 3 bulan).\n\nKaldu ini bisa dijadikan dasar aneka sup, tumisan, atau pengganti air saat menanak nasi gurih.',
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
          'Pisang yang kulitnya sudah berbintik cokelat atau menghitam adalah bahan baku sempurna untuk pancake alami bebas gluten dan tanpa tambahan gula pasir.\n\nBahan:\n• 1 buah pisang ambon/cavendish matang ukuran besar\n• 2 butir telur ayam\n• Sejumput bubuk kayu manis (opsional)\n• 1/2 sdt minyak kelapa atau mentega untuk memanggang\n\nCara membuat:\n1. Haluskan pisang dengan garpu di dalam mangkuk hingga lembut.\n2. Masukkan 2 butir telur, kocok bersama pisang hingga tercampur rata.\n3. Panaskan wajan anti-lengket dengan api kecil, olesi sedikit minyak atau mentega.\n4. Tuang 2 sendok makan adonan, masak selama 2 menit hingga muncul gelembung kecil.\n5. Balik perlahan dan masak sisi lainnya selama 1 menit hingga kecokelatan.\n6. Sajikan hangat dengan potongan buah segar atau sedikit madu.',
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
          'Meskipun dibutuhkan dalam jumlah kecil dibandingkan makronutrien, mikronutrien (vitamin dan mineral) adalah pemicu ribuan reaksi enzimatik penting di dalam tubuh manusia.\n\nTiga mineral penting yang sering terabaikan:\n\n1. Zat Besi (Iron) — komponen utama hemoglobin pembawa oksigen ke seluruh sel tubuh. Kekurangan zat besi menyebabkan anemia, rasa lelah kronis, dan sulit berkonsentrasi. Sumber: bayam, hati ayam, daging sapi, dan kacang merah. Tip: konsumsi bersama vitamin C untuk meningkatkan penyerapan.\n2. Kalsium (Calcium) — bukan hanya untuk kepadatan tulang dan gigi, tapi juga penting untuk kontraksi otot jantung dan transmisi saraf. Sumber: teri kering, tahu, tempe, brokoli, dan yogurt.\n3. Seng (Zinc) — mineral kunci untuk sintesis DNA, penyembuhan luka, dan fungsi sel darah putih dalam melawan kuman penyakit. Sumber: telur, biji labu, kacang mete, dan makanan laut.',
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
          'Salah satu penyebab terbesar food waste rumah tangga adalah kebingungan membaca label tanggal kedaluwarsa pada kemasan makanan.\n\nPerbedaan mendasar:\n\n1. "Best Before" / "Baik Digunakan Sebelum" — mengacu pada KUALITAS dan rasa terbaik makanan. Setelah tanggal ini terlewati, makanan biasanya masih aman dikonsumsi asalkan kemasan utuh, tidak berbau aneh, dan teksturnya normal, meski rasanya mungkin sedikit berkurang. Umum ditemukan pada makanan kering, biskuit, dan makanan kaleng.\n2. "Use By" / "Batas Penggunaan" — mengacu pada KEAMANAN konsumsi. Makanan tidak boleh dikonsumsi setelah tanggal ini karena risiko pertumbuhan bakteri berbahaya. Umum ditemukan pada produk segar seperti susu pasteurisasi, daging segar, dan salad siap santap.\n\nPrinsip 3S sebelum membuang makanan berlabel Best Before: Lihat (Sight), Cium (Smell), dan Cicipi sedikit (Taste).',
    ),
  ];

  bool _showAllArticles = false;

  @override
  void initState() {
    super.initState();
    NotificationNotifier.instance.addListener(_onNotifChanged);
    NotificationNotifier.instance.refresh();
  }

  @override
  void dispose() {
    NotificationNotifier.instance.removeListener(_onNotifChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Callback untuk menyinkronkan counter lencana notifikasi belum terbaca.
  void _onNotifChanged() {
    if (mounted) {
      setState(() {
        _unreadNotifCount = NotificationNotifier.instance.value;
      });
    }
  }

  /// Membuka layar notifikasi saat ikon lonceng ditekan.
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  /// Membuka modal bacaan artikel edukasi lengkap beserta tips praktis pencegahan food waste.
  void _openArticleDetail(ArticleModel article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArticleDetailModal(article: article),
    );
  }

  /// Membuka modal kuis interaktif gizi dan food waste harian.
  void _startQuiz() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuizModal(),
    );
  }

  List<ArticleModel> get _filteredArticles {
    List<ArticleModel> list = _allArticles;

    // Filter daftar artikel berdasarkan kategori chip yang dipilih.
    if (_selectedCategory > 0 && _selectedCategory < _categories.length) {
      final selectedCat = _categories[_selectedCategory];
      list = list.where((a) => a.category == selectedCat).toList();
    }

    // Filter artikel berdasarkan kecocokan judul, kategori, atau ringkasan.
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

  /// Membangun tampilan utama FoodInfo yang mencakup bilah pencarian, filter kategori, artikel unggulan, daftar artikel, dan kuis edukasi.
  @override
  Widget build(BuildContext context) {
    // Pisahkan artikel pertama sebagai banner unggulan utama (Hero Featured Card).
    final featured = _filteredArticles.isNotEmpty
        ? _filteredArticles.first
        : null;

    // Sisa artikel selain banner utama dialokasikan ke daftar 'Artikel Terbaru'.
    final latestArticles = _filteredArticles.length > 1
        ? _filteredArticles.sublist(1)
        : <ArticleModel>[];

    // Batasi 2 artikel awal agar layar tetap ringkas dan kartu kuis AI di bawahnya langsung terlihat tanpa perlu scrolling panjang.
    final displayedLatestArticles = _showAllArticles
        ? latestArticles
        : latestArticles.take(2).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'FoodInfo',
              unreadNotifications: _unreadNotifCount,
              onNotificationTap: _openNotifications,
            ),

            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => NotificationNotifier.instance.refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),

                      _buildSearchBar(),

                      const SizedBox(height: 14),

                      _buildCategoryChips(),

                      const SizedBox(height: 24),

                      if (_filteredArticles.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 36,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.surfaceDim),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.menu_book_outlined,
                                size: 44,
                                color: AppColors.textGray,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada artikel ditemukan',
                                style: AppTextStyles.heading2.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coba ubah kata kunci pencarian atau pilih kategori lain.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textGray,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      if (featured != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pilihan Untukmu',
                              style: AppTextStyles.headlineSm.copyWith(
                                color: AppColors.deepForest,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mintTint,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Unggulan',
                                style: AppTextStyles.badgeText.copyWith(
                                  color: AppColors.ecoGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildFeaturedCard(featured),
                        const SizedBox(height: 28),
                      ],

                      if (latestArticles.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedCategory == 0
                                  ? 'Artikel Terbaru'
                                  : 'Artikel ${_categories[_selectedCategory]}',
                              style: AppTextStyles.headlineSm.copyWith(
                                color: AppColors.deepForest,
                              ),
                            ),
                            if (latestArticles.length > 2)
                              GestureDetector(
                                // Toggle ekspansi artikel tanpa perlu navigasi halaman baru (Progressive Disclosure).
                                onTap: () {
                                  setState(() {
                                    _showAllArticles = !_showAllArticles;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _showAllArticles
                                        ? AppColors.surfaceDim
                                        : AppColors.mintTint,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _showAllArticles
                                            ? 'Tampilkan Sedikit'
                                            : 'Lihat Semua (${latestArticles.length})',
                                        style: AppTextStyles.badgeText.copyWith(
                                          color: _showAllArticles
                                              ? AppColors.textGray
                                              : AppColors.ecoGreen,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(
                                        _showAllArticles
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: _showAllArticles
                                            ? AppColors.textGray
                                            : AppColors.ecoGreen,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...displayedLatestArticles.map(
                          (a) => _buildArticleListItem(a),
                        ),
                        const SizedBox(height: 28),
                      ],

                      _buildMiniQuizCard(),

                      const SizedBox(height: 28),

                      _buildDailyTipCard(),

                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun bilah pencarian artikel dengan ikon cari dan text field dinamis.
  Widget _buildSearchBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surfaceDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textGray, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {
                _searchQuery = val;
                // Reset ekspansi ke mode ringkas saat kata kunci pencarian berubah.
                _showAllArticles = false;
              }),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.deepForest,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Cari topik makanan, nutrisi...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGray,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun baris chip kategori horizontal untuk memfilter topik artikel.
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = index;
              // Reset ekspansi daftar ke 2 item saat beralih ke kategori lain.
              _showAllArticles = false;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.surfaceDim),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: AppTextStyles.chipText.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textGray,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Membangun kartu artikel unggulan utama dengan gambar besar dan badge kategori.
  Widget _buildFeaturedCard(ArticleModel article) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Image.network(
                  article.imageUrl,
                  height: 175,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 175,
                    color: AppColors.mintTint,
                    child: const Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 40,
                        color: AppColors.ecoGreen,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    article.category,
                    style: AppTextStyles.badgeText.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: AppTextStyles.button.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.readTime,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.summary,
                  style: AppTextStyles.bodySmall.copyWith(
                    height: 1.5,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _openArticleDetail(article),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Baca Artikel',
                        style: AppTextStyles.buttonSmall.copyWith(
                          fontSize: 12,
                          color: AppColors.ecoGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.ecoGreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun item baris artikel edukasi horizontal pada daftar artikel terbaru.
  Widget _buildArticleListItem(ArticleModel article) {
    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceDim),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                article.imageUrl,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 88,
                  height: 88,
                  color: AppColors.mintTint,
                  child: const Icon(Icons.article, color: AppColors.ecoGreen),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.category,
                    style: AppTextStyles.badgeText.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ecoGreen,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.title,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepForest,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${article.readTime} · ${article.date}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun kartu promosi kuis mini gizi dan food waste berlatar hijau emerald.
  Widget _buildMiniQuizCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.quiz,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'UJI PENGETAHUANMU',
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Mana yang paling membantu mengurangi food waste?',
                style: AppTextStyles.headlineSm.copyWith(
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih jawaban yang menurutmu benar.',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _startQuiz,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mulai Quiz',
                        style: AppTextStyles.buttonSmall.copyWith(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Membangun kartu tips praktis harian seputar penyimpanan bahan makanan.
  Widget _buildDailyTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintTint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.ecoGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FoodCura Tip',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepForest,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Simpan makanan yang akan kedaluwarsa lebih dulu di bagian depan kulkas agar tidak terlupakan.',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    height: 1.5,
                    color: AppColors.deepForest.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
