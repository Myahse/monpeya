import 'package:flutter/material.dart';
import 'package:immo/immo.dart';

/// Fournisseur : reçoit les commandes des chantiers et confirme les livraisons.
const immoFournisseurApp = ConstructionRoleApp(appId: 'immo_fournisseur', role: ConstructionRole.supplier);

void main() => runApp(immoFournisseurApp);
