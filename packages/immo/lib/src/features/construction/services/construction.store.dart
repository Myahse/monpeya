import 'package:flutter/foundation.dart';

import 'package:immo/src/features/construction/models/construction.site.dart';
import 'package:immo/src/features/construction/models/material_request.model.dart';
import 'package:immo/src/features/construction/models/metre.model.dart';
import 'package:immo/src/features/construction/services/construction_api.service.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';

/// Chantiers shared by the Construction tabs (they stay alive in an IndexedStack).
class ConstructionStore extends ChangeNotifier {
  ConstructionStore({required ImmoApiClient client})
      : _api = ConstructionApiService(client: client);

  final ConstructionApiService _api;

  String? _userId;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  List<ConstructionSite> _sites = const [];
  List<MaterialRequest> _requests = const [];
  String? _accessLevel;
  List<Supplier>? _suppliers;
  List<SupplierOrder>? _supplierOrders;
  String? _supplierError;

  /// A supplier screen asked for its orders; (re)loaded with every refresh.
  bool _supplierOrdersWanted = false;

  bool get signedIn => _userId != null;
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;
  List<ConstructionSite> get sites => _sites;

  /// Demandes of the enterprise's chantiers (superviseur's queue, chef's follow-up).
  List<MaterialRequest> get requests => _requests;

  /// The user's niveau d'accès from the backend (CHEF_CHANTIER, SUPERVISEUR…), once known.
  String? get accessLevel => _accessLevel;

  /// Supplier view: orders sent to them (null until loaded).
  List<SupplierOrder>? get supplierOrders => _supplierOrders;
  String? get supplierError => _supplierError;

  /// Loads for [userId]; a null id (guest) clears everything.
  Future<void> load(String? userId) async {
    _userId = (userId == null || userId.isEmpty) ? null : userId;
    if (_userId == null) {
      _sites = const [];
      _requests = const [];
      _accessLevel = null;
      _supplierOrders = null;
      _loaded = true;
      _error = null;
      notifyListeners();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) return;
    _loading = true;
    notifyListeners();
    // Demandes load on their own: if they fail, the chantiers must still show.
    final requests = _api
        .fetchRequests(userId: userId)
        .then<List<MaterialRequest>?>((r) => r, onError: (Object _) => null);
    final role = _api.fetchRole(userId: userId).then<String?>((r) => r, onError: (Object _) => null);
    try {
      _sites = await _api.fetchSites(userId: userId);
      _error = null;
    } catch (e) {
      _error = _message(e);
    } finally {
      _requests = await requests ?? _requests;
      _accessLevel = await role ?? _accessLevel;
      if (_supplierOrdersWanted) await _fetchSupplierOrders(userId);
      _loading = false;
      _loaded = true;
      notifyListeners();
    }
  }

  /// Returns null on success, or the message to show.
  Future<String?> handover(ConstructionSite site, {double? monthlyRent}) async {
    final userId = _userId;
    if (userId == null) return _signIn;
    try {
      final updated = await _api.handover(
        siteId: site.id,
        userId: userId,
        monthlyRent: monthlyRent,
      );
      _sites = [for (final s in _sites) s.id == updated.id ? updated : s];
      notifyListeners();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  /// The chantier's saved métré (null when none yet), or the message to show.
  Future<({SiteMetre? metre, String? error})> loadMetre(ConstructionSite site) async {
    try {
      return (metre: await _api.fetchMetre(site.id), error: null);
    } catch (e) {
      return (metre: null, error: _message(e));
    }
  }

  /// The drawn métré a demande was raised from: the chantier's latest métré, only
  /// when this demande is the one it created. Null otherwise, and when it can't be read.
  Future<SiteMetre?> metreOfRequest(MaterialRequest request) async {
    final siteId = request.siteId;
    if (siteId == null) return null;
    try {
      final metre = await _api.fetchMetre(siteId);
      return metre != null && metre.requestId == request.id && metre.input.plan != null ? metre : null;
    } catch (_) {
      return null;
    }
  }

  Future<({SiteMetre? metre, String? error})> saveMetre(
    ConstructionSite site,
    MetreInput input,
  ) async {
    final userId = _userId;
    if (userId == null) return (metre: null, error: _signIn);
    try {
      return (
        metre: await _api.saveMetre(siteId: site.id, userId: userId, input: input),
        error: null,
      );
    } catch (e) {
      return (metre: null, error: _message(e));
    }
  }

  Future<({SiteMetre? metre, String? error})> requestMaterials(
    ConstructionSite site,
    List<MaterialRequestLine> lines,
  ) async {
    final userId = _userId;
    if (userId == null) return (metre: null, error: _signIn);
    try {
      final metre = await _api.requestMaterials(siteId: site.id, userId: userId, lines: lines);
      await refresh(); // the new demande joins the list (chef's count, superviseur's queue)
      return (metre: metre, error: null);
    } catch (e) {
      return (metre: null, error: _message(e));
    }
  }

  /// Validates, or refuses with [reason]. Returns null on success, or the message to show.
  Future<String?> decide(MaterialRequest request, {required bool validate, String? reason}) async {
    final userId = _userId;
    if (userId == null) return _signIn;
    try {
      final updated = await _api.decide(
        requestId: request.id,
        userId: userId,
        validate: validate,
        reason: reason,
      );
      _requests = [for (final r in _requests) r.id == updated.id ? updated : r];
      notifyListeners();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  /// Suppliers to order from, loaded once.
  Future<({List<Supplier> suppliers, String? error})> suppliers() async {
    final cached = _suppliers;
    if (cached != null) return (suppliers: cached, error: null);
    try {
      final list = await _api.fetchSuppliers();
      _suppliers = list;
      return (suppliers: list, error: null);
    } catch (e) {
      return (suppliers: const <Supplier>[], error: _message(e));
    }
  }

  /// Moyens généraux: orders [request] from [supplier]. Returns null on success, or the message to show.
  Future<String?> order(MaterialRequest request, Supplier supplier, {String? instruction}) async {
    final userId = _userId;
    if (userId == null) return _signIn;
    try {
      final updated = await _api.order(
        requestId: request.id,
        userId: userId,
        supplierId: supplier.id,
        instruction: instruction,
      );
      _requests = [for (final r in _requests) r.id == updated.id ? updated : r];
      notifyListeners();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  /// Loads the orders sent to the supplier the user is (only the supplier view needs them).
  /// Before sign-in is known it only notes the wish; the next refresh loads them.
  Future<void> loadSupplierOrders() async {
    _supplierOrdersWanted = true;
    final userId = _userId;
    if (userId == null) return;
    await _fetchSupplierOrders(userId);
    notifyListeners();
  }

  Future<void> _fetchSupplierOrders(String userId) async {
    try {
      _supplierOrders = await _api.fetchSupplierOrders(userId: userId);
      _supplierError = null;
    } catch (e) {
      _supplierOrders ??= const [];
      _supplierError = _message(e);
    }
  }

  /// Supplier: [order] is on its way, expected on [expectedOn]. Returns null on success, or the message to show.
  Future<String?> shipOrder(SupplierOrder order, {DateTime? expectedOn}) async {
    final userId = _userId;
    if (userId == null) return _signIn;
    try {
      final updated = await _api.shipOrder(requestId: order.requestId, userId: userId, expectedOn: expectedOn);
      _supplierOrders = [for (final o in _supplierOrders ?? const <SupplierOrder>[]) o.requestId == updated.requestId ? updated : o];
      notifyListeners();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  /// Chef de chantier: checks [request]'s delivery on site; [counted] holds the lines short of
  /// what was ordered. Returns null on success, or the message to show.
  Future<String?> receiveDelivery(MaterialRequest request, {Map<String, int> counted = const {}, String? comment}) async {
    final userId = _userId;
    if (userId == null) return _signIn;
    try {
      await _api.receiveDelivery(requestId: request.id, userId: userId, counted: counted, comment: comment);
      await refresh();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  /// Supplier: confirms delivery of [order]. Returns null on success, or the message to show.
  Future<String?> confirmDelivery(SupplierOrder order, {String? comment}) async {
    final userId = _userId;
    if (userId == null) return _signIn;
    try {
      final updated = await _api.confirmDelivery(requestId: order.requestId, userId: userId, comment: comment);
      _supplierOrders = [for (final o in _supplierOrders ?? const <SupplierOrder>[]) o.requestId == updated.requestId ? updated : o];
      notifyListeners();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  static const _signIn = 'Connectez-vous à Mon Peya pour suivre vos chantiers.';

  static String _message(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}
