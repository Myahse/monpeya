import 'dart:math' as math;

/// Shared layout math for review-transfer screens (full page + bottom sheet).
abstract final class PeyapayReviewTransferLayout {
  /// Header row: `14 + 44 + 14`.
  static const headerHeight = 72.0;

  static const cardsTopSpacing = 10.0;

  /// Matches [PeyapayPartyCardsStack] card height.
  static const cardStackHeight = 140.0;

  /// Breathing room between cards and the white details panel.
  static const gapBelowCards = 16.0;

  /// Minimum height reserved for the details panel (rows + total + slider).
  static const minDetailsSheetHeight = 320.0;

  /// Bottom of the cards region from the top of the review body.
  static double get cardsRegionBottom =>
      headerHeight + cardsTopSpacing + cardStackHeight;

  /// Resolves where the details sheet should start so it never overlaps cards.
  static double sheetTop({
    required double bodyHeight,
    required bool isDark,
  }) {
    final minTop = cardsRegionBottom + gapBelowCards;
    final maxTop = math.max(minTop, bodyHeight - minDetailsSheetHeight);

    if (isDark) {
      // Keep the original look on tall screens, but never overlap cards.
      return math.max(minTop, math.min(252.0, maxTop));
    }

    // Light theme: sheet fills the bottom edge, starting right below the cards.
    return minTop.clamp(minTop, maxTop);
  }
}
