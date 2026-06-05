String formatFrMoneySigned(int amount) {
  final abs = amount.abs();
  final s = abs.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(' ');
  }
  return (amount < 0 ? '-' : '') + buf.toString();
}

String formatFrDateOnly(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year.toString();
  return '$d/$m/$y';
}

