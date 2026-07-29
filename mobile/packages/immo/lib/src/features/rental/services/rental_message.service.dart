import 'package:immo/src/shared/services/immo_api.client.dart';
import 'package:immo/src/features/rental/models/rental.message.dart';
import 'package:immo/src/features/rental/config/rental_api.endpoints.dart';

class RentalMessageService {
  RentalMessageService({ImmoApiClient? client}) : _client = client ?? ImmoApiClient();

  final ImmoApiClient _client;

  Future<List<RentalConversation>> fetchConversations(String userId) async {
    final response =
        await _client.getBody('${RentalApiEndpoints.conversations}/$userId');
    if (!response.success || response.data == null) return const [];

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => RentalConversation.fromBackend(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  Future<List<RentalMessage>> fetchMessages({
    required String userId,
    required String otherUserId,
  }) async {
    final path =
        '${RentalApiEndpoints.conversation}?user1Id=$userId&user2Id=$otherUserId';
    final response = await _client.getBody(path);
    if (!response.success || response.data == null) return const [];

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => RentalMessage.fromBackend(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map>()
          .map((e) => RentalMessage.fromBackend(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final message = RentalMessage(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      sentAt: DateTime.now(),
    );

    final response = await _client.postJson(
      RentalApiEndpoints.sendMessage,
      body: message.toSendPayload(senderId: senderId, receiverId: receiverId),
    );

    if (!response.success) {
      throw Exception(response.error ?? 'Envoi impossible');
    }
  }
}
