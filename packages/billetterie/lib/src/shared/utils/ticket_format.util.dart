
library;

const _months = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String formatTicketDateTime(DateTime d) {
  final minutes = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${_months[d.month - 1]} ${d.year}, ${d.hour}h$minutes';
}

String ticketStatusLabel(String status) => switch (status) {
      'FOR_SALE' => 'En vente',
      'SOLD' => 'Vendu',
      'CONSUMED' => 'Utilisé',
      'GENERATED' => 'Généré',
      'CANCELLED' => 'Annulé',
      _ => status,
    };

String ticketVehicleTypeLabel(String type) => switch (type) {
      'CAR' => 'Voiture',
      'BUS' => 'Bus',
      'MINIBUS' => 'Minibus',
      'TAXI' => 'Taxi',
      'MOTORBIKE' => 'Moto',
      'TRUCK' => 'Camion',
      _ => type,
    };
