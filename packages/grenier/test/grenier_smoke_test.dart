import 'package:flutter_test/flutter_test.dart';
import 'package:grenier/grenier.dart';

void main() {
  test('brand and keys', () {
    expect(GrenierBrand.name, 'Mon Grenier');
    expect(GrenierModuleKeys.isGrenierKey('mon-grenier'), isTrue);
  });
}
