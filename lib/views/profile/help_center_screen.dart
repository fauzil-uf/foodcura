import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../widgets/app_top_bar.dart';

class HelpFaqItem {
  final String question;
  final String answer;
  final IconData? icon;

  const HelpFaqItem({required this.question, required this.answer, this.icon});
}

class HelpFaqCategory {
  final String title;
  final IconData icon;
  final List<HelpFaqItem> items;

  const HelpFaqCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
}

/// Layar pusat bantuan pengguna yang menyajikan pencarian FAQ interaktif, kategori panduan, dan kanal kontak dukungan pelanggan.
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedQuestions = {};

  final List<HelpFaqCategory> _faqCategories = const [
    HelpFaqCategory(
      title: 'PERTANYAAN UMUM',
      icon: Icons.help_outline_rounded,
      items: [
        HelpFaqItem(
          question: 'Bagaimana cara menggunakan FoodCura?',
          answer:
              'FoodCura adalah asisten nutrisi dan pencegahan food waste terpadu. Aplikasi ini memiliki 3 fitur utama:\n\n'
              '1. **Food Tracker**: Catat konsumsi makanan harian dan pantau kalori serta makronutrisi harianmu.\n'
              '2. **Pantry Inventory**: Pantau stok bahan makanan di rumah lengkap dengan estimasi tanggal kedaluwarsa.\n'
              '3. **FoodInfo & Quiz**: Baca artikel informatif, tips dapur, dan ikuti mini kuis untuk mengumpulkan Eco Poin.',
        ),
        HelpFaqItem(
          question: 'Bagaimana cara mencatat makanan?',
          answer:
              'Untuk mencatat makanan:\n\n'
              '1. Buka tab **Tracker** pada bilah navigasi bawah.\n'
              '2. Tekan tombol **+ Catat Makanan** di bagian bawah layar.\n'
              '3. Pilih waktu makan (*Sarapan, Makan Siang, Makan Malam, atau Camilan*).\n'
              '4. Cari makanan dari katalog atau buat makanan kustom baru.\n'
              '5. Masukkan jumlah porsi lalu tekan **Simpan**.',
        ),
        HelpFaqItem(
          question: 'Bagaimana cara menambahkan makanan ke Inventory?',
          answer:
              'Untuk menambahkan bahan ke Pantry/Inventory:\n\n'
              '1. Buka tab **Pantry** pada bilah navigasi bawah.\n'
              '2. Tekan tombol **+ Tambah Bahan** di bagian bawah layar.\n'
              '3. Ketik nama bahan makanan (misal: *Bayam, Susu, Daging Ayam*).\n'
              '4. Masukkan jumlah & satuan, pilih lokasi simpan (*Kulkas, Freezer, atau Suhu Ruang*).\n'
              '5. Tentukan tanggal kedaluwarsa lalu tekan **Tambah Bahan**.',
        ),
        HelpFaqItem(
          question: 'Bagaimana cara mengatur tanggal kedaluwarsa?',
          answer:
              'Saat menambahkan atau mengedit bahan di Pantry, ketuk kolom **Tanggal kadaluwarsa** untuk memilih tanggal dari kalender. FoodCura akan otomatis menghitung sisa hari dan mengelompokkan bahan ke dalam status:\n\n'
              '• 🔴 **Harus Segera**: Kurang dari 2 hari.\n'
              '• 🟠 **Segera**: 3 sampai 5 hari.\n'
              '• 🟢 **Aman**: Lebih dari 5 hari.',
        ),
        HelpFaqItem(
          question: 'Bagaimana cara kerja Food Tracker?',
          answer:
              'Food Tracker menjumlahkan seluruh kalori dan makronutrisi (Karbohidrat, Protein, Lemak) dari makanan yang kamu catat setiap hari. Sistem membandingkannya dengan target harian rekomendasi kesehatan agar pola makanmu tetap seimbang.',
        ),
      ],
    ),
    HelpFaqCategory(
      title: 'NUTRISI',
      icon: Icons.eco_rounded,
      items: [
        HelpFaqItem(
          question: 'Dari mana data nutrisi FoodCura?',
          answer:
              'Data nutrisi FoodCura mengacu pada standar resmi **Tabel Komposisi Pangan Indonesia (TKPI)** dari Kementerian Kesehatan RI, serta basis data nutrisi internasional yang telah divalidasi oleh ahli gizi.',
        ),
        HelpFaqItem(
          question: 'Apa arti kalori dan kandungan nutrisi?',
          answer:
              '• **Kalori (kcal)**: Satuan energi yang diperoleh tubuh dari makanan untuk beraktivitas.\n'
              '• **Karbohidrat**: Sumber energi utama bagi otak dan otot.\n'
              '• **Protein**: Zat pembangun utama untuk regenerasi sel dan massa otot.\n'
              '• **Lemak**: Sumber cadangan energi dan pelarut vitamin penting (A, D, E, K).',
        ),
        HelpFaqItem(
          question: 'Bagaimana cara melihat detail nutrisi makanan?',
          answer:
              'Kamu dapat mengetuk item makanan apa pun di tab **Tracker** atau saat mencari makanan di katalog untuk melihat rincian lengkap informasi gizi, kalori per gram, dan persentase makronutrisinya.',
        ),
      ],
    ),
    HelpFaqCategory(
      title: 'FOOD WASTE',
      icon: Icons.delete_sweep_rounded,
      items: [
        HelpFaqItem(
          question: 'Bagaimana cara FoodCura membantu mengurangi food waste?',
          answer:
              'FoodCura memberikan visibilitas penuh terhadap stok bahan makanan di rumahmu. Dengan pengingat kedaluwarsa visual dan notifikasi cerdas, kamu diingatkan untuk mengolah bahan makanan sebelum rusak atau terbuang sia-sia.',
        ),
        HelpFaqItem(
          question: 'Bagaimana cara menandai bahan makanan telah digunakan?',
          answer:
              'Kamu dapat menekan tombol ceklis **(✓)** pada Radar Expiry di Dashboard atau menekan **"Tandai Habis/Digunakan"** di detail bahan Pantry setelah bahan tersebut selesai dimasak.',
        ),
        HelpFaqItem(
          question: 'Bagaimana cara kerja pengingat kedaluwarsa?',
          answer:
              'Sistem FoodCura secara otomatis memeriksa tanggal kedaluwarsa bahan di Pantry dan mengirimkan notifikasi pengingat pada H-3 dan H-1 sebelum kedaluwarsa agar kamu dapat segera mengolahnya.',
        ),
      ],
    ),
    HelpFaqCategory(
      title: 'AKUN & KEAMANAN',
      icon: Icons.security_rounded,
      items: [
        HelpFaqItem(
          question: 'Bagaimana cara mengubah data profil?',
          answer:
              'Buka tab **Profil** > tekan tombol **Edit Profil** (atau ikon pensil pada avatar) > ubah nama lengkap atau email > tekan **Simpan Perubahan**.',
        ),
        HelpFaqItem(
          question: 'Bagaimana cara mengganti password?',
          answer:
              'Buka tab **Profil** > pilih menu **Privasi & Keamanan** > ketuk **Ganti Password** > masukkan password saat ini dan password baru yang kuat > tekan **Perbarui Password**.',
        ),
        HelpFaqItem(
          question: 'Bagaimana cara mengubah pengaturan notifikasi?',
          answer:
              'Buka tab **Profil** > pilih menu **Pengaturan Notifikasi** > atur toggle aktif/nonaktif untuk pengingat kedaluwarsa bahan, pengingat waktu makan, dan tips harian sesuai preferensimu.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Mengubah status buka/tutup akordeon FAQ untuk pertanyaan tertentu.
  void _toggleQuestion(String question) {
    setState(() {
      if (_expandedQuestions.contains(question)) {
        _expandedQuestions.remove(question);
      } else {
        _expandedQuestions.add(question);
      }
    });
  }

  /// Membuka modal kontak dukungan pelanggan FoodCura.
  void _openContactSupport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildContactModal(ctx),
    );
  }

  /// Membangun modal kontak dengan opsi email, WhatsApp resmi, dan form pesan bantuan.
  Widget _buildContactModal(BuildContext ctx) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(ctx).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.mintTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.headset_mic_rounded,
                  color: AppColors.ecoGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hubungi Tim Dukungan',
                      style: AppTextStyles.headlineMd.copyWith(
                        fontSize: 18,
                        color: AppColors.deepForest,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kami siap melayani setiap hari 08.00 - 20.00 WIB',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildContactCard(
            icon: Icons.email_outlined,
            title: 'Email Dukungan',
            subtitle: 'support@foodcura.app',
            actionText: 'Salin Email',
            onTap: () {
              Clipboard.setData(
                const ClipboardData(text: 'support@foodcura.app'),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Alamat email berhasil disalin ke clipboard!'),
                  backgroundColor: AppColors.ecoGreen,
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildContactCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'WhatsApp Official',
            subtitle: '+62 812-3456-7890',
            actionText: 'Kirim Pesan',
            onTap: () {
              Clipboard.setData(const ClipboardData(text: '+6281234567890'));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nomor WhatsApp disalin (+6281234567890)'),
                  backgroundColor: AppColors.ecoGreen,
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildContactCard(
            icon: Icons.send_rounded,
            title: 'Kirim Pesan Masukan',
            subtitle: 'Kirim saran atau laporkan masalah teknis',
            actionText: 'Tulis Pesan',
            onTap: () {
              Navigator.pop(ctx);
              _showFeedbackDialog();
            },
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.surfaceDim),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Tutup',
                style: AppTextStyles.buttonSmall.copyWith(
                  color: AppColors.textGray,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun kartu opsi saluran kontak dengan aksi salin atau navigasi interaktif.
  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceDim),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepForest,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mintTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                actionText,
                style: AppTextStyles.badgeText.copyWith(
                  color: AppColors.ecoGreen,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Kirim Pesan Bantuan',
          style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tuliskan kendala atau pertanyaanmu secara detail:',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 4,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                hintText:
                    'Contoh: Saya mengalami kendala saat mencatat kalori...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGray,
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.surfaceDim),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.surfaceDim),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppTextStyles.buttonSmall.copyWith(
                color: AppColors.textGray,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Pesan Anda telah terkirim! Tim kami akan segera merespons.',
                  ),
                  backgroundColor: AppColors.ecoGreen,
                ),
              );
            },
            child: const Text('Kirim', style: AppTextStyles.buttonSmall),
          ),
        ],
      ),
    );
  }

  List<HelpFaqCategory> get _filteredCategories {
    if (_searchQuery.trim().isEmpty) {
      return _faqCategories;
    }
    final query = _searchQuery.toLowerCase().trim();
    final result = <HelpFaqCategory>[];

    for (final cat in _faqCategories) {
      final matchingItems = cat.items.where((item) {
        return item.question.toLowerCase().contains(query) ||
            item.answer.toLowerCase().contains(query);
      }).toList();

      if (matchingItems.isNotEmpty) {
        result.add(
          HelpFaqCategory(
            title: cat.title,
            icon: cat.icon,
            items: matchingItems,
          ),
        );
      }
    }
    return result;
  }

  /// Membangun antarmuka Pusat Bantuan dengan bilah pencarian FAQ, daftar kategori tanya-jawab, dan kartu kontak bantuan.
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCategories;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Pusat Bantuan',
              showBackButton: true,
              onBack: () => Navigator.pop(context),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    Text(
                      'Halo, ada yang bisa\nkami bantu?',
                      style: AppTextStyles.headlineLg.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepForest,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Temukan jawaban cepat seputar fitur dan penggunaan FoodCura.',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 13,
                        color: AppColors.textGray,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search Bar [ 🔍 Cari bantuan... ]
                    _buildSearchBar(),

                    const SizedBox(height: 24),

                    // Search Results Count (if searching)
                    if (_searchQuery.trim().isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          filtered.isEmpty
                              ? 'Tidak ada artikel yang cocok dengan "$_searchQuery"'
                              : 'Menampilkan hasil pencarian untuk "$_searchQuery"',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: filtered.isEmpty
                                ? AppColors.errorText
                                : AppColors.ecoGreen,
                          ),
                        ),
                      ),
                    ],

                    // FAQ Categories & Questions
                    if (filtered.isEmpty)
                      _buildEmptySearchResult()
                    else
                      ...filtered.map(
                        (category) => _buildCategorySection(category),
                      ),

                    const SizedBox(height: 16),

                    // MASIH BUTUH BANTUAN? Section
                    _buildStillNeedHelpSection(),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: AppColors.textGray, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.deepForest),
              decoration: InputDecoration(
                hintText: 'Cari bantuan...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGray,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.textGray,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildCategorySection(HelpFaqCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title (Uppercase with letter spacing)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              category.title,
              style: AppTextStyles.sectionHeader.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ecoGreen,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // FAQ Items Container
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceDim),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(category.items.length, (index) {
                  final item = category.items[index];
                  final isLast = index == category.items.length - 1;
                  final isExpanded =
                      _expandedQuestions.contains(item.question) ||
                      _searchQuery.trim().isNotEmpty;

                  return Column(
                    children: [
                      _buildFaqTile(item, isExpanded),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.surfaceDim,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(HelpFaqItem item, bool isExpanded) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: Key(item.question),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (_) => _toggleQuestion(item.question),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: Text(
          '›',
          style: AppTextStyles.headlineMd.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isExpanded ? AppColors.ecoGreen : AppColors.textGray,
          ),
        ),
        title: Text(
          item.question,
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 14,
            fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w600,
            color: isExpanded ? AppColors.primary : AppColors.deepForest,
            height: 1.35,
          ),
        ),
        trailing: AnimatedRotation(
          turns: isExpanded ? 0.25 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.chevron_right,
            size: 20,
            color: isExpanded ? AppColors.ecoGreen : AppColors.textGray,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceDim),
            ),
            child: _buildFormattedAnswer(item.answer),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedAnswer(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Rich Text parsing for **bold** text
      final spans = <TextSpan>[];
      final regex = RegExp(r'\*\*(.+?)\*\*');
      int lastEnd = 0;

      for (final match in regex.allMatches(trimmed)) {
        if (match.start > lastEnd) {
          spans.add(
            TextSpan(
              text: trimmed.substring(lastEnd, match.start),
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: AppColors.deepForest,
                height: 1.5,
              ),
            ),
          );
        }
        spans.add(
          TextSpan(
            text: match.group(1),
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.deepForest,
              height: 1.5,
            ),
          ),
        );
        lastEnd = match.end;
      }
      if (lastEnd < trimmed.length) {
        spans.add(
          TextSpan(
            text: trimmed.substring(lastEnd),
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
              color: AppColors.deepForest,
              height: 1.5,
            ),
          ),
        );
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: RichText(text: TextSpan(children: spans)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildStillNeedHelpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mintTint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ecoGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.ecoGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'MASIH BUTUH BANTUAN?',
                style: AppTextStyles.sectionHeader.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Punya pertanyaan yang belum terjawab atau kendala teknis? Tim kami siap membantu kamu kapan saja.',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
              color: AppColors.deepForest.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _openContactSupport,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.headset_mic_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hubungi Kami',
                    style: AppTextStyles.buttonSmall.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchResult() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.mintTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: AppColors.ecoGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pertanyaan Tidak Ditemukan',
            style: AppTextStyles.headlineMd.copyWith(
              fontSize: 16,
              color: AppColors.deepForest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coba gunakan kata kunci lain atau langsung hubungi tim dukungan kami.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              color: AppColors.textGray,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
