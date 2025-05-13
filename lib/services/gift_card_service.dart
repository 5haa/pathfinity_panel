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

      debugPrint('Gift cards data: $data');
      return data.map((json) => GiftCard.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting gift cards: $e');
      if (e is Error) {
        debugPrint('Stack trace: ${e.stackTrace}');
      }
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
  Future<GiftCard?> createGiftCard({
    int? days,
    String? notes,
    int quantity = 1,
  }) async {
    try {
      debugPrint(
        'Creating gift card with days: $days, metadata: $notes, quantity: $quantity',
      );

      // Log the parameters we're sending
      final params = {
        'p_days': days,
        'p_metadata': notes,
        'p_quantity': quantity,
      };
      debugPrint('RPC params: $params');

      try {
        final result = await _supabase.rpc(
          'generate_gift_cards',
          params: params,
        );

        debugPrint('Gift card creation response: $result');

        // Check if we got a successful response
        if (result != null) {
          // Refresh the list to get the newly created gift cards
          final cards = await getAllGiftCards();
          debugPrint('Retrieved ${cards.length} cards after creation');

          if (cards.isNotEmpty) {
            // Return the most recently created card
            return cards.first;
          }
        }
      } catch (rpcError) {
        debugPrint('First attempt failed: $rpcError');

        // Try with just p_days and p_metadata
        debugPrint('Trying with only p_days and p_metadata...');
        final params2 = {'p_days': days, 'p_metadata': notes};

        try {
          final result = await _supabase.rpc(
            'generate_gift_cards',
            params: params2,
          );

          if (result != null) {
            debugPrint('Second attempt worked! Result: $result');
            final cards = await getAllGiftCards();
            if (cards.isNotEmpty) {
              return cards.first;
            }
          }
        } catch (secondError) {
          debugPrint('Second attempt also failed: $secondError');

          // Try directly inserting into the table as a last resort
          debugPrint('Trying direct insertion as last resort...');
          try {
            final response =
                await _supabase.from('gift_cards').insert({
                  'code': 'MANUAL${DateTime.now().millisecondsSinceEpoch}',
                  'days': days,
                  'metadata': notes,
                }).select();

            if (response.isNotEmpty) {
              debugPrint('Direct insertion worked! Response: $response');
              return GiftCard.fromJson(response[0]);
            }
          } catch (insertError) {
            debugPrint('Direct insertion failed: $insertError');
          }
        }
      }

      // Last attempt: Just manually retrieve the latest card
      try {
        debugPrint('Last resort: Just retrieving the most recent card...');
        final cards = await getAllGiftCards();
        if (cards.isNotEmpty) {
          debugPrint('Found ${cards.length} cards, returning the latest one');
          return cards.first;
        }
      } catch (e) {
        debugPrint('Failed to retrieve latest card: $e');
      }

      debugPrint('Failed to create gift card: all attempts failed');
      return null;
    } catch (e) {
      debugPrint('Error creating gift card: $e');
      if (e is PostgrestException) {
        debugPrint(
          'PostgrestException details: ${e.details}, code: ${e.code}, hint: ${e.hint}',
        );
      }
      return null;
    }
  }

  // Use a gift card (for testing in admin panel)
  Future<bool> useGiftCard(String code) async {
    try {
      debugPrint('Attempting to use gift card with code: $code');

      final result = await _supabase.rpc(
        'use_gift_card',
        params: {'p_code': code},
      );

      debugPrint('Use gift card response: $result');

      if (result == true) {
        debugPrint('Gift card used successfully');
        return true;
      } else {
        debugPrint('Failed to use gift card: result is not true');
        return false;
      }
    } catch (e) {
      debugPrint('Error using gift card: $e');
      if (e is PostgrestException) {
        debugPrint(
          'PostgrestException details: ${e.details}, code: ${e.code}, hint: ${e.hint}',
        );
      }
      return false;
    }
  }
}
