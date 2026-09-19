abstract final class GrenierModuleKeys {
  static const grenier = 'mon-grenier';
  static const legacy = 'grenier';

  static bool isGrenierKey(String? key) {
    final k = (key ?? '').toLowerCase();
    return k == grenier || k == legacy || k == 'mon_grenier';
  }
}
