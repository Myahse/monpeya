import 'package:leadway/src/data/models/leadway_quote_values.model.dart';

class LeadwayQuoteRequest {
  const LeadwayQuoteRequest({
    required this.produit,
    required this.quoteType,
    required this.businessType,
    required this.fullName,
    required this.email,
    required this.phoneNo,
    required this.brand,
    required this.model,
    required this.power,
    required this.energy,
    required this.noOfSeat,
    required this.firstDriveDate,
    required this.vtc,
    required this.carRegNo,
    required this.contractDuration,
    required this.quoteAmount,
    required this.agentCode,
    required this.quoteValues,
  });

  final String produit;
  final String quoteType;
  final String businessType;
  final String fullName;
  final String email;
  final String phoneNo;
  final String brand;
  final String model;
  final String power;
  final String energy;
  final int noOfSeat;
  final String firstDriveDate; // Format: YYYY-MM-DD
  final int vtc;               // 0 ou 1
  final String carRegNo;
  final int contractDuration;
  final int quoteAmount;
  final String agentCode;
  final LeadwayQuoteValues quoteValues;

  Map<String, dynamic> toJson() => {
        // Souscripteur
        'fullName': fullName,
        'phoneNo': phoneNo,
        'email': email,
        'agentCode': agentCode,
        // Véhicule
        'carRegNo': carRegNo,
        'brand': brand,
        'model': model,
        'power': power,
        'energy': energy,
        'firstDriveDate': firstDriveDate,
        'noOfSeat': noOfSeat,
        'vtc': vtc,
        'contractDuration': contractDuration,
        // Tarification (résultat du calculateur)
        'quoteAmount': quoteAmount,
        'quoteValues': quoteValues.toJson(),
        // Champs complémentaires API
        'produit': produit,
        'quoteType': quoteType,
        'businessType': businessType,
      };
}
