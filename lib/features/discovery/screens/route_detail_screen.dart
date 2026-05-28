import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wiroboard/features/discovery/presentation/providers/route_list_notifier.dart';
import '../../../core/constants/hold_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/grade_badge.dart';
import '../../../core/widgets/star_rating.dart';
import '../../../data/models/board_config.dart';
import '../../logbook/data/models/log_entry.dart';
import '../../board/data/notifiers/active_route_notifier.dart';
import '../../board/widgets/climbing_grid.dart';
import '../../ble/presentation/providers/ble_notifier.dart';
import '../../logbook/presentation/providers/logbook_notifier.dart';
import '../../profile/presentation/providers/favorites_notifier.dart';
import '../data/models/climbing_route_model.dart';

/// Route detail screen showing grid preview and action buttons.
class RouteDetailScreen extends ConsumerWidget {
  const RouteDetailScreen({super.key, required this.route});
  final ClimbingRouteModel route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for updates to this specific route (e.g., after logging a send)
    final latestRoute = ref
            .watch(routeListProvider)
            .valueOrNull
            ?.allRoutes
            .firstWhere((r) => r.id == route.id, orElse: () => route) ??
        route;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, latestRoute),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGridPreview(context, latestRoute),
                      const SizedBox(height: 20),
                      _buildRouteInfo(latestRoute),
                      const SizedBox(height: 16),
                      _buildHoldLegend(latestRoute),
                      const SizedBox(height: 24),
                      _buildLightUpButton(context, ref, latestRoute),
                      const SizedBox(height: 12),
                      _buildLogButtons(context, ref, latestRoute),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ClimbingRouteModel latestRoute) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Consumer(builder: (context, ref, _) {
            ref.watch(favoritesProvider);
            final isFav =
                ref.read(favoritesProvider.notifier).isFavorite(route.id!);
            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                size: 22,
                color: isFav ? AppColors.accentRed : null,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(favoritesProvider.notifier).toggleFavorite(route);
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildGridPreview(
      BuildContext context, ClimbingRouteModel latestRoute) {
    return ClimbingGrid(
      boardConfig: BoardConfig.standard(),
      activeRoute: latestRoute,
      isLocked: true,
    );
  }

  Widget _buildRouteInfo(ClimbingRouteModel latestRoute) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(latestRoute.name, style: AppTypography.headline),
            ),
            GradeBadge(grade: latestRoute.grade, size: GradeBadgeSize.large),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'by ${latestRoute.setterName} · ${_formatDate(latestRoute.createdAt)}',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            StarRating(rating: latestRoute.rating, size: 18, showValue: true),
            Text(
              ' (${latestRoute.ratingCount})',
              style: AppTypography.label,
            ),
            const SizedBox(width: 16),
            const Icon(Icons.check_circle_outline,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${latestRoute.sendCount} sends',
                style: AppTypography.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.rotate_right,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('Angle: ${latestRoute.angle}°',
                style: AppTypography.bodySmall),
            const SizedBox(width: 16),
            const Icon(Icons.swap_vert,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('Moves: ${latestRoute.computedMoveCount}',
                style: AppTypography.bodySmall),
          ],
        ),
        if (latestRoute.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(latestRoute.description, style: AppTypography.body),
        ],
      ],
    );
  }

  Widget _buildHoldLegend(ClimbingRouteModel latestRoute) {
    return Row(
      children: [
        _holdLegendItem(HoldType.start,
            '${latestRoute.holdsByType(HoldType.start.name).length}'),
        const SizedBox(width: 16),
        _holdLegendItem(HoldType.hand,
            '×${latestRoute.holdsByType(HoldType.hand.name).length}'),
        const SizedBox(width: 16),
        _holdLegendItem(HoldType.foot,
            '×${latestRoute.holdsByType(HoldType.foot.name).length}'),
        const SizedBox(width: 16),
        _holdLegendItem(HoldType.finish,
            '${latestRoute.holdsByType(HoldType.finish.name).length}'),
      ],
    );
  }

  Widget _holdLegendItem(HoldType type, String count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: type == HoldType.foot ? Colors.transparent : type.color,
            border: Border.all(color: type.color, width: 2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${type.label} $count',
          style: AppTypography.label.copyWith(color: type.color),
        ),
      ],
    );
  }

  Widget _buildLightUpButton(
      BuildContext context, WidgetRef ref, ClimbingRouteModel latestRoute) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentLime,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          HapticFeedback.mediumImpact();

          if (latestRoute.id == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot light up unsaved route')),
            );
            return;
          }

          // Trigger backend update via ActiveRouteNotifier
          ref.read(activeRouteProvider.notifier).activateRoute(latestRoute.id!);

          final bleState = ref.read(bleProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                bleState.isConnected
                    ? '💡 LEDs activated!'
                    : '💡 Route loaded (BLE not connected)',
              ),
              backgroundColor: AppColors.surfaceElevated,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb, size: 22),
            const SizedBox(width: 8),
            Text('LIGHT UP',
                style: AppTypography.button.copyWith(
                  color: AppColors.surface,
                  fontSize: 16,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildLogButtons(
      BuildContext context, WidgetRef ref, ClimbingRouteModel latestRoute) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showLogSheet(context, ref,
                  isSent: true, latestRoute: latestRoute),
              icon: const Icon(Icons.check_circle, size: 20),
              label: Text('Log Send', style: AppTypography.button),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showLogSheet(context, ref,
                  isSent: false, latestRoute: latestRoute),
              icon: const Icon(Icons.refresh, size: 20),
              label: Text('Attempt', style: AppTypography.button),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogSheet(BuildContext context, WidgetRef ref,
      {required bool isSent, required ClimbingRouteModel latestRoute}) {
    int attempts = 1;
    double rating = 0;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 8, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSent ? '🎉 Log Your Send!' : '🔄 Log Attempt',
                    style: AppTypography.headline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${latestRoute.name} (${latestRoute.grade})',
                    style: AppTypography.subtitle,
                  ),
                  const SizedBox(height: 20),
                  // Attempt counter
                  Row(
                    children: [
                      Text('Attempts:', style: AppTypography.body),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: attempts > 1
                            ? () => setModalState(() => attempts--)
                            : null,
                      ),
                      Text('$attempts',
                          style: AppTypography.title.copyWith(fontSize: 20)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setModalState(() => attempts++),
                      ),
                    ],
                  ),
                  if (isSent) ...[
                    const SizedBox(height: 12),
                    Text('Rating:', style: AppTypography.body),
                    const SizedBox(height: 8),
                    StarRating(
                      rating: rating,
                      size: 32,
                      onRatingChanged: (val) =>
                          setModalState(() => rating = val),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    style: AppTypography.body,
                    decoration: const InputDecoration(
                      hintText: 'Notes (optional)',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final entry = LogEntry(
                          id: 'log_${DateTime.now().millisecondsSinceEpoch}',
                          routeId: latestRoute.id ?? 'unknown',
                          routeName: latestRoute.name,
                          routeGrade: latestRoute.grade,
                          date: DateTime.now(),
                          isSent: isSent,
                          attempts: attempts,
                          rating: rating,
                          notes: notesController.text,
                        );

                        try {
                          await ref
                              .read(logbookProvider.notifier)
                              .addEntry(entry);
                          await ref
                              .read(routeListProvider.notifier)
                              .refresh(); // Refresh route data
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isSent
                                  ? '✅ Send logged!'
                                  : '📝 Attempt recorded'),
                              backgroundColor: AppColors.surfaceElevated,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e',
                                  maxLines: 3, overflow: TextOverflow.ellipsis),
                              backgroundColor: AppColors.accentRed,
                            ),
                          );
                        }
                      },
                      child: Text('💾 Save Log', style: AppTypography.button),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
