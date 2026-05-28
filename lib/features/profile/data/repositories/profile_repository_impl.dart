import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/profile_model.dart';
import 'profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;
  static const _profilesTable = 'profiles';

  @override
  Future<ProfileModel?> getProfile(String userId) async {
    final response = await _client
        .from(_profilesTable)
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return ProfileModel.fromJson(response);
  }

  @override
  Future<void> updateProfile(ProfileModel profile) async {
    await _client
        .from(_profilesTable)
        .update(profile.toJson())
        .eq('id', profile.id);
  }
}
