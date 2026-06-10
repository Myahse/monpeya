import '../../shared/services/immo_api_client.dart';

class ConstructionApiService {
  ConstructionApiService({ImmoApiClient? client})
      : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;

  Uri get base => _client.resolve('/api/construction');
}
