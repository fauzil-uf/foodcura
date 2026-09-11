//// Tingkat keparahan peringatan asupan nutrisi harian.
enum NutrientWarningSeverity {
  /// Peringatan waspada (misal: asupan nutrisi mendekati batas harian).
  caution,

  /// Peringatan bahaya atau tinggi (asupan nutrisi telah melampaui batas AKG harian).
  alert,
}

/// Model representasi data peringatan batas asupan nutrisi harian pengguna.
///
/// Model ini memisahkan data bisnis peringatan dari detail rendering UI (seperti Color atau Icon),
//// sehingga controller tetap murni dan mematuhi arsitektur MVC.
class NutrientWarningModel {
  /// Judul peringatan (misal: 'Peringatan Lemak Tinggi!').
  final String title;

  /// Pesan penjelasan rinci mengenai asupan dan anjuran kesehatan.
  final String message;

  /// Nama nutrisi yang diperingatkan (misal: 'Lemak', 'Kalori', 'Kolesterol').
  final String nutrient;

  /// Tingkat keparahan peringatan (caution atau alert).
  final NutrientWarningSeverity severity;

  const NutrientWarningModel({
    required this.title,
    required this.message,
    required this.nutrient,
    required this.severity,
  });
}
