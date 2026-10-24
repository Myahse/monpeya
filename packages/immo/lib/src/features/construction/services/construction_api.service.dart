import 'package:immo/src/features/construction/models/construction.site.dart';
import 'package:immo/src/features/construction/models/material_request.model.dart';
import 'package:immo/src/features/construction/models/metre.model.dart';
import 'package:immo/src/shared/models/immo_api.response.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';

abstract final class ConstructionApiEndpoints {
  static String sitesForUser(String userId) => '/api/chantiers/user/$userId';
  static String handover(String siteId) => '/api/chantiers/$siteId/handover';
  static String metre(String siteId) => '/api/chantiers/$siteId/metre';
  static String materialRequest(String siteId) => '/api/chantiers/$siteId/metre/demande';
  static String requestsForUser(String userId) => '/api/demandes/entreprise/$userId';
  static String decision(String requestId) => '/api/demandes/$requestId/decision';
  static const suppliers = '/api/demandes/fournisseurs';
  static String order(String requestId) => '/api/demandes/$requestId/commande';
  static String role(String userId) => '/api/chantiers/role/$userId';
  static String supplierOrders(String userId) => '/api/demandes/fournisseur/$userId/commandes';
  static String delivery(String requestId) => '/api/demandes/$requestId/livraison';
  static String shipping(String requestId) => '/api/demandes/$requestId/expedition';
  static String reception(String requestId) => '/api/demandes/$requestId/reception';
}

class ConstructionApiService {
  ConstructionApiService({ImmoApiClient? client})
      : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;

  Uri get base => _client.resolve('/api/construction');

  /// Chantiers the user follows (their enterprise's, or the ones they manage).
  Future<List<ConstructionSite>> fetchSites({required String userId}) async {
    final response = await _client.getJson(ConstructionApiEndpoints.sitesForUser(userId));
    final envelope = _envelope(response);
    if (envelope.hasError) {
      throw Exception(envelope.message ?? 'Chargement impossible');
    }
    return envelope.items
        .map(ConstructionSite.fromBackend)
        .where((s) => s.id.isNotEmpty)
        .toList();
  }

  /// Closes the chantier and turns it into a bien listed in Mr Immo Location.
  Future<ConstructionSite> handover({
    required String siteId,
    required String userId,
    double? monthlyRent,
  }) async {
    final response = await _client.postJson(
      ConstructionApiEndpoints.handover(siteId),
      body: {
        'data': {
          'userId': userId,
          'prix': ?monthlyRent,
        },
      },
    );
    final envelope = _envelope(response);
    if (envelope.hasError || envelope.item == null) {
      throw Exception(envelope.message ?? 'Passage en location refusé');
    }
    return ConstructionSite.fromBackend(envelope.item!);
  }

  /// The chantier's saved métré, or null when none was entered yet.
  Future<SiteMetre?> fetchMetre(String siteId) async {
    final envelope = _envelope(await _client.getJson(ConstructionApiEndpoints.metre(siteId)));
    if (envelope.hasError) throw Exception(envelope.message ?? 'Chargement impossible');
    return envelope.item == null ? null : SiteMetre.fromJson(envelope.item!);
  }

  /// Saves the dimensions and returns the computed materials.
  Future<SiteMetre> saveMetre({
    required String siteId,
    required String userId,
    required MetreInput input,
  }) async {
    final query = Uri(queryParameters: {'userId': userId}).query;
    final envelope = _envelope(await _client.postJson(
      '${ConstructionApiEndpoints.metre(siteId)}?$query',
      body: {'data': input.toJson()},
    ));
    if (envelope.hasError || envelope.item == null) {
      throw Exception(envelope.message ?? 'Calcul impossible');
    }
    return SiteMetre.fromJson(envelope.item!);
  }

  /// Sends the material lines as a demande "en attente" for the superviseur.
  Future<SiteMetre> requestMaterials({
    required String siteId,
    required String userId,
    required List<MaterialRequestLine> lines,
  }) async {
    final envelope = _envelope(await _client.postJson(
      ConstructionApiEndpoints.materialRequest(siteId),
      body: {
        'data': {
          'userId': userId,
          'lignes': [for (final l in lines) l.toJson()],
        },
      },
    ));
    if (envelope.hasError || envelope.item == null) {
      throw Exception(envelope.message ?? 'Demande non créée');
    }
    return SiteMetre.fromJson(envelope.item!);
  }

  /// Demandes of the user's enterprise chantiers, newest first.
  Future<List<MaterialRequest>> fetchRequests({required String userId}) async {
    final envelope = _envelope(await _client.getJson(ConstructionApiEndpoints.requestsForUser(userId)));
    if (envelope.hasError) throw Exception(envelope.message ?? 'Chargement impossible');
    return envelope.items.map(MaterialRequest.fromBackend).where((r) => r.id.isNotEmpty).toList();
  }

  /// Superviseur's answer: validate, or refuse with a reason.
  Future<MaterialRequest> decide({
    required String requestId,
    required String userId,
    required bool validate,
    String? reason,
  }) async {
    final envelope = _envelope(await _client.postJson(
      ConstructionApiEndpoints.decision(requestId),
      body: {
        'data': {
          'userId': userId,
          'decision': validate ? 'VALIDER' : 'REFUSER',
          'motif': ?reason,
        },
      },
    ));
    if (envelope.hasError || envelope.item == null) {
      throw Exception(envelope.message ?? 'Décision non enregistrée');
    }
    return MaterialRequest.fromBackend(envelope.item!);
  }

  Future<List<Supplier>> fetchSuppliers() async {
    final envelope = _envelope(await _client.getJson(ConstructionApiEndpoints.suppliers));
    if (envelope.hasError) throw Exception(envelope.message ?? 'Fournisseurs indisponibles');
    return envelope.items.map(Supplier.fromBackend).where((f) => f.id.isNotEmpty).toList();
  }

  /// Moyens généraux: orders a validated demande from [supplierId].
  Future<MaterialRequest> order({
    required String requestId,
    required String userId,
    required String supplierId,
    String? instruction,
  }) async {
    final envelope = _envelope(await _client.postJson(
      ConstructionApiEndpoints.order(requestId),
      body: {
        'data': {
          'userId': userId,
          'fournisseursId': supplierId,
          'instruction': ?instruction,
        },
      },
    ));
    if (envelope.hasError || envelope.item == null) {
      throw Exception(envelope.message ?? 'Commande non envoyée');
    }
    return MaterialRequest.fromBackend(envelope.item!);
  }

  /// Orders sent to the supplier the user is, newest first.
  Future<List<SupplierOrder>> fetchSupplierOrders({required String userId}) async {
    final envelope = _envelope(await _client.getJson(ConstructionApiEndpoints.supplierOrders(userId)));
    if (envelope.hasError) throw Exception(envelope.message ?? 'Commandes indisponibles');
    return envelope.items.map(SupplierOrder.fromBackend).where((o) => o.requestId.isNotEmpty).toList();
  }

  /// Supplier: the order is on its way, expected on [expectedOn] (a day, optional).
  Future<SupplierOrder> shipOrder({
    required String requestId,
    required String userId,
    DateTime? expectedOn,
  }) async {
    final envelope = _envelope(await _client.postJson(
      ConstructionApiEndpoints.shipping(requestId),
      body: {
        'data': {
          'userId': userId,
          if (expectedOn != null)
            'dateLivraisonPrevue': DateTime(expectedOn.year, expectedOn.month, expectedOn.day)
                .toIso8601String()
                .substring(0, 10),
        },
      },
    ));
    if (envelope.hasError || envelope.item == null) {
      throw Exception(envelope.message ?? 'Commande non mise en route');
    }
    return SupplierOrder.fromBackend(envelope.item!);
  }

  /// Chef de chantier: what arrived on site. [counted] maps an order line to the quantity
  /// counted; lines left out arrived in full.
  Future<SupplierOrder> receiveDelivery({
    required String requestId,
    required String userId,
    Map<String, int> counted = const {},
    String? comment,
  }) async {
    final envelope = _envelope(await _client.postJson(
      ConstructionApiEndpoints.reception(requestId),
      body: {
        'data': {
          'userId': userId,
          'lignes': [
            for (final MapEntry(key: line, value: quantity) in counted.entries)
              {'commandesId': line, 'quantiteRecue': quantity},
          ],
          'commentaire': ?comment,
        },
      },
    ));
    if (envelope.hasError || envelope.item == null) {
      throw Exception(envelope.message ?? 'Réception non enregistrée');
    }
    return SupplierOrder.fromBackend(envelope.item!);
  }

  /// Supplier: confirms the order was delivered; the chef de chantier then checks it on site.
  Future<SupplierOrder> confirmDelivery({
    required String requestId,
    required String userId,
    String? comment,
  }) async {
    final envelope = _envelope(await _client.postJson(
      ConstructionApiEndpoints.delivery(requestId),
      body: {
        'data': {'userId': userId, 'commentaire': ?comment},
      },
    ));
    if (envelope.hasError || envelope.item == null) {
      throw Exception(envelope.message ?? 'Livraison non confirmée');
    }
    return SupplierOrder.fromBackend(envelope.item!);
  }

  /// The user's niveau d'accès (CHEF_CHANTIER, SUPERVISEUR, MOYEN_GENERAUX…), or null.
  Future<String?> fetchRole({required String userId}) async {
    final envelope = _envelope(await _client.getJson(ConstructionApiEndpoints.role(userId)));
    if (envelope.hasError) return null;
    return envelope.item?['niveauAcces'] as String?;
  }

  ImmoBackendEnvelope _envelope(ImmoApiResponse<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      return ImmoBackendEnvelope(hasError: true, message: response.error);
    }
    final envelope = ImmoBackendEnvelope.fromJson(data);
    if (!response.success && !envelope.hasError) {
      return ImmoBackendEnvelope(hasError: true, message: envelope.message ?? response.error);
    }
    return envelope;
  }
}
