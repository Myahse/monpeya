/// Stable keys for Billetterie native modules (aligned with API + catalog).
abstract final class BilletterieModuleKeys {
  static const transport = 'billetterie-transport';
  static const event = 'billetterie-event';

  /// Legacy single-module key — maps to transport.
  static const legacy = 'billetterie';

  static const all = [transport, event, legacy];

  static bool isBilletterieKey(String? key) =>
      key != null && all.contains(key);
}
