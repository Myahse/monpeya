import 'package:peyapay/src/data/models/peyapay_client_state.model.dart';
import 'package:peyapay/src/data/models/peyapay_gsm_search.model.dart';
import 'package:peyapay/src/data/models/peyapay_type_client.model.dart';

/// PeyaPay wallet account typing (`typcpt`, `estFournisseur`, `wtypeClient`).
abstract final class PeyapayAccountProfile {
  PeyapayAccountProfile._();

  /// Merchant / professionnel wallet in `datasCompte.typcpt`.
  static const merchantTypcpt = 'P';

  static bool isMerchantTypcpt(String? typcpt) =>
      typcpt?.trim().toUpperCase() == merchantTypcpt;

  /// `estFournisseur`: **O** = fournisseur (business-only when no client wallet).
  static bool isFournisseur(String? estFournisseur) =>
      estFournisseur?.trim().toUpperCase() == 'O';

  static bool isClientFournisseur(String? estFournisseur) =>
      estFournisseur?.trim().toUpperCase() == 'N';

  static bool isClientWtype(PeyapayTypeClient? wtypeClient) {
    if (wtypeClient == null) return false;
    if (isClientFournisseur(wtypeClient.estFournisseur)) return true;
    if (isFournisseur(wtypeClient.estFournisseur)) return false;
    return wtypeClient.isClientLabel ||
        wtypeClient.idwTypeClient == 1;
  }

  static List<String> readTypcptsFromAccounts(Object? accounts) =>
      PeyapayTypeClient.readTypcptsFromAccounts(accounts);

  static bool profileHasClientWallet({
    String? estFournisseur,
    PeyapayTypeClient? wtypeClient,
    List<String> typcpts = const [],
  }) {
    if (isClientFournisseur(estFournisseur)) return true;
    if (isFournisseur(estFournisseur) && typcpts.isEmpty) return false;
    if (isClientWtype(wtypeClient)) return true;
    if (typcpts.any((t) => !isMerchantTypcpt(t))) return true;
    return false;
  }

  static bool profileHasMerchantWallet({
    String? estFournisseur,
    PeyapayTypeClient? wtypeClient,
    List<String> typcpts = const [],
  }) {
    if (isFournisseur(estFournisseur)) return true;
    if (isFournisseur(wtypeClient?.estFournisseur)) return true;
    if (typcpts.any(isMerchantTypcpt)) return true;
    return false;
  }

  /// Resolves client vs merchant wallets for one phone (supports dual accounts).
  static ({bool hasClientWallet, bool hasMerchantWallet}) resolve({
    PeyapayClientState? sessionState,
    PeyapayGsmSearchResult? gsmSearch,
  }) {
    var hasClient = false;
    var hasMerchant = false;

    void merge({
      String? estFournisseur,
      PeyapayTypeClient? wtypeClient,
      List<String> typcpts = const [],
    }) {
      if (profileHasClientWallet(
        estFournisseur: estFournisseur,
        wtypeClient: wtypeClient,
        typcpts: typcpts,
      )) {
        hasClient = true;
      }
      if (profileHasMerchantWallet(
        estFournisseur: estFournisseur,
        wtypeClient: wtypeClient,
        typcpts: typcpts,
      )) {
        hasMerchant = true;
      }
    }

    final items = gsmSearch?.items ?? const <PeyapayGsmClientProfile>[];
    if (items.isNotEmpty) {
      for (final item in items) {
        merge(
          estFournisseur: item.estFournisseur,
          wtypeClient: item.wtypeClient,
          typcpts: item.typcpts,
        );
      }
    } else if (sessionState != null) {
      merge(
        estFournisseur: sessionState.estFournisseur,
        wtypeClient: sessionState.wtypeClient,
      );
    }

    return (hasClientWallet: hasClient, hasMerchantWallet: hasMerchant);
  }
}
