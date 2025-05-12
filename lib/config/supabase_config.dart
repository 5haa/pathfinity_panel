import 'package:flutter/foundation.dart';

class SupabaseConfig {
  // Supabase URL and anon key
  static const String supabaseUrl = 'https://warbjjrpzsmaqphavhir.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhcmJqanJwenNtYXFwaGF2aGlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2MDA2NjcsImV4cCI6MjA1NjE3NjY2N30.qrgV2YxVNjcNj02xzi-0w6hfIWijtm-s3mcK4o2Sr78';

  // Debug mode flag
  static bool get isDebugMode => kDebugMode;
}
