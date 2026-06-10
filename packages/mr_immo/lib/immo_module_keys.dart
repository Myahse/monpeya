/// Stable keys for Mr Immo native modules (aligned with API + mobile apps).
abstract final class ImmoModuleKeys {
  static const rental = 'real-estate';
  static const construction = 'construction';
  static const collection = 'collection';

  static const all = [rental, construction, collection];

  static bool isImmoKey(String? key) => key != null && all.contains(key);
}
