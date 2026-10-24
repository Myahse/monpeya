import 'package:flutter/material.dart';
import 'package:immo/immo.dart';

/// Chef de chantier : chantiers, métré et plan, demandes de matériaux, remise en location.
const immoChantierApp = ConstructionRoleApp(appId: 'immo_chantier', role: ConstructionRole.chefSite);

void main() => runApp(immoChantierApp);
