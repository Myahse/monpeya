import 'package:shared_preferences/shared_preferences.dart';

/// Products the user follows, kept on the device.
class GrenierFollowStore {
  static const _key = 'grenier.follows';

  Future<Set<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  Future<void> save(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.map((e) => '$e').toList());
  }
}
