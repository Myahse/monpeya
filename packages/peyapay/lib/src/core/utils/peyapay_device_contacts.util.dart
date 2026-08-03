import 'package:flutter_contacts/flutter_contacts.dart';

/// Reads the device address book for transfer recipient selection.
Future<List<({String name, String phone})>> peyapayReadDeviceContacts({
  bool requestPermission = true,
}) async {
  if (requestPermission) {
    final ok = await FlutterContacts.requestPermission(readonly: true);
    if (!ok) return const [];
  }

  final raw = await FlutterContacts.getContacts(withProperties: true);
  final rows = <({String name, String phone})>[];

  for (final contact in raw) {
    final name = contact.displayName.trim();
    if (name.isEmpty || contact.phones.isEmpty) continue;

    for (final phoneEntry in contact.phones) {
      final phone = phoneEntry.number.trim();
      if (phone.isEmpty) continue;
      rows.add((name: name, phone: phone));
    }
  }

  return rows;
}
