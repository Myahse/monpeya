import 'package:flutter/material.dart';
import 'package:immo/immo.dart';

/// Superviseur : valide ou refuse les demandes de matériaux des chantiers.
const immoSuperviseurApp = ConstructionRoleApp(appId: 'immo_superviseur', role: ConstructionRole.superviseur);

void main() => runApp(immoSuperviseurApp);
