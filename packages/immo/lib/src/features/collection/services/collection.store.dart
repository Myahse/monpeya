import 'package:flutter/foundation.dart';

import 'package:immo/src/features/collection/models/payment.model.dart';
import 'package:immo/src/features/collection/models/property.model.dart';
import 'package:immo/src/features/collection/models/tenant.model.dart';
import 'package:immo/src/features/collection/services/payment.service.dart';
import 'package:immo/src/features/collection/services/property.service.dart';
import 'package:immo/src/features/collection/services/tenant.service.dart';
import 'package:immo/src/shared/services/immo_api.client.dart';

/// Rents and tenants shared by every Collection tab, so marking a rent as
/// paid on Loyers updates Accueil too (the tabs stay alive in an IndexedStack).
class CollectionStore extends ChangeNotifier {
  CollectionStore({required ImmoApiClient client})
      : _payments = CollectionPaymentService(client: client),
        _tenants = CollectionTenantService(client: client);

  final CollectionPaymentService _payments;
  final CollectionTenantService _tenants;

  String? _userId;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  List<CollectionPayment> _paymentList = const [];
  List<CollectionTenant> _tenantList = const [];

  bool get signedIn => _userId != null;
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;
  List<CollectionPayment> get payments => _paymentList;
  List<CollectionTenant> get tenants => _tenantList;
  List<CollectionProperty> get properties =>
      CollectionPropertyService.propertiesOf(_tenantList);

  /// Tenants with a complete lease but no rent schedule yet.
  List<CollectionTenant> get unscheduledTenants =>
      _tenantList.where((t) => !t.hasSchedule).toList();

  /// Loads for [userId]; a null id (guest) clears everything.
  Future<void> load(String? userId) async {
    _userId = (userId == null || userId.isEmpty) ? null : userId;
    if (_userId == null) {
      _paymentList = const [];
      _tenantList = const [];
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
    try {
      final results = await Future.wait([
        _payments.fetchPayments(userId: userId),
        _tenants.fetchTenants(userId: userId),
      ]);
      _paymentList = results[0] as List<CollectionPayment>;
      _tenantList = results[1] as List<CollectionTenant>;
      _error = null;
    } catch (e) {
      _error = _message(e);
    } finally {
      _loading = false;
      _loaded = true;
      notifyListeners();
    }
  }

  /// Returns null on success, or the message to show.
  Future<String?> markPaid(
    CollectionPayment payment, {
    required String method,
    String? reference,
  }) async {
    try {
      await _payments.markPaid(payment.id, method: method, reference: reference);
      await refresh();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  /// Returns null on success, or the message to show.
  Future<String?> generateSchedule(CollectionTenant tenant) async {
    final userId = _userId;
    if (userId == null) return 'Connectez-vous à Mon Peya pour suivre vos loyers.';
    try {
      await _payments.generateSchedule(tenantId: tenant.id, userId: userId);
      await refresh();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  static String _message(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}
