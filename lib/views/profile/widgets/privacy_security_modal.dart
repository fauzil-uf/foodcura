import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';

/// Modal interaktif Kebijakan Privasi & Keamanan Data FoodCura (UU PDP No. 27/2022).
class PrivacySecurityModal extends StatefulWidget {
  final VoidCallback? onAccept;

  const PrivacySecurityModal({super.key, this.onAccept});

  @override
  State<PrivacySecurityModal> createState() => _PrivacySecurityModalState();
}

class _PrivacySecurityModalState extends State<PrivacySecurityModal> {
  final ScrollController _scrollController = ScrollController();
  bool _hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 40 && !_hasReachedBottom) {
        setState(() {
          _hasReachedBottom = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDim,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.mintTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppColors.ecoGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Kebijakan Privasi',
                            style: AppTextStyles.headlineMd,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pembaruan: 31 Agustus 2026 · Versi 2.1.0',
                            style: AppTextStyles.subtitleSmall.copyWith(
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textGray,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.borderSoft),
              ],
            ),
          ),
          Expanded(
            child: RawScrollbar(
              controller: _scrollController,
              thumbColor: AppColors.primary.withValues(alpha: 0.3),
              radius: const Radius.circular(8),
              thickness: 4,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.infoContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Komitmen Privasi & Keamanan Data',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'FoodCura menghargai dan berkomitmen untuk melindungi privasi serta keamanan data pribadi Anda. Kebijakan ini disusun berdasarkan peraturan perundang-undangan Republik Indonesia (UU Pelindungan Data Pribadi & UU ITE).',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primaryDark,
                                    height: 1.4,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildSectionHeader(
                      number: '1',
                      title: 'Pendahuluan dan Kepatuhan Hukum',
                      icon: Icons.gavel_rounded,
                    ),
                    _buildParagraph(
                      'Kebijakan Privasi ini menjelaskan bagaimana FoodCura mengumpulkan, menggunakan, menyimpan, melindungi, dan menghapus informasi pribadi Anda saat menggunakan aplikasi mobile FoodCura.',
                    ),
                    _buildParagraph(
                      'Kebijakan ini disusun dan tunduk pada peraturan perundang-undangan yang berlaku di Republik Indonesia, termasuk Undang-Undang Nomor 27 Tahun 2022 tentang Pelindungan Data Pribadi (UU PDP), Undang-Undang Nomor 1 Tahun 2024 tentang Perubahan Kedua atas UU No. 11/2008 tentang Informasi dan Transaksi Elektronik (UU ITE), serta peraturan pelaksana terkait sistem elektronik. Kami bertindak sebagai Pengendali Data Pribadi (Data Controller) yang bertanggung jawab atas perlindungan data Anda.',
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      number: '2',
                      title: 'Informasi yang Kami Kumpulkan',
                      icon: Icons.folder_open_rounded,
                    ),
                    _buildParagraph(
                      'Kami mengumpulkan informasi yang diperlukan untuk menyediakan fungsi pelacak nutrisi harian dan pengelolaan inventaris bahan makanan secara optimal:',
                    ),
                    _buildSubHeader('a. Data yang Anda Berikan Secara Langsung:'),
                    _buildBulletItem(
                      'Informasi Akun',
                      'Nama lengkap atau nama pengguna, alamat surat elektronik (email), dan kredensial kata sandi saat pendaftaran lokal atau informasi profil dasar saat masuk melalui akun Google.',
                    ),
                    _buildBulletItem(
                      'Catatan Nutrisi & Pola Makan (Data Spesifik Kesehatan)',
                      'Log asupan makanan harian, takaran porsi, estimasi kalori, dan rincian makronutrisi (Protein, Karbohidrat, Lemak, Kolesterol) dari katalog resmi TKPI Kementerian Kesehatan RI yang Anda catat secara mandiri.',
                    ),
                    _buildBulletItem(
                      'Inventaris Bahan Makanan (Pantry)',
                      'Nama bahan makanan, jumlah/satuan, kategori penyimpanan (Kulkas, Freezer, Suhu Ruang), dan perkiraan tanggal kedaluwarsa.',
                    ),
                    _buildBulletItem(
                      'Aktivitas dan Gamifikasi',
                      'Catatan konsistensi hari aktif (streak) dan poin reward (Eco Points) yang diperoleh dari kuis edukasi pangan.',
                    ),
                    const SizedBox(height: 6),
                    _buildSubHeader('b. Informasi yang Dikumpulkan Secara Otomatis:'),
                    _buildBulletItem(
                      'Informasi Perangkat',
                      'Model perangkat, versi sistem operasi, resolusi layar, dan pengaturan bahasa sistem.',
                    ),
                    _buildBulletItem(
                      'Data Diagnostik',
                      'Catatan performa dan laporan crash non-identifikasi untuk pemeliharaan dan peningkatan stabilitas aplikasi.',
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      number: '3',
                      title: 'Dasar Hukum dan Tujuan Penggunaan Informasi',
                      icon: Icons.assignment_outlined,
                    ),
                    _buildParagraph(
                      'Pemrosesan data pribadi Anda dilakukan berdasarkan persetujuan sukarela yang Anda berikan (consent) serta kebutuhan operasional penyediaan layanan. Kami menggunakan informasi tersebut untuk:',
                    ),
                    _buildNumberedItem(
                      1,
                      'Menghitung asupan nutrisi harian dan membandingkannya dengan standar Angka Kecukupan Gizi (AKG).',
                    ),
                    _buildNumberedItem(
                      2,
                      'Memantau persediaan bahan makanan di dapur dan memberikan pengingat sebelum bahan makanan kedaluwarsa guna mengurangi limbah pangan (food waste).',
                    ),
                    _buildNumberedItem(
                      3,
                      'Mengirimkan notifikasi pengingat jadwal makan harian secara lokal di perangkat Anda.',
                    ),
                    _buildNumberedItem(
                      4,
                      'Menyediakan saran nutrisi yang dipersonalisasi dan pertanyaan kuis melalui bantuan kecerdasan buatan (AI Coach).',
                    ),
                    _buildNumberedItem(
                      5,
                      'Mengamankan akun dan mencegah akses yang tidak sah ke dalam aplikasi.',
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      number: '4',
                      title: 'Keamanan dan Penyimpanan Data',
                      icon: Icons.lock_outline_rounded,
                    ),
                    _buildParagraph(
                      'Kami menerapkan langkah-langkah keamanan teknis dan organisasional yang ketat untuk melindungi data pribadi Anda dari akses tidak sah, pengubahan, pengungkapan, atau penghapusan yang tidak sah:',
                    ),
                    _buildSecurityCard(
                      icon: Icons.storage_rounded,
                      title: 'Penyimpanan Lokal (Offline-First)',
                      description:
                          'Basis data utama catatan makanan, inventaris, dan preferensi Anda disimpan secara lokal pada perangkat Anda menggunakan SQLite yang aman dan terisolasi per akun pengguna (Scoped User ID).',
                    ),
                    const SizedBox(height: 8),
                    _buildSecurityCard(
                      icon: Icons.enhanced_encryption_rounded,
                      title: 'Enkripsi Kata Sandi Kriptografis',
                      description:
                          'Kata sandi akun Anda diacak secara permanen menggunakan algoritma one-way cryptographic hash SHA-256 dengan secret salt. Teks asli kata sandi Anda tidak pernah disimpan dalam sistem.',
                    ),
                    const SizedBox(height: 8),
                    _buildSecurityCard(
                      icon: Icons.https_rounded,
                      title: 'Enkripsi Saluran Komunikasi',
                      description:
                          'Seluruh komunikasi jaringan dengan layanan eksternal dienkripsi menggunakan protokol standar industri (TLS 1.3 / HTTPS).',
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      number: '5',
                      title: 'Pembagian Data dan Layanan Pihak Ketiga',
                      icon: Icons.cloud_done_outlined,
                    ),
                    _buildParagraph(
                      'Kami tidak pernah menjual, menyewakan, atau memperdagangkan data pribadi Anda kepada pihak ketiga mana pun untuk tujuan periklanan atau pemasaran komersial.',
                    ),
                    _buildParagraph(
                      'Aplikasi kami menggunakan beberapa layanan pihak ketiga terpercaya dengan batasan pemrosesan yang ketat:',
                    ),
                    _buildThirdPartyItem(
                      name: 'Google Play Services & Firebase Authentication',
                      purpose:
                          'Digunakan untuk autentikasi masuk dengan akun Google secara aman tanpa menyimpan kata sandi Google Anda di aplikasi kami.',
                    ),
                    _buildThirdPartyItem(
                      name: 'Google Gemini AI REST API',
                      purpose:
                          'Digunakan untuk fitur evaluasi nutrisi dan generator kuis gizi. Permintaan yang dikirimkan ke model AI hanya berisi data numerik gizi agregat dan nama bahan makanan anonim tanpa identitas pribadi (Non-PII). Nama, email, atau identitas Anda tidak pernah dikirimkan ke model AI.',
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      number: '6',
                      title:
                          'Hak-Hak Anda atas Data Pribadi (Kendali Penuh Mandiri)',
                      icon: Icons.manage_accounts_outlined,
                    ),
                    _buildParagraph(
                      'Karena FoodCura mengadopsi arsitektur Offline-First, seluruh data Anda tersimpan secara lokal di perangkat Anda sendiri. Tim Pengembang maupun pihak ketiga tidak memiliki akses jarak jauh (remote access) ke database lokal perangkat Anda dan tidak menyimpan basis data log makanan Anda di peladen (server) pusat.',
                    ),
                    _buildParagraph(
                      'Sesuai dengan ketentuan Undang-Undang Pelindungan Data Pribadi (UU PDP), Anda memiliki kendali penuh secara mandiri atas data Anda:',
                    ),
                    _buildBulletItem(
                      '1. Hak Akses dan Informasi',
                      'Anda memiliki akses langsung kapan saja untuk melihat, memeriksa, dan membaca seluruh riwayat nutrisi, inventaris pantry, dan data profil Anda secara langsung di dalam aplikasi.',
                    ),
                    _buildBulletItem(
                      '2. Hak Koreksi dan Pembaruan',
                      'Anda dapat mengubah nama, email, kata sandi, maupun menyunting porsi serta takaran log makanan secara langsung melalui menu yang tersedia.',
                    ),
                    _buildBulletItem(
                      '3. Hak Penghapusan (Right to Erasure)',
                      'Anda berhak menghapus entri log makanan, item pantry, atau memusnahkan seluruh basis data lokal kapan pun tanpa memerlukan persetujuan manual dari admin.',
                    ),
                    _buildBulletItem(
                      '4. Hak Penarikan Persetujuan',
                      'Anda berhak menghentikan pemrosesan data dengan cara keluar dari akun (sign out), mencabut otorisasi akun Google, atau mencopot pemasangan aplikasi dari perangkat Anda.',
                    ),
                    _buildBulletItem(
                      '5. Hak Portabilitas Data',
                      'Seluruh catatan konsumsi dan nutrisi tersaji transparan di layar aplikasi untuk Anda tinjau atau catat secara mandiri kapan saja.',
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      number: '7',
                      title: 'Retensi dan Penghapusan Data',
                      icon: Icons.auto_delete_outlined,
                    ),
                    _buildBulletItem(
                      'Masa Simpan (Retensi)',
                      'Data pribadi Anda disimpan di perangkat selama akun Anda aktif pada aplikasi FoodCura.',
                    ),
                    _buildBulletItem(
                      'Penghapusan Parsial',
                      'Saat Anda menghapus entri log makanan atau item pantry, data tersebut seketika dihapus dari penyimpanan basis data lokal.',
                    ),
                    _buildBulletItem(
                      'Pemusnahan Total',
                      'Apabila Anda melakukan pembersihan data aplikasi (Clear App Data) atau menghapus instalan (uninstall) aplikasi, seluruh basis data lokal beserta catatan terkait akan terhapus dan musnah secara permanen dari perangkat Anda.',
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      number: '8',
                      title: 'Perlindungan Privasi Anak',
                      icon: Icons.child_care_rounded,
                    ),
                    _buildParagraph(
                      'Layanan FoodCura tidak ditujukan untuk anak di bawah usia 13 (tiga belas) tahun tanpa bimbingan dan persetujuan dari orang tua atau wali yang sah. Kami tidak dengan sengaja mengumpulkan informasi pribadi dari anak-anak di bawah batas usia tersebut. Jika Anda mengetahui bahwa anak Anda telah memberikan data pribadi tanpa izin, silakan hubungi kami agar kami dapat segera mengambil tindakan penghapusan data.',
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      number: '9',
                      title: 'Pemberitahuan Insiden Keamanan',
                      icon: Icons.notification_important_outlined,
                    ),
                    _buildParagraph(
                      'Meskipun sebagian besar data disimpan secara offline di perangkat Anda, apabila terjadi kegagalan perlindungan data pribadi pada layanan terintegrasi yang berpotensi memengaruhi pengguna, kami berkomitmen untuk menyampaikan pemberitahuan resmi tertulis maksimal 3 x 24 jam kepada pihak terdampak dan otoritas terkait sesuai ketentuan hukum yang berlaku.',
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      number: '10',
                      title: 'Perubahan Kebijakan Privasi',
                      icon: Icons.update_rounded,
                    ),
                    _buildParagraph(
                      'Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu untuk menyesuaikan dengan perubahan operasional aplikasi atau regulasi perundang-undangan. Setiap perubahan akan diberitahukan dengan memperbarui tanggal "Terakhir Diperbarui" pada dokumen ini dan melalui notifikasi di dalam aplikasi.',
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      number: '11',
                      title: 'Hubungi Kami',
                      icon: Icons.mail_outline_rounded,
                    ),
                    _buildParagraph(
                      'Jika Anda memiliki pertanyaan, saran, atau ingin mengajukan permohonan pelaksanaan hak data pribadi Anda, Anda dapat menghubungi kami melalui:',
                    ),
                    _buildBulletItem(
                      'Surel (Email)',
                      'fauzil3710@gmail.com',
                    ),
                    _buildBulletItem(
                      'Repositori GitHub',
                      'github.com/fauzil-uf/foodcura',
                    ),
                    _buildBulletItem(
                      'Pusat Bantuan & Isu',
                      'github.com/fauzil-uf/foodcura/issues',
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '© 2026 FoodCura • Hak Cipta Dilindungi',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textGraySoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Disusun sesuai dengan peraturan perundang-undangan Republik Indonesia',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textGraySoft.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    widget.onAccept?.call();
                    Navigator.pop(context, true);
                  },
                  child: Text(
                    widget.onAccept != null
                        ? 'Saya Telah Membaca & Menyetujui'
                        : 'Saya Mengerti & Tutup',
                    style: AppTextStyles.buttonSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String number,
    required String title,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.mintTint,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: AppColors.ecoGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$number. $title',
              style: AppTextStyles.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.deepForest,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6, left: 2, right: 2),
      child: Text(
        title,
        style: AppTextStyles.bodyMd.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.deepForest,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
      child: Text(
        text,
        style: AppTextStyles.bodyMd.copyWith(
          color: AppColors.deepForest.withValues(alpha: 0.85),
          height: 1.5,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildNumberedItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 6, right: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1, right: 8),
            decoration: const BoxDecoration(
              color: AppColors.mintTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ecoGreen,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.deepForest.withValues(alpha: 0.9),
                height: 1.45,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 6, right: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 6, color: AppColors.ecoGreen),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.deepForest.withValues(alpha: 0.9),
                  height: 1.45,
                  fontSize: 12.5,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepForest,
                    ),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSecurityCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.mintTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.ecoGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepForest,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGray,
                    height: 1.35,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPartyItem({required String name, required String purpose}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.arrow_right_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.deepForest.withValues(alpha: 0.9),
                  height: 1.4,
                  fontSize: 12.5,
                ),
                children: [
                  TextSpan(
                    text: '$name — ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepForest,
                    ),
                  ),
                  TextSpan(text: purpose),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
