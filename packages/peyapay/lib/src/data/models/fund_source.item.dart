
class FundSourceItem {
  const FundSourceItem({
    required this.id,
    required this.name,
    this.logoAsset,
    this.isAdded = false,
  });

  final int id;
  final String name;
  final String? logoAsset;
  final bool isAdded;

  FundSourceItem copyWith({bool? isAdded}) => FundSourceItem(
        id: id,
        name: name,
        logoAsset: logoAsset,
        isAdded: isAdded ?? this.isAdded,
      );
}

/// CI banks (logos under `assets/logo/banks/`).
const peyapayBanks = <FundSourceItem>[
  FundSourceItem(id: 1, name: 'AFG BANK', logoAsset: 'assets/logo/banks/afg bank.png', isAdded: true),
  FundSourceItem(id: 2, name: 'AFRILAND FIRST BANK', logoAsset: 'assets/logo/banks/AFRILAND FIRST BANK.jpg', isAdded: true),
  FundSourceItem(id: 3, name: 'ATLANTIC BANK', logoAsset: 'assets/logo/banks/atlantic bank.jpg', isAdded: true),
  FundSourceItem(id: 4, name: 'BDA', logoAsset: 'assets/logo/banks/BDA.jpg', isAdded: true),
  FundSourceItem(id: 5, name: 'BGFI BANK', logoAsset: 'assets/logo/banks/BGFI BANK.png', isAdded: true),
  FundSourceItem(id: 6, name: 'BOA', logoAsset: 'assets/logo/banks/BOA.png', isAdded: true),
  FundSourceItem(id: 7, name: 'BRIDGE BANK', logoAsset: 'assets/logo/banks/Bridge bank.jpg', isAdded: false),
  FundSourceItem(id: 8, name: 'CITIBANK', logoAsset: 'assets/logo/banks/citibank-3.jpg', isAdded: false),
  FundSourceItem(id: 9, name: 'CORIS BANK', logoAsset: 'assets/logo/banks/CORIS.png', isAdded: false),
  FundSourceItem(id: 10, name: 'GTCO BANK', logoAsset: 'assets/logo/banks/GTCO BANK.jpg', isAdded: false),
  FundSourceItem(id: 11, name: 'MANSA BANK', logoAsset: 'assets/logo/banks/MANSA BANK.png', isAdded: false),
  FundSourceItem(id: 12, name: 'NSIA BANK', logoAsset: 'assets/logo/banks/NSIA-BANQUE-1.png', isAdded: false),
  FundSourceItem(id: 13, name: 'ORABANK', logoAsset: 'assets/logo/banks/orabank.jpeg', isAdded: false),
  FundSourceItem(id: 14, name: 'SGBCI', logoAsset: 'assets/logo/banks/SGBCI.jpg', isAdded: false),
  FundSourceItem(id: 15, name: 'STANDARD CHARTERED', logoAsset: 'assets/logo/banks/STANDARD CHARTERED.png', isAdded: false),
];

const peyapayDebitCards = <FundSourceItem>[
  FundSourceItem(id: 1, name: 'DJAMO', logoAsset: 'assets/logo/banks/DJAMO.jpg', isAdded: true),
  FundSourceItem(id: 2, name: 'PUSH', logoAsset: 'assets/logo/banks/PUSH.jpg', isAdded: true),
  FundSourceItem(id: 3, name: 'UBA', logoAsset: 'assets/logo/banks/UBA.png', isAdded: false),
];
