class GiftCard {
  final String code;
  final DateTime createdAt;
  final DateTime? redeemedAt;
  final String? redeemedBy;
  final int? days;
  final int serial;
  final DateTime updatedAt;
  final String metadata;
  final String? generatedBy;

  GiftCard({
    required this.code,
    required this.createdAt,
    this.redeemedAt,
    this.redeemedBy,
    this.days,
    required this.serial,
    required this.updatedAt,
    required this.metadata,
    this.generatedBy,
  });

  factory GiftCard.fromJson(Map<String, dynamic> json) {
    return GiftCard(
      code: json['code'],
      createdAt: DateTime.parse(json['created_at']),
      redeemedAt:
          json['redeemed_at'] != null
              ? DateTime.parse(json['redeemed_at'])
              : null,
      redeemedBy: json['redeemed_by'],
      days: json['days'] != null ? int.parse(json['days'].toString()) : null,
      serial: json['serial'],
      updatedAt: DateTime.parse(json['updated_at']),
      metadata: json['metadata'] ?? '',
      generatedBy: json['generated_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'created_at': createdAt.toIso8601String(),
      'redeemed_at': redeemedAt?.toIso8601String(),
      'redeemed_by': redeemedBy,
      'days': days,
      'serial': serial,
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
      'generated_by': generatedBy,
    };
  }

  bool get isUsed => redeemedAt != null;
}

class GiftCardStats {
  final int totalCards;
  final int usedCards;
  final int unusedCards;

  GiftCardStats({
    required this.totalCards,
    required this.usedCards,
    required this.unusedCards,
  });

  factory GiftCardStats.fromJson(Map<String, dynamic> json) {
    return GiftCardStats(
      totalCards: json['total_cards'] ?? 0,
      usedCards: json['used_cards'] ?? 0,
      unusedCards: json['unused_cards'] ?? 0,
    );
  }
}
