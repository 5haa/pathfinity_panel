class GiftCard {
  final String id;
  final String code;
  final bool isUsed;
  final DateTime? usedAt;
  final String? usedBy;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? expiresAt;
  final String? notes;

  GiftCard({
    required this.id,
    required this.code,
    required this.isUsed,
    this.usedAt,
    this.usedBy,
    required this.createdAt,
    required this.createdBy,
    this.expiresAt,
    this.notes,
  });

  factory GiftCard.fromJson(Map<String, dynamic> json) {
    return GiftCard(
      id: json['id'],
      code: json['code'],
      isUsed: json['is_used'] ?? false,
      usedAt: json['used_at'] != null ? DateTime.parse(json['used_at']) : null,
      usedBy: json['used_by'],
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'],
      expiresAt:
          json['expires_at'] != null
              ? DateTime.parse(json['expires_at'])
              : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'is_used': isUsed,
      'used_at': usedAt?.toIso8601String(),
      'used_by': usedBy,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'expires_at': expiresAt?.toIso8601String(),
      'notes': notes,
    };
  }
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
