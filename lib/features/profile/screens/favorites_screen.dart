import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/grade_badge.dart';
import '../../../core/widgets/star_rating.dart';
import '../../discovery/data/models/climbing_route_model.dart';
import '../../discovery/screens/route_detail_screen.dart';
import '../presentation/providers/favorites_notifier.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Routes', style: AppTypography.headline),
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
    final stateAsync = ref.watch(favoritesProvider);

    return stateAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accentPrimary),
      ),
      error: (err, stack) => Center(
        child: Text('Error loading favorites: $err', style: AppTypography.body),
      ),
      data: (routes) {
        if (routes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text("You haven't saved any routes yet.", style: AppTypography.subtitle),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(favoritesProvider.notifier).refresh(),
          color: AppColors.accentPrimary,
          backgroundColor: AppColors.surfaceVariant,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              return _FavoriteRouteCard(
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
class _FavoriteRouteCard extends ConsumerWidget {
  const _FavoriteRouteCard({required this.route, required this.onTap});
  final ClimbingRouteModel route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${route.setterName} · ${route.sendCount} sends',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      ref.watch(favoritesProvider);
                      final isFav = ref.read(favoritesProvider.notifier).isFavorite(route.id!);
                      return GestureDetector(
                        onTap: () {
                          ref.read(favoritesProvider.notifier).toggleFavorite(route);
                        },
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isFav ? AppColors.accentRed : AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StarRating(rating: route.rating, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        route.rating.toStringAsFixed(1),
                        style: AppTypography.label,
                      ),
                    ],
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
