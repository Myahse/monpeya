/// Découpe le nom PeyaPay (`nomClient`) en nom / prénom pour l'API SIM.
abstract final class SimProfileUtil {
  SimProfileUtil._();

  /// CI / PeyaPay : premier mot = nom de famille, le reste = prénom(s).
  /// Ex. « KOUADIO INNOCENT » → nom `KOUADIO`, prénom `INNOCENT`.
  static ({String? nom, String? prenom}) splitDisplayName(String? raw) {
    final name = raw?.trim() ?? '';
    if (name.isEmpty) return (nom: null, prenom: null);

    final bits = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (bits.length == 1) {
      return (nom: bits.first, prenom: null);
    }
    return (nom: bits.first, prenom: bits.sublist(1).join(' '));
  }
}
