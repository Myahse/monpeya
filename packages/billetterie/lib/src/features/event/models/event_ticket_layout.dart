/// Visual layout creators can choose for event tickets.
enum EventTicketLayout {
  /// Long horizontal ticket (wallet / list style).
  horizontal,

  /// Near-square ticket (QR / check-in style).
  square;

  String get apiValue => name;

  String get labelFr {
    switch (this) {
      case EventTicketLayout.horizontal:
        return 'Horizontal';
      case EventTicketLayout.square:
        return 'Carré';
    }
  }

  String get subtitleFr {
    switch (this) {
      case EventTicketLayout.horizontal:
        return 'Format long — idéal pour le portefeuille';
      case EventTicketLayout.square:
        return 'Format carré — idéal pour le QR code';
    }
  }

  /// Front aspect: height / width.
  double get heightRatio {
    switch (this) {
      case EventTicketLayout.horizontal:
        return 0.52;
      case EventTicketLayout.square:
        return 0.95;
    }
  }

  static EventTicketLayout fromApi(String? raw) {
    final v = raw?.trim().toLowerCase();
    if (v == 'square' || v == 'carré' || v == 'carre') {
      return EventTicketLayout.square;
    }
    return EventTicketLayout.horizontal;
  }
}
