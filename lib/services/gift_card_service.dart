import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/gift_card_model.dart';

class GiftCardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all gift cards
  Future<List<GiftCard>> getAllGiftCards() async {
    try {
      final data = await _supabase
          .from('gift_cards')
          .select()
          .order('created_at', ascending: false);
      return data.map((json) => GiftCard.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting gift cards: $e');
      return [];
    }
  }

  // Get gift card statistics
  Future<GiftCardStats?> getGiftCardStats() async {
    try {
      final data = await _supabase.rpc('get_gift_card_stats');

      // Handle the response as a Map
      if (data is Map<String, dynamic>) {
        return GiftCardStats.fromJson(data);
      } else {
        debugPrint('Unexpected stats format: $data');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting gift card stats: $e');
      return null;
    }
  }

  // Create a new gift card
  Future<GiftCard?> createGiftCard({DateTime? expiresAt, String? notes}) async {
    try {
      final giftCardId = await _supabase.rpc(
        'create_gift_card',
        params: {
          'p_expires_at': expiresAt?.toIso8601String(),
          'p_notes': notes,
        },
      );

      if (giftCardId != null) {
        final data =
            await _supabase
                .from('gift_cards')
                .select()
                .eq('id', giftCardId)
                .single();
        return GiftCard.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating gift card: $e');
      return null;
    }
  }

  // Use a gift card (for testing in admin panel)
  Future<bool> useGiftCard(String code) async {
    try {
      final result = await _supabase.rpc(
        'use_gift_card',
        params: {'p_code': code},
      );
      return result == true;
    } catch (e) {
      debugPrint('Error using gift card: $e');
      return false;
    }
  }
}
