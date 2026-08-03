import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:billetterie/src/core/constants/billetterie.prefs.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/transport/models/transport_profile.model.dart';

/// Persists transport client/conductor profile (upgrade requests live here only).
class TransportProfileStore {
  TransportProfileStore();

  Future<TransportProfileState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(BilletteriePrefs.transportProfile);
    TransportProfileState state = const TransportProfileState();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          state = TransportProfileState.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }

    final merchant = await BilletterieHostBridge.isPeyapayMerchant();
    if (merchant != state.peyapayMerchant) {
      state = state.copyWith(peyapayMerchant: merchant);
    }

    final merchantOnly = await BilletterieHostBridge.isMerchantOnly();
    if (merchantOnly) {
      if (state.canUseAsConductor) {
        state = state.copyWith(role: TransportProfileRole.conductor);
      } else if (state.isClientMode) {
        state = state.copyWith(role: TransportProfileRole.conductor);
      }
    }

    if (merchant != state.peyapayMerchant || merchantOnly) {
      await save(state);
    }
    return state;
  }

  Future<void> save(TransportProfileState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      BilletteriePrefs.transportProfile,
      jsonEncode(state.toJson()),
    );
    revision.value++;
  }

  /// Bumps when profile mode / access changes so the shell can rebuild tabs.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Client asks to subscribe so they can buy/use tickets.
  Future<TransportProfileState> requestClientSubscribe() async {
    if (await BilletterieHostBridge.isMerchantOnly()) {
      return load();
    }
    final current = await load();
    final next = current.copyWith(
      role: TransportProfileRole.client,
      clientAccess: TransportAccessStatus.pending,
      requestNote: 'Demande d’abonnement client envoyée',
    );
    await save(next);
    return next;
  }

  /// Activates client access after subscribe (or mock approval).
  Future<TransportProfileState> activateClient() async {
    final current = await load();
    final next = current.copyWith(
      role: TransportProfileRole.client,
      clientAccess: TransportAccessStatus.active,
      clearRequestNote: true,
    );
    await save(next);
    return next;
  }

  /// Save KYC docs from the Documents screen (no conductor request).
  Future<TransportProfileState> saveDocuments({
    required bool isCompany,
    String? idCardFrontPath,
    String? idCardBackPath,
    String? companyDocPath,
    bool clearIdFront = false,
    bool clearIdBack = false,
    bool clearCompanyDoc = false,
  }) async {
    final current = await load();
    final next = current.copyWith(
      isCompany: isCompany,
      idCardFrontPath: idCardFrontPath,
      idCardBackPath: idCardBackPath,
      companyDocPath: companyDocPath,
      clearIdFront: clearIdFront,
      clearIdBack: clearIdBack,
      clearCompanyDoc: clearCompanyDoc,
    );
    await save(next);
    return next;
  }

  /// Non-merchant: request to become a PeyaPay partner.
  Future<TransportProfileState> requestPartner() async {
    final current = await load();
    final next = current.copyWith(
      partnerAccess: TransportAccessStatus.pending,
      requestNote: 'Demande pour devenir partenaire envoyée',
    );
    await save(next);
    return next;
  }

  Future<TransportProfileState> activatePartner() async {
    final current = await load();
    final next = current.copyWith(
      partnerAccess: TransportAccessStatus.active,
      requestNote: 'Statut partenaire actif — vous pouvez devenir conducteur',
    );
    await save(next);
    return next;
  }

  /// Conductor path when already merchant / partner → subscribe to business module.
  Future<TransportProfileState> requestConductorSubscribe() async {
    final current = await load();
    final next = current.copyWith(
      conductorAccess: TransportAccessStatus.pending,
      requestNote: 'Abonnement conducteur en attente de validation',
    );
    await save(next);
    return next;
  }

  Future<TransportProfileState> activateConductor() async {
    final current = await load();
    final next = current.copyWith(
      role: TransportProfileRole.conductor,
      conductorAccess: TransportAccessStatus.active,
      clearRequestNote: true,
    );
    await save(next);
    return next;
  }

  Future<TransportProfileState> switchToClientMode() async {
    if (await BilletterieHostBridge.isMerchantOnly()) {
      return load();
    }
    final current = await load();
    final next = current.copyWith(role: TransportProfileRole.client);
    await save(next);
    return next;
  }

  Future<TransportProfileState> switchToConductorMode() async {
    final current = await load();
    if (current.conductorAccess != TransportAccessStatus.active) {
      return current;
    }
    final next = current.copyWith(role: TransportProfileRole.conductor);
    await save(next);
    return next;
  }
}
