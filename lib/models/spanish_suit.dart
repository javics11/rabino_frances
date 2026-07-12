enum SpanishSuit { bastos, copas, espadas, oros }

extension SpanishSuitExtension on SpanishSuit {
  String get symbol {
    switch (this) {
      case SpanishSuit.bastos:
        return '🌿';
      case SpanishSuit.copas:
        return '🏆';
      case SpanishSuit.espadas:
        return '⚔️';
      case SpanishSuit.oros:
        return '🟡';
    }
  }
}
