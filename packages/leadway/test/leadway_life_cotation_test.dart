import 'package:flutter_test/flutter_test.dart';
import 'package:leadway/src/data/models/leadway_life_cotation_response.model.dart';

void main() {
  group('LeadwayLifeCotationResult.withTierInputAmountFallback', () {
    LeadwayLifeCotationResult resultWithGross(num grossAmount) {
      return LeadwayLifeCotationResult.fromJson({
        'success': true,
        'data': {
          'subscriptionRef': 'SUB-001',
          'productCode': 'FUNERAIRES_DJOGANA',
          'status': 'QUOTED',
          'premium': {
            'gross': {'amount': grossAmount, 'currency': 'XOF'},
            'net': {'amount': 0, 'currency': 'XOF'},
            'tax': {'amount': 0, 'currency': 'XOF'},
            'frequency': 'MONTHLY',
            'breakdown': [],
          },
        },
      });
    }

    test('remplace gross.amount par tierInputAmount quand gross vaut 0', () {
      final result = resultWithGross(0).withTierInputAmountFallback(7500);

      expect(result.data.premium.gross.amount, 7500);
      expect(result.data.premium.gross.currency, 'XOF');
    });

    test('conserve gross.amount quand il est déjà renseigné', () {
      final result = resultWithGross(12000).withTierInputAmountFallback(7500);

      expect(result.data.premium.gross.amount, 12000);
    });

    test('ne modifie pas le résultat si tierInputAmount <= 0', () {
      final result = resultWithGross(0).withTierInputAmountFallback(0);

      expect(result.data.premium.gross.amount, 0);
    });
  });
}
