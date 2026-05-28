import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository_impl.dart';

class ProfileNotifier extends AsyncNotifier<ProfileModel?> {
  @override
  Future<ProfileModel?> build() async {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user == null) return null;

    final repo = ProfileRepositoryImpl();
    var profile = await repo.getProfile(user.id);

    if (profile == null) {
      // If the database trigger on auth.users is not set up in Supabase,
      // create and insert the profile row automatically from the app!
      final username = user.userMetadata?['username'] as String? ?? user.email?.split('@')[0] ?? 'climber';
      profile = ProfileModel(
        id: user.id,
        username: username,
        displayName: username,
        createdAt: DateTime.now(),
      );
      try {
        await SupabaseService.client.from('profiles').upsert({
          'id': user.id,
          'username': username,
          'display_name': username,
          'bio': '',
          'max_grade': 'V0',
          'total_sends': 0,
        });
      } catch (e) {
        debugPrint("Failed to auto-create profile row: $e");
      }
    }

    return profile;
  }

  Future<void> updateProfile(ProfileModel profile) async {
    final repo = ProfileRepositoryImpl();
    await repo.updateProfile(profile);
    state = AsyncData(profile);
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileModel?>(ProfileNotifier.new);
