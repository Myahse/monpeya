const _monthsFr = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

/// `250 000 FCFA`, the way Mr Immo Location writes amounts; `—` when unknown.
String formatRentalAmount(double? amount) {
  if (amount == null) return '—';
  final s = amount.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '${buf.toString()} FCFA';
}

/// `23 oct. 2026`; `—` when unknown.
String formatRentalDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.day.toString().padLeft(2, '0')} ${_monthsFr[date.month - 1]} ${date.year}';
}
