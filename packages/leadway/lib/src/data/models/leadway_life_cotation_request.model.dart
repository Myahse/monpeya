import 'package:leadway/src/core/constants/leadway_life.constants.dart';

class LeadwayLifeFullName {
  const LeadwayLifeFullName({
    required this.firstName,
    required this.lastName,
  });

  final String firstName;
  final String lastName;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
      };
}

class LeadwayLifePerson {
  const LeadwayLifePerson({
    required this.fullName,
    required this.birthDate,
    required this.gender,
    required this.phone,
    required this.email,
  });

  final LeadwayLifeFullName fullName;
  final String birthDate; // YYYY-MM-DD
  final LeadwayLifeGender gender;
  final String phone;
  final String email;

  Map<String, dynamic> toJson() => {
        'fullName': fullName.toJson(),
        'birthDate': birthDate,
        'gender': gender.code,
        'phone': phone,
        'email': email,
      };
}

class LeadwayLifeInsured {
  const LeadwayLifeInsured({
    required this.person,
    required this.relationshipToSubscriber,
    required this.subscriber,
  });

  final LeadwayLifePerson person;
  final LeadwayLifeRelationship relationshipToSubscriber;
  final bool subscriber;

  Map<String, dynamic> toJson() => {
        'person': person.toJson(),
        'relationshipToSubscriber': relationshipToSubscriber.code,
        'subscriber': subscriber,
      };
}

/// Corps POST /api/souscription/cotation
class LeadwayLifeCotationRequest {
  const LeadwayLifeCotationRequest({
    required this.subscriptionRef,
    required this.productCode,
    required this.subscriber,
    required this.additionalInsureds,
    required this.paymentFrequency,
    required this.tierInputAmount,
    required this.effectiveDate,
  });

  final String subscriptionRef;
  final String productCode;
  final LeadwayLifeInsured subscriber;
  final List<LeadwayLifeInsured> additionalInsureds;
  final String paymentFrequency;
  final int tierInputAmount;
  final String effectiveDate; // YYYY-MM-DD

  Map<String, dynamic> toJson() => {
        'subscriptionRef': subscriptionRef,
        'productCode': productCode,
        'subscriber': subscriber.toJson(),
        'additionalInsureds': additionalInsureds.map((e) => e.toJson()).toList(),
        'paymentFrequency': paymentFrequency,
        'tierInputAmount': tierInputAmount,
        'effectiveDate': effectiveDate,
      };
}
