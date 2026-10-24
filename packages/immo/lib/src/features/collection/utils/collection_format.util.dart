/// `125000` → `125 000 FCFA`.
String formatFcfa(num amount) {
  final digits = amount.round().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]} ',
  );
  return '$grouped FCFA';
}

/// Short form for tight spots: `11998800` → `12 M FCFA`; under a million as [formatFcfa].
String formatFcfaShort(num amount) {
  if (amount.abs() < 1000000) return formatFcfa(amount);
  return '${formatNumber((amount / 100000).round() / 10)} M FCFA';
}

/// Shortest form, for a stat card a third of the width: `2274000` → `2,3 M F`, `850000` → `850 k F`.
String formatFcfaCompact(num amount) {
  final a = amount.abs();
  if (a >= 1000000) return '${formatNumber((amount / 100000).round() / 10)} M F';
  if (a >= 10000) return '${formatNumber((amount / 1000).round())} k F';
  return '${formatNumber(amount.round())} F';
}

/// `2012` → `2 012`, `4.5` → `4,5` (up to 2 decimals).
String formatNumber(num value) {
  final fixed = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  final parts = fixed.split('.');
  final grouped = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]} ',
  );
  return parts.length == 1 ? grouped : '$grouped,${parts[1]}';
}

/// `"2,5"` or `"2.5"` or `"2 500"` → number; null when empty or invalid.
double? parseNumber(String text) {
  final clean = text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
  return clean.isEmpty ? null : double.tryParse(clean);
}

/// `dd/MM/yyyy`.
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
