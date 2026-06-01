import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/presentation/providers/auth_notifier.dart';
import '../../ble/presentation/providers/ble_notifier.dart';
import '../../ble/screens/ble_setup_screen.dart';
import '../../logbook/presentation/providers/logbook_notifier.dart';
import '../data/models/profile_model.dart';
import '../presentation/providers/profile_notifier.dart';
import '../presentation/providers/my_routes_notifier.dart';
import '../presentation/providers/favorites_notifier.dart';
import 'my_routes_screen.dart';
import 'favorites_screen.dart';
import '../presentation/providers/drafts_notifier.dart';
import 'drafts_screen.dart';

/// Profile screen with user stats and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accentPrimary),
            ),
            error: (err, stack) => Center(
              child: Text('Error loading profile: $err', style: AppTypography.body),
            ),
            data: (profile) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHeader(context, ref),
                    const SizedBox(height: 24),
                    _buildProfileCard(profile),
                    const SizedBox(height: 16),
                    _buildStatsRow(context, ref, profile),
                    const SizedBox(height: 24),
                    _buildMenuItems(context, ref),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.logout, color: AppColors.accentRed),
          tooltip: 'Sign Out',
          onPressed: () {
            ref.read(authProvider.notifier).signOut();
          },
        ),
      ],
    );
  }

  Widget _buildProfileCard(ProfileModel? profile) {
    final hasCustomDisplayName = profile?.displayName != null &&
        profile?.displayName != 'Climber' &&
        profile?.displayName != profile?.username;
    final displayName = hasCustomDisplayName
        ? profile!.displayName!
        : (profile?.username ?? 'Climber');
    final sinceYear = profile?.createdAt?.year.toString() ?? DateTime.now().year.toString();

    return Column(
      children: [
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.accentPrimary,
                AppColors.accentLime,
              ],
            ),
          ),
          child: const Icon(Icons.person, size: 40, color: AppColors.surface),
        ),
        const SizedBox(height: 12),
        Text(displayName, style: AppTypography.headline),
        if (hasCustomDisplayName) ...[
          const SizedBox(height: 2),
          Text('@${profile!.username}', style: AppTypography.bodySmall.copyWith(color: AppColors.accentPrimary)),
        ],
        const SizedBox(height: 4),
        Text('Climbing since $sinceYear', style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, WidgetRef ref, ProfileModel? profile) {
    final logbookState = ref.watch(logbookProvider).valueOrNull;
    final totalSends = profile?.totalSends ?? logbookState?.totalSends ?? 0;
    final maxGrade = profile?.maxGrade ?? 'V${logbookState?.averageGrade.ceil() ?? 0}';
    final myRoutesCount = ref.watch(myRoutesProvider).valueOrNull?.length ?? 0;

    return Row(
      children: [
        _profileStat('Sends', '$totalSends'),
        Container(
          width: 0.5,
          height: 40,
          color: AppColors.border,
        ),
        _profileStat('Routes', '$myRoutesCount'),
        Container(
          width: 0.5,
          height: 40,
          color: AppColors.border,
        ),
        _profileStat('Max', maxGrade),
      ],
    );
  }

  Widget _profileStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.headline),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.label),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleProvider);
    final myRoutesAsync = ref.watch(myRoutesProvider);
    final myRoutesCount = myRoutesAsync.valueOrNull?.length ?? 0;
    
    final draftsAsync = ref.watch(draftsProvider);
    final draftsCount = draftsAsync.valueOrNull?.length ?? 0;

    return Column(
      children: [
        _menuTile(
          Icons.route,
          'My Routes',
          '$myRoutesCount routes',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyRoutesScreen()),
            );
          },
        ),
        _menuTile(
          Icons.favorite,
          'Favorites',
          '${ref.watch(favoritesProvider).valueOrNull?.length ?? 0} saved',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            );
          },
        ),
        _menuTile(
          Icons.drafts,
          'Drafts',
          '$draftsCount drafts',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DraftsScreen()),
            );
          },
        ),
        const Divider(height: 32),
        _menuTile(
          Icons.grid_view,
          'Board Settings',
          'Standard 11×18',
          onTap: () {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Board Settings are coming soon!')));
          },
        ),
        _menuTile(
          Icons.bluetooth,
          'BLE Connection',
          bleState.isConnected
              ? 'Connected to ${bleState.connectedDeviceName}'
              : 'Not connected',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BleSetupScreen()),
            );
          },
          trailing: Icon(
            Icons.circle,
            size: 10,
            color: bleState.isConnected
                ? AppColors.accentGreen
                : AppColors.accentRed,
          ),
        ),
        const Divider(height: 32),
        _menuTile(
          Icons.info_outline,
          'About Boulder Board 112',
          'V1.0.0',
          onTap: () {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Boulder Board 112 V1.0.0')));
          },
        ),
      ],
    );
  }

  Widget _menuTile(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: AppTypography.body),
      subtitle:
          Text(subtitle, style: AppTypography.label.copyWith(fontSize: 11)),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
