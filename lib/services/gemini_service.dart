import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/quiz_model.dart';

/// Service AI edukasi kuis nutrisi dan pencegahan food waste.
///
/// Fitur utama:
/// 1. **Online Generation**: Menggunakan Google Gemini API untuk membuat 5 pertanyaan
///    kuis baru secara dinamis berdasarkan berbagai variasi topik.
/// 2. **Offline Fallback**: Menyediakan kumpulan soal offline terkurasi dengan opsi jawaban
///    panjang seimbang agar kuis tetap dapat dimainkan tanpa koneksi internet.
class GeminiService {
  static final GeminiService instance = GeminiService._();
  GeminiService._();

  final _rng = Random();

  /// Curated offline pool with balanced option lengths
  static const List<Map<String, dynamic>> _offlinePool = [
    {
      'question':
          'Mana tindakan yang paling membantu mengurangi food waste di rumah?',
      'options': [
        'Membeli banyak bahan saat ada diskon besar di supermarket',
        'Menyusun rencana menu dan daftar belanja sebelum ke pasar',
        'Membuang bahan makanan yang mendekati tanggal kadaluwarsa',
        'Menyimpan semua jenis sayuran dan buah dalam satu kantong',
      ],
      'correctAnswerIndex': 1,
      'explanation':
          'Menyusun rencana menu dan daftar belanja mencegah pembelian impulsif yang tidak terpakai.',
    },
    {
      'question':
          'Cara terbaik menyimpan sayuran hijau agar tetap segar lebih lama adalah…',
      'options': [
        'Mencuci bersih lalu menyimpannya saat daun masih basah',
        'Membungkusnya dengan tisu kering dalam wadah tertutup rapat',
        'Membiarkannya di tempat terbuka dalam kantong kresek hitam',
        'Menaruhnya berdampingan dengan buah apel di mangkuk meja',
      ],
      'correctAnswerIndex': 1,
      'explanation':
          'Tisu menyerap kelembaban berlebih yang menjadi penyebab utama sayuran membusuk.',
    },
    {
      'question':
          'Apa arti perbedaan label "Best Before" dan "Use By" pada makanan?',
      'options': [
        'Best Before batas keamanan konsumsi, Use By batas kualitas rasa',
        'Best Before batas kualitas rasa, Use By batas keamanan konsumsi',
        'Best Before untuk makanan beku, Use By untuk makanan kering',
        'Keduanya memiliki fungsi dan aturan konsumsi yang persis sama',
      ],
      'correctAnswerIndex': 1,
      'explanation':
          'Best Before mengacu pada kualitas/rasa terbaik, sedangkan Use By adalah batas akhir keamanan konsumsi.',
    },
    {
      'question':
          'Di manakah posisi terbaik di kulkas untuk menyimpan daging mentah?',
      'options': [
        'Rak pintu kulkas agar lebih mudah diambil saat akan dimasak',
        'Laci khusus sayuran agar terjaga kelembaban alami dagingnya',
        'Rak paling bawah karena merupakan area dengan suhu terdingin',
        'Rak paling atas karena suhunya paling stabil saat pintu dibuka',
      ],
      'correctAnswerIndex': 2,
      'explanation':
          'Rak paling bawah adalah zona terdingin (0–2°C) dan mencegah tetesan cairan ke makanan lain.',
    },
    {
      'question':
          'Mengapa nasi sisa semalam lebih cocok digunakan untuk nasi goreng?',
      'options': [
        'Kadar airnya berkurang sehingga butiran nasi tidak menggumpal',
        'Kadar gulanya menurun sehingga hasil gorengan lebih gurih',
        'Minyak goreng lebih mudah meresap ke dalam butiran nasinya',
        'Bakteri fermentasi alami membuat aromanya lebih sedap dimasak',
      ],
      'correctAnswerIndex': 0,
      'explanation':
          'Nasi dingin sudah kehilangan sebagian kadar air sehingga butirannya terpisah rapi saat ditumis.',
    },
    {
      'question':
          'Apa tujuan utama menerapkan sistem FIFO saat menata bahan makanan?',
      'options': [
        'Memisahkan bahan makanan matang dengan bahan makanan mentah',
        'Menggunakan bahan yang lebih dulu dibeli agar tidak terlupakan',
        'Membekukan semua jenis bahan masakan agar awet berbulan-bulan',
        'Membeli bahan dalam jumlah besar untuk menghemat biaya belanja',
      ],
      'correctAnswerIndex': 1,
      'explanation':
          'FIFO (First In, First Out) memastikan bahan yang lebih lama dibeli digunakan terlebih dahulu.',
    },
    {
      'question':
          'Berapa batas konsumsi gula harian yang dianjurkan Kemenkes (G4)?',
      'options': [
        'Maksimal 1 sendok makan per hari (setara dengan 15 gram)',
        'Maksimal 4 sendok makan per hari (setara dengan 50 gram)',
        'Maksimal 8 sendok makan per hari (setara dengan 100 gram)',
        'Tidak ada batasan selama berasal dari gula pasir murni',
      ],
      'correctAnswerIndex': 1,
      'explanation':
          'G4 menganjurkan batas konsumsi gula maksimal 4 sendok makan (50 gram) per orang per hari.',
    },
    {
      'question':
          'Mengapa minyak goreng jelantah yang menghitam berbahaya bagi tubuh?',
      'options': [
        'Minyak menyerap terlalu banyak air sehingga masakan jadi lembek',
        'Minyak mengandung radikal bebas dan lemak trans akibat oksidasi',
        'Minyak kehilangan rasa gurih aslinya sehingga masakan hambar',
        'Minyak menjadi terlalu kental sehingga sulit matang merata',
      ],
      'correctAnswerIndex': 1,
      'explanation':
          'Pemanasan berulang merusak struktur minyak dan menghasilkan radikal bebas pemicu penyakit.',
    },
    {
      'question':
          'Dalam panduan G4-G1-L5 Kemenkes, apa arti takaran G1 untuk garam?',
      'options': [
        'Maksimal 1 gram garam per orang dalam satu hari penuh',
        'Maksimal 1 sendok teh garam per hari (2.000 mg natrium)',
        'Maksimal 1 sendok makan garam untuk setiap porsi masakan',
        'Maksimal 1 bungkus bumbu instan untuk masakan harian',
      ],
      'correctAnswerIndex': 1,
      'explanation':
          'G1 berarti batas garam adalah 1 sendok teh per hari untuk menjaga tekanan darah normal.',
    },
    {
      'question':
          'Bagaimana cara terbaik menyimpan jahe segar agar tahan berminggu-minggu?',
      'options': [
        'Membiarkannya di atas meja dapur dalam ruangan terbuka',
        'Menyimpannya dalam wadah berair di kulkas atau dibekukan',
        'Merebusnya terlebih dahulu lalu menaruhnya di toples kedap',
        'Menguburnya di dalam toples beras kering di tempat gelap',
      ],
      'correctAnswerIndex': 1,
      'explanation':
          'Jahe segar awet disimpan dalam wadah berisi sedikit air di kulkas atau langsung dibekukan.',
    },
    {
      'question':
          'Apa manfaat utama membiasakan meal prep bagi pola makan sehari-hari?',
      'options': [
        'Menghilangkan kebutuhan membeli bahan segar setiap minggunya',
        'Mengontrol porsi nutrisi harian dan menghemat pengeluaran',
        'Memastikan makanan bisa bertahan hingga satu bulan di lemari',
        'Menggantikan peran sayuran segar dengan suplemen makanan',
      ],
      'correctAnswerIndex': 1,
      'explanation':
          'Meal prep mengontrol porsi makan sehat dan menghemat hingga 40% pengeluaran makanan.',
    },
    {
      'question':
          'Metode manakah yang paling aman untuk mencairkan daging beku?',
      'options': [
        'Merendamnya dalam air panas mendidih di atas api kompor',
        'Memindahkannya dari freezer ke rak kulkas semalam sebelumnya',
        'Mendiamkannya di atas meja dapur terbuka sepanjang hari',
        'Menjemurnya langsung di bawah terik matahari hingga mencair',
      ],
      'correctAnswerIndex': 1,
      'explanation':
          'Mencairkan di suhu kulkas (4°C) mencegah pertumbuhan bakteri berbahaya pada daging.',
    },
  ];

  List<QuizQuestion> _buildOfflineFallback() {
    final pool = List<Map<String, dynamic>>.from(_offlinePool);
    pool.shuffle(_rng);
    final picked = pool.take(5).toList();
    return picked.asMap().entries.map((e) {
      return QuizQuestion.fromJson(e.value, e.key + 1);
    }).toList();
  }

  Future<List<QuizQuestion>> generateQuiz() async {
    final apiKey = ApiConstants.geminiApiKey.trim();

    // Prioritaskan generate online jika API key tersedia
    if (apiKey.isNotEmpty) {
      final topics = [
        'pencegahan food waste dan cara menyimpan bahan makanan di kulkas',
        'nutrisi harian (protein, karbohidrat, lemak, dan kalori)',
        'keamanan pangan, batas kadaluwarsa, dan cara membaca label makanan',
        'teknik memasak sehat, porsi gizi seimbang, dan pemanfaatan bahan sisa',
        'panduan batas aman konsumsi gula, garam, dan minyak goreng',
      ];
      final topic = topics[_rng.nextInt(topics.length)];

      final prompt =
          '''
Buatkan 5 pertanyaan pilihan ganda edukatif bertema "$topic" dalam Bahasa Indonesia.

ATURAN WAJIB FORMAT OPSI JAWABAN:
1. Setiap pertanyaan memiliki tepat 4 opsi jawaban (A, B, C, D).
2. SANGAT PENTING: Panjang kalimat dan jumlah kata pada keempat opsi jawaban (A, B, C, D) harus SEIMBANG, SERAGAM, dan SEJAJAR.
3. DILARANG membuat jawaban yang benar menjadi opsi yang paling panjang, paling lengkap, atau paling detail, agar tidak mudah ditebak dari panjang karakternya.
4. Acak posisi index jawaban yang benar secara bervariasi (0, 1, 2, atau 3).
5. JANGAN membuat pertanyaan tentang serat (fiber). Fokus pada nutrisi utama (protein, karbohidrat, lemak, kalori, kolesterol), pencegahan food waste, dan penyimpanan bahan makanan.

Kembalikan HANYA array JSON murni:
[
  {
    "question": "teks pertanyaan",
    "options": ["opsi A", "opsi B", "opsi C", "opsi D"],
    "correctAnswerIndex": 0,
    "explanation": "penjelasan singkat padat mengapa jawaban tersebut benar"
  }
]
''';

      final models = [
        'gemini-3.5-flash',
        'gemini-3.7-flash',
        'gemini-3.1-flash-lite',
        'gemini-flash-latest',
      ];

      for (final model in models) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
          );

          final response = await http
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'contents': [
                    {
                      'parts': [
                        {'text': prompt},
                      ],
                    },
                  ],
                  'generationConfig': {
                    'response_mime_type': 'application/json',
                    'temperature': 0.7,
                  },
                }),
              )
              .timeout(const Duration(seconds: 25));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final String rawText =
                data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

            final start = rawText.indexOf('[');
            final end = rawText.lastIndexOf(']');
            final jsonStr = (start != -1 && end != -1 && end > start)
                ? rawText.substring(start, end + 1)
                : rawText.replaceAll(RegExp(r'```json\s*|```\s*'), '').trim();

            final List<dynamic> jsonList = jsonDecode(jsonStr);
            final List<QuizQuestion> questions = [];
            for (int i = 0; i < jsonList.length; i++) {
              questions.add(QuizQuestion.fromJson(jsonList[i], i + 1));
            }
            if (questions.isNotEmpty) return questions;
          }
        } catch (e) {
          // Lanjut coba model berikutnya jika model pertama gagal
          continue;
        }
      }
    }

    // Fallback ke kumpulan soal offline jika offline atau kuota/koneksi bermasalah
    return _buildOfflineFallback();
  }

  /// Evaluasi pola makan harian (AI Daily Nutrition Coach)
  Future<String> evaluateDailyNutrition({
    required int calories,
    required double protein,
    required double carbs,
    double fat = 0,
    double saturatedFat = 0,
    required double cholesterol,
  }) async {
    final effectiveFat = fat > 0 ? fat : saturatedFat;
    final apiKey = ApiConstants.geminiApiKey.trim();

    if (apiKey.isNotEmpty && calories > 0) {
      final prompt =
          '''
Sebagai Nutrition Coach cerdas di aplikasi FoodCura, berikan analisis singkat dan saran pola makan personal (maksimal 2-3 kalimat ramah dan solutif) berdasarkan data asupan harian berikut:
- Total Kalori: $calories kkal (Target: 2000 kkal)
- Protein: ${protein.toStringAsFixed(1)} g (Target: ~60 g)
- Karbohidrat: ${carbs.toStringAsFixed(1)} g (Target: ~300 g)
- Lemak: ${effectiveFat.toStringAsFixed(1)} g (Batas anjuran Kemenkes: maks 67 g)
- Kolesterol: ${cholesterol.toStringAsFixed(1)} mg (Batas aman: maks 300 mg)

Tuliskan evaluasi dalam Bahasa Indonesia yang santai, edukatif, dan langsung memberi solusi menu untuk makanan selanjutnya. Kembalikan teks saran langsung tanpa format JSON/markdown.
''';

      final models = [
        'gemini-3.5-flash',
        'gemini-3.7-flash',
        'gemini-3.1-flash-lite',
        'gemini-flash-latest',
      ];

      for (final model in models) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
          );

          final response = await http
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'contents': [
                    {
                      'parts': [
                        {'text': prompt},
                      ],
                    },
                  ],
                  'generationConfig': {'temperature': 0.7},
                }),
              )
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final String rawText =
                data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
            final cleanText = rawText.trim();
            if (cleanText.isNotEmpty) return cleanText;
          }
        } catch (_) {
          continue;
        }
      }
    }

    return _buildOfflineNutritionAdvice(
      calories: calories,
      protein: protein,
      fat: effectiveFat,
      cholesterol: cholesterol,
    );
  }

  String _buildOfflineNutritionAdvice({
    required int calories,
    required double protein,
    required double fat,
    required double cholesterol,
  }) {
    if (calories == 0) {
      return 'Belum ada makanan yang dicatat hari ini. Yuk catat makanan pertamamu untuk memantau kalori dan nutrisi seimbang!';
    }

    final issues = <String>[];
    if (fat > 67) {
      issues.add('asupan lemak sudah melewati batas anjuran Kemenkes (67g)');
    }
    if (cholesterol > 300) {
      issues.add('kadar kolesterol harian tergolong tinggi (>300mg)');
    }
    if (protein < 40 && calories > 1200) {
      issues.add('asupan protein masih rendah');
    }

    if (issues.isNotEmpty) {
      return 'Perhatian: ${issues.join(" dan ")}. Untuk menu berikutnya, prioritaskan lauk tinggi protein tanpa minyak seperti dada ayam rebus, tahu, tempe kukus, atau sayuran segar.';
    }

    if (calories > 2100) {
      return 'Total kalorimu hari ini sudah mencapai target harian ($calories kkal). Seimbangkan dengan konsumsi air putih yang cukup dan pilih camilan buah segar.';
    }

    return 'Pola makanmu hari ini cukup seimbang! Pertahankan kombinasi karbohidrat kompleks, protein, dan sayuran agar tubuh tetap bugar sepanjang hari.';
  }

  /// Menghasilkan insight dampak lingkungan saat menyelamatkan bahan makanan
  Future<String> generateEcoImpactInsight({
    required int rescuedCount,
    required int ecoPoints,
    required String lastRescuedItem,
  }) async {
    final apiKey = ApiConstants.geminiApiKey.trim();

    if (apiKey.isNotEmpty) {
      final prompt =
          '''
Pengguna aplikasi FoodCura baru saja berhasil mengolah dan menyelamatkan "$lastRescuedItem" dari kulkas sebelum tanggal kedaluwarsa.
Total bahan makanan yang terselamatkan sejauh ini: $rescuedCount bahan.
Total Eco Points: $ecoPoints poin.

Buatkan 1-2 kalimat apresiasi singkat, seru, dan memotivasi dalam Bahasa Indonesia yang menyoroti dampak nyata tindakannya bagi bumi (mencegah emisi gas metana/CO2e di TPA dan menghemat pengeluaran dapur). Langsung kembalikan teks tanpa format tanda kutip atau markdown.
''';

      final models = [
        'gemini-3.5-flash',
        'gemini-3.7-flash',
        'gemini-3.1-flash-lite',
        'gemini-flash-latest',
      ];

      for (final model in models) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
          );

          final response = await http
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'contents': [
                    {
                      'parts': [
                        {'text': prompt},
                      ],
                    },
                  ],
                  'generationConfig': {'temperature': 0.7},
                }),
              )
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final String rawText =
                data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
            final cleanText = rawText.trim();
            if (cleanText.isNotEmpty) return cleanText;
          }
        } catch (_) {
          continue;
        }
      }
    }

    return _buildOfflineEcoImpactInsight(
      lastRescuedItem: lastRescuedItem,
      rescuedCount: rescuedCount,
    );
  }

  String _buildOfflineEcoImpactInsight({
    required String lastRescuedItem,
    required int rescuedCount,
  }) {
    final estKgCO2 = (rescuedCount * 1.2).toStringAsFixed(1);
    final estRupiah = rescuedCount * 15000;
    return 'Luar biasa! Dengan menyelamatkan $lastRescuedItem, kamu telah mencegah sekitar $estKgCO2 kg emisi jejak karbon dan menghemat estimasi Rp ${estRupiah.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")} biaya belanja dapur.';
  }
}
