import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/grade_badge.dart';
import '../../../core/widgets/star_rating.dart';
import '../../discovery/data/models/climbing_route_model.dart';
import '../../discovery/screens/route_detail_screen.dart';
import '../presentation/providers/my_routes_notifier.dart';

class MyRoutesScreen extends ConsumerStatefulWidget {
  const MyRoutesScreen({super.key});

  @override
  ConsumerState<MyRoutesScreen> createState() => _MyRoutesScreenState();
}

class _MyRoutesScreenState extends ConsumerState<MyRoutesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Routes', style: AppTypography.headline),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: _buildRouteList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteList(BuildContext context) {
    final stateAsync = ref.watch(myRoutesProvider);

    return stateAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accentPrimary),
      ),
      error: (err, stack) => Center(
        child: Text('Error loading routes: $err', style: AppTypography.body),
      ),
      data: (routes) {
        if (routes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.route, size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text("You haven't created any routes yet.", style: AppTypography.subtitle),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(myRoutesProvider.notifier).refresh(),
          color: AppColors.accentPrimary,
          backgroundColor: AppColors.surfaceVariant,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              return _MyRouteCard(
                route: routes[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailScreen(route: routes[index]),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Route Card ────────────────────────────────────────────
class _MyRouteCard extends StatelessWidget {
  const _MyRouteCard({required this.route, required this.onTap});
  final ClimbingRouteModel route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GradeBadge(grade: route.grade, size: GradeBadgeSize.medium),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            route.name,
                            style: AppTypography.title.copyWith(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (route.isDraft)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.textTertiary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Draft',
                              style: AppTypography.label.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${route.sendCount} sends · ${route.computedMoveCount} moves',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StarRating(rating: route.rating, size: 14),
                  const SizedBox(height: 4),
                  Text(
                    route.rating.toStringAsFixed(1),
                    style: AppTypography.label,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
