import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ble_status_indicator.dart';
import '../../../data/models/board_config.dart';
import '../../ble/presentation/providers/ble_notifier.dart';
import '../data/notifiers/active_route_notifier.dart';
import '../../discovery/data/models/climbing_route_model.dart';
import '../widgets/climbing_grid.dart';

/// Full-screen board view showing the active route on the grid.
class BoardViewScreen extends ConsumerWidget {
  const BoardViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, ref),
              Expanded(child: _buildGrid(context, ref)),
              _buildActiveRouteBar(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Board View', style: AppTypography.title),
          const Spacer(),
          // BLE status
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    bleState.isConnected
                        ? 'Connected to ${bleState.connectedDeviceName}'
                        : 'Not connected. Go to Profile → BLE Connection to connect.',
                  ),
                  backgroundColor: AppColors.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: BleStatusIndicator(
              isConnected: bleState.isConnected,
              showLabel: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, WidgetRef ref) {
    final activeRouteState = ref.watch(activeRouteProvider).valueOrNull;

    ClimbingRouteModel? dummyRoute;
    if (activeRouteState != null && activeRouteState.hasActiveRoute) {
      dummyRoute = ClimbingRouteModel(
        id: activeRouteState.routeId,
        name: activeRouteState.routeName,
        grade: activeRouteState.routeGrade,
        holds: activeRouteState.holds,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: ClimbingGrid(
        boardConfig: BoardConfig.standard(),
        activeRoute: dummyRoute,
        isLocked: true,
      ),
    );
  }

  Widget _buildActiveRouteBar(BuildContext context, WidgetRef ref) {
    final activeRouteState = ref.watch(activeRouteProvider).valueOrNull;
    final hasRoute = activeRouteState?.hasActiveRoute ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: hasRoute
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Active: ${activeRouteState!.routeName} (${activeRouteState.routeGrade})',
                        style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${activeRouteState.holds.where((h) => h.holdType != 'foot').length} moves',
                        style: AppTypography.label,
                      ),
                    ],
                  ),
                ),
                _LedToggleButton(
                  isOn: activeRouteState.ledsOn,
                  onTap: () {
                    final notifier = ref.read(activeRouteProvider.notifier);
                    notifier.toggleLeds();
                  },
                ),
              ],
            )
          : Center(
              child: Text(
                'No route selected. Pick one from Discover.',
                style: AppTypography.bodySmall,
              ),
            ),
    );
  }

}

// ─── LED Toggle Button ────────────────────────────────────
class _LedToggleButton extends StatelessWidget {
  const _LedToggleButton({required this.isOn, required this.onTap});
  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isOn
              ? AppColors.accentLime.withValues(alpha: 0.2)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isOn ? AppColors.accentLime : AppColors.border,
          ),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: AppColors.accentLime.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb,
              size: 18,
              color: isOn ? AppColors.accentLime : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              isOn ? 'ON' : 'OFF',
              style: AppTypography.label.copyWith(
                color: isOn ? AppColors.accentLime : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
