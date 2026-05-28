import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  final User? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Listen to auth state changes to update state automatically
    SupabaseService.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        state = state.copyWith(user: data.session?.user, clearError: true);
      } else if (data.event == AuthChangeEvent.signedOut) {
        state = const AuthState(user: null);
      }
    });

    return AuthState(user: SupabaseService.auth.currentUser);
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await SupabaseService.auth.signInWithPassword(email: email, password: password);
      // State updates automatically via listener
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await SupabaseService.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      // State updates automatically via listener
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await SupabaseService.signOut();
      state = const AuthState(user: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
