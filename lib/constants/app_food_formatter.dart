/// Helper pemformat nama makanan dan takaran porsi (Food Tracker).
/// Mencegah penumpukan kurung ganda dan membedakan varian nama dari takaran porsi.
class AppFoodFormatter {
  AppFoodFormatter._();

  static final RegExp _portionUnitRegex = RegExp(
    r'^\s*(\d+(?:\.\d+)?)\s*(batang|buah|bungkus(?:\s+kecil)?|butir|cangkir|ekor(?:\s+sedang)?|gelas|genggam|keping|kotak|lempeng|lembar(?:\s+lauk)?|mangkok|pasang|porsi|potong|sdm|sdt|sendok\s*makan|sendok\s*teh|sendok|shot|stick|strip|tusuk|piring|gram|g|ml|kg)(?:\s*/\s*(\d+(?:\.\d+)?)\s*(g|ml|mg|ekor|tusuk|butir|keping|stick|strip))?\s*$',
    caseSensitive: false,
  );

  static final RegExp _mentahRegex = RegExp(
    r'^\s*(mentah)\s*/\s*(\d+(?:\.\d+)?)\s*(g|ml|mg)\s*$',
    caseSensitive: false,
  );

  /// Mengecek apakah teks dalam tanda kurung merupakan unit takaran porsi.
  static bool isPortionUnit(String text) {
    final t = text.trim();
    return _portionUnitRegex.hasMatch(t) || _mentahRegex.hasMatch(t);
  }

  /// Menghitung takaran porsi secara rapi dan mempertahankan varian nama makanan.
  static String formatFoodWithPortion(String rawName, double portion) {
    final clean = cleanDisplayName(rawName);
    if (portion <= 0 || portion == 1.0) {
      return clean;
    }

    final portionStr =
        portion % 1 == 0 ? portion.toInt().toString() : portion.toString();

    final match = RegExp(r'^(.*?)\s*\(([^)]+)\)$').firstMatch(clean);
    if (match != null) {
      final baseName = match.group(1)!.trim();
      final inner = match.group(2)!.trim();

      final unitMatch = _portionUnitRegex.firstMatch(inner);
      if (unitMatch != null) {
        final origNum = double.tryParse(unitMatch.group(1)!) ?? 1.0;
        final unitName = unitMatch.group(2)!;
        final hasSubUnit = unitMatch.group(3) != null;

        final newAmount = origNum * portion;
        final amountStr = newAmount % 1 == 0
            ? newAmount.toInt().toString()
            : newAmount.toStringAsFixed(1);

        if (hasSubUnit) {
          final origSubVal = double.tryParse(unitMatch.group(3)!) ?? 0.0;
          final subUnitName = unitMatch.group(4)!;
          final newSubVal = (origSubVal * portion).round();
          return '$baseName ($amountStr $unitName / $newSubVal$subUnitName)';
        }

        return '$baseName ($amountStr $unitName)';
      }

      final mentahMatch = _mentahRegex.firstMatch(inner);
      if (mentahMatch != null) {
        final prefix = mentahMatch.group(1)!;
        final origVal = double.tryParse(mentahMatch.group(2)!) ?? 100.0;
        final unit = mentahMatch.group(3)!;
        final newVal = (origVal * portion).round();
        return '$baseName ($prefix / $newVal$unit)';
      }

      return '$clean ($portionStr porsi)';
    }

    return '$clean ($portionStr porsi)';
  }

  /// Membersihkan nama makanan dari kurung ganda atau duplikasi porsi untuk tampilan UI.
  static String cleanDisplayName(String rawName) {
    final trimmed = rawName.trim();

    final doubleParenMatch =
        RegExp(r'^(.*?)\s*\(([^)]+)\)\s*\(([^)]+)\)$').firstMatch(trimmed);
    if (doubleParenMatch != null) {
      final baseName = doubleParenMatch.group(1)!.trim();
      final firstInner = doubleParenMatch.group(2)!.trim();
      final secondInner = doubleParenMatch.group(3)!.trim();

      if (isPortionUnit(firstInner) && isPortionUnit(secondInner)) {
        final portionMatch =
            RegExp(r'^(\d+(?:\.\d+)?)\s*porsi$', caseSensitive: false)
                .firstMatch(secondInner);
        if (portionMatch != null) {
          final portionVal = double.tryParse(portionMatch.group(1)!) ?? 1.0;
          return formatFoodWithPortion('$baseName ($firstInner)', portionVal);
        }
        return '$baseName ($secondInner)';
      }

      if (!isPortionUnit(firstInner) && isPortionUnit(secondInner)) {
        return trimmed;
      }
    }

    final tripleParenMatch =
        RegExp(r'^(.*?)\s*\(([^)]+)\)\s*\(([^)]+)\)\s*\(([^)]+)\)$')
            .firstMatch(trimmed);
    if (tripleParenMatch != null) {
      final base = tripleParenMatch.group(1)!.trim();
      final variant = tripleParenMatch.group(2)!.trim();
      final firstUnit = tripleParenMatch.group(3)!.trim();
      final secondUnit = tripleParenMatch.group(4)!.trim();

      if (isPortionUnit(firstUnit) && isPortionUnit(secondUnit)) {
        final portionMatch =
            RegExp(r'^(\d+(?:\.\d+)?)\s*porsi$', caseSensitive: false)
                .firstMatch(secondUnit);
        if (portionMatch != null) {
          final portionVal = double.tryParse(portionMatch.group(1)!) ?? 1.0;
          return formatFoodWithPortion(
            '$base ($variant) ($firstUnit)',
            portionVal,
          );
        }
      }
    }

    return trimmed;
  }
}
