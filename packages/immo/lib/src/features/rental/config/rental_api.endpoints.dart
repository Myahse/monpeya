abstract final class RentalApiEndpoints {
  static const listProperties = '/api/biens/getByCriteria';
  static const availableProperties = '/api/biens/available';
  static const createProperty = '/api/biens/create';
  static const publicProperty = '/api/biens/public';
  static const listTenants = '/api/locataires/getByCriteria';
  static const createTenant = '/api/locataires/create';
  static const listPayments = '/api/paiements/getByCriteria';
  static const conversations = '/api/messages/conversations';
  static const conversation = '/api/messages/conversation';
  static const sendMessage = '/api/messages';
  static const uploadFile = '/api/upload/file';
  static const listCountries = '/api/codePays/getByCriteria';
  static const favorites = '/api/favoris';
  static const createUser = '/api/utilisateurs/create';
  static const usersByCriteria = '/api/utilisateurs/getByCriteria';
}

/// Property type UUIDs from rental-app `App.tsx`.
abstract final class RentalPropertyTypes {
  static const house = '0957a631-c7db-49e8-9517-22aea67a849e';
  static const building = '004648d3-63ab-4405-b258-aa26e382d392';
}
