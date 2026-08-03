import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leadway/leadway.dart';

void main() {
  group('Leadway barrel exports', () {
    test('LeadwayHostBridge is accessible', () {
      expect(LeadwayHostBridge.onExitModule, isNull);
      expect(LeadwayHostBridge.onPayment, isNull);
    });

    test('LeadwayBrand constants', () {
      expect(LeadwayBrand.primary, const Color(0xFF006D56));
      expect(LeadwayBrand.onPrimary, isNotNull);
    });

    test('LeadwayApiConstants are defined', () {
      expect(LeadwayPaymentOperator.orange, 'orange');
      expect(LeadwayPaymentOperator.peyapay, 'peyapay');
      expect(LeadwayPaymentDefaults.agentCode, '0');
    });
  });

  group('Leadway enums', () {
    test('LeadwayProductCode has expected values', () {
      expect(LeadwayProductCode.tiersSimple.code, 'TIERS_SIMPLE');
      expect(LeadwayProductCode.tousRisques.name, 'Tous Risques');
      expect(LeadwayProductCode.values.length, 4);
    });

    test('LeadwayVehicleCategory has expected values', () {
      expect(LeadwayVehicleCategory.particular.value, 1);
      expect(LeadwayVehicleCategory.moto.value, 5);
    });

    test('LeadwayEnergy has expected values', () {
      expect(LeadwayEnergy.essence.code, 'ESSENCE');
      expect(LeadwayEnergy.diesel.code, 'DIESEL');
    });

    test('LeadwayWarranty has expected values', () {
      expect(LeadwayWarranty.rc.code, 'garantieRC');
      expect(LeadwayWarranty.values.length, 12);
    });

    test('LeadwayAssistanceLevel has expected values', () {
      expect(LeadwayAssistanceLevel.none.value, 0);
      expect(LeadwayAssistanceLevel.premium.value, 3);
    });

    test('LeadwayContractDuration has expected values', () {
      expect(LeadwayContractDuration.douzeMois.days, 365);
      expect(LeadwayContractDuration.unMois.days, 30);
    });

    test('LeadwayQuoteState has expected values', () {
      expect(LeadwayQuoteState.draft.code, 'Draft');
      expect(LeadwayQuoteState.approved.code, 'Approved');
    });
  });

  group('LeadwayQuoteValues', () {
    test('const and toJson round-trip', () {
      final qv = LeadwayQuoteValues(
        detailsPrime: const LeadwayDetailsPrime(
          primeNette: 140000,
          taxes: 0,
          accessoires: 2500,
          cedeao: 0,
          fga: 0,
          primeTtc: 150000,
          frais: 0,
        ),
        listeGaranties: const LeadwayListeGaranties(
          garantieRC: 100000,
          garantieDefenseRecours: 0,
          garantieBrisDeGlace: 0,
          garantieIncendie: 0,
          garantieVol: 0,
          garantieVolAccessoires: 0,
          garantieDommageCollision: 0,
          garantieDommagesTousAccidents: 0,
          garantieRecoursAnticipe: 0,
          garantieAssistanceAuto: 0,
          garantieVie: 0,
          garantieSecuriteRoutiere: 0,
        ),
      );
      final json = qv.toJson();
      expect(json['detailsPrime']['primeNette'], 140000);
      expect(json['listeGaranties']['garantieRC'], 100000);
    });
  });

  group('LeadwayQuoteResponse', () {
    test('fromJson parses response', () {
      final r = LeadwayQuoteResponse.fromJson({
        'quoteNo': 'Q-001',
        'id': 'ID-001',
        'quoteAmount': 150000,
      });
      expect(r.quoteNo, 'Q-001');
      expect(r.quoteAmount, 150000);
    });
  });

  group('LeadwayApiPaymentInitRequest', () {
    test('toJson produces correct map', () {
      final req = LeadwayApiPaymentInitRequest(
        quoteNo: 'Q-001',
        amount: 50000,
        operator: 'orange',
        phoneNo: '0102030405',
        email: 'alice@test.com',
        effectDate: '2024-06-01',
        agentCode: '0',
        deliveryLocation: 'Abidjan',
      );
      final json = req.toJson();
      expect(json['quoteNo'], 'Q-001');
      expect(json['amount'], 50000);
      expect(json['operator'], 'orange');
    });
  });

  group('LeadwayPremiumRequest', () {
    test('fromForm factory creates valid request', () {
      final req = LeadwayPremiumRequest.fromForm(
        ageVehicule: 3,
        valeurInitiale: 15000000,
        valeurVenale: 10000000,
        codeProduit: LeadwayProductCode.tiersSimple,
        categorieVehicule: LeadwayVehicleCategory.particular,
        dureeContratEnJour: 365,
        isVehiculeVTC: false,
        isGPS: false,
        garantieSecuriteRoutiere: false,
        garantieAssistanceAuto: 0,
        garantieVol: false,
        garantieVolAccessoires: false,
        garantieIncendie: false,
        garantieBrisDeGlace: false,
        garantieRecoursAnticipe: false,
        chargeUtile: 0,
        isTransportHydro: false,
        isTracteurRoutier: false,
        withRecoursAnticipe: false,
      );
      final json = req.toJson();
      expect(json['cotation'], isNotNull);
      expect(json['cotation']['vehicule']['codeProduit'], 'TIERS_SIMPLE');
    });
  });

  group('LeadwayApiPaymentCheckRequest', () {
    test('toJson produces correct map', () {
      final req = LeadwayApiPaymentCheckRequest(paymentId: 'PAY-001');
      expect(req.toJson()['paymentId'], 'PAY-001');
    });
  });
}
