import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Service layer for Supabase initialization and client access.
///
/// This service handles:
/// - Initializing the Supabase SDK with custom URL and Anon Key
/// - Providing a singleton [SupabaseClient] for all data operations
/// - Exposing convenience getters for auth, database, storage, and realtime
///
/// Usage:
/// ```dart
/// // Initialize once in main.dart
/// await SupabaseService.initialize();
///
/// // Access the client anywhere
/// final client = SupabaseService.client;
/// final user = SupabaseService.auth.currentUser;
/// ```
class SupabaseService {
  SupabaseService._();

  /// Initialize Supabase with custom URL and Anon Key.
  ///
  /// Must be called before [runApp] in `main.dart`.
  /// Uses [SupabaseConfig] for credentials by default, but allows
  /// overriding for testing or multi-environment setups.
  static Future<void> initialize({
    String? url,
    String? anonKey,
  }) async {
    await Supabase.initialize(
      url: url ?? SupabaseConfig.supabaseUrl,
      anonKey: anonKey ?? SupabaseConfig.supabaseAnonKey,
    );
  }

  /// The initialized Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut to the GoTrue auth client.
  static GoTrueClient get auth => client.auth;

  /// Shortcut to the current authenticated user (nullable).
  static User? get currentUser => auth.currentUser;

  /// Shortcut to the current session (nullable).
  static Session? get currentSession => auth.currentSession;

  /// Whether a user is currently signed in.
  static bool get isAuthenticated => currentUser != null;

  /// Perform a query on a Supabase table.
  ///
  /// Example:
  /// ```dart
  /// final data = await SupabaseService.from('routes').select();
  /// ```
  static SupabaseQueryBuilder from(String table) => client.from(table);

  /// Access Supabase Storage for file uploads/downloads.
  static SupabaseStorageClient get storage => client.storage;

  /// Access Supabase Realtime for live subscriptions.
  static RealtimeClient get realtime => client.realtime;

  /// Sign out the current user and clear the session.
  static Future<void> signOut() async {
    await auth.signOut();
  }
}
