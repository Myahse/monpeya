import 'package:flutter_test/flutter_test.dart';
import 'package:sim/sim.dart';

void main() {
  test('SimApiProducts subscription list is non-empty', () {
    expect(SimApiProducts.subscriptionSupported, isNotEmpty);
  });

  test('SimDevisRequest serializes', () {
    const req = SimDevisRequest(
      produit: SimApiProducts.relaxmoto,
      formule: SimApiFormules.mensuel,
      nombrePeriodes: 3,
    );
    expect(req.toJson()['produit'], 'relaxmoto');
    expect(req.toJson()['nombrePeriodes'], 3);
  });

  test('formule options use libelleVariante for accident products', () {
    const product = SimProduitCatalogue(
      code: 'relaxaccidents_fraismedicaux',
      libelle: 'RelaxAccidents',
      actifPourPartenaire: true,
      kycRequis: true,
      tauxCommissionApi: 0.1,
      formules: [
        SimFormule(
          libelleVariante: 'Formule A',
          prime: 5000,
          capitalGaranti: 100000,
        ),
        SimFormule(
          libelleVariante: 'Formule B',
          prime: 8000,
          capitalGaranti: 200000,
        ),
      ],
    );

    final options = product.formuleOptions();
    expect(options.map((o) => o.value), ['Formule A', 'Formule B']);
  });

  test('formule options use cycleFacturation for moto/auto', () {
    const product = SimProduitCatalogue(
      code: 'relaxmoto',
      libelle: 'RelaxMoto',
      actifPourPartenaire: true,
      kycRequis: true,
      tauxCommissionApi: 0.1,
      formules: [
        SimFormule(
          libelleVariante: 'Mensuel',
          cycleFacturation: 'mensuel',
          prime: 2500,
          capitalGaranti: 500000,
        ),
        SimFormule(
          libelleVariante: 'Annuel',
          cycleFacturation: 'annuel',
          prime: 25000,
          capitalGaranti: 500000,
        ),
      ],
    );

    final options = product.formuleOptions();
    expect(options.map((o) => o.value), ['mensuel', 'annuel']);
  });

  test('splitDisplayName maps PeyaPay nomClient to nom and prenom', () {
    final parts = SimProfileUtil.splitDisplayName('KOUADIO INNOCENT');
    expect(parts.nom, 'KOUADIO');
    expect(parts.prenom, 'INNOCENT');
  });

  test('splitDisplayName handles multi-word prenom', () {
    final parts = SimProfileUtil.splitDisplayName('DIOMANDE Tini Yacou');
    expect(parts.nom, 'DIOMANDE');
    expect(parts.prenom, 'Tini Yacou');
  });
}
