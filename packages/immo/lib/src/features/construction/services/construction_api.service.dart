import 'package:immo/src/shared/services/immo_api.client.dart';

class ConstructionApiService {
  ConstructionApiService({ImmoApiClient? client})
      : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;

  Uri get base => _client.resolve('/api/construction');
}
