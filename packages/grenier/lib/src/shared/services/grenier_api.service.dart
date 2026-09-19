import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:grenier/src/shared/config/grenier_api.config.dart';
import 'package:grenier/src/shared/models/grenier_produit.model.dart';

class GrenierApiService {
  Future<List<GrenierProduit>> listProduits() async {
    final res = await http.get(
      Uri.parse('${GrenierApiConfig.baseUrl}/api/produits'),
    );
    if (res.statusCode >= 400) {
      throw Exception('Grenier API ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final items = decoded['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => GrenierProduit.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
