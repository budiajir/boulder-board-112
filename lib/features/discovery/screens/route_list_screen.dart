import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ble_status_indicator.dart';
import '../../../core/widgets/grade_badge.dart';
import '../../../core/widgets/star_rating.dart';
import '../data/models/climbing_route_model.dart';
import '../presentation/providers/route_list_notifier.dart';
import '../../profile/presentation/providers/favorites_notifier.dart';
import '../../ble/presentation/providers/ble_notifier.dart';
import 'route_detail_screen.dart';

/// Main discovery screen showing filterable/sortable route list.
class RouteListScreen extends ConsumerStatefulWidget {
  const RouteListScreen({super.key});

  @override
  ConsumerState<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends ConsumerState<RouteListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildSearchBar(context),
              _buildFilterChips(context),
              Expanded(child: _buildRouteList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final bleState = ref.watch(bleProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Discover', style: AppTypography.display),
          BleStatusIndicator(isConnected: bleState.isConnected, showLabel: true),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: AppTypography.body,
        decoration: InputDecoration(
          hintText: 'Search routes...',
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textTertiary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(routeListProvider.notifier).setSearchQuery('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          ref.read(routeListProvider.notifier).setSearchQuery(value);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final stateAsync = ref.watch(routeListProvider);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChipButton(
            label: stateAsync.valueOrNull != null 
                ? 'Sort: ${stateAsync.value!.sortOption.label}' 
                : 'Sort',
            icon: Icons.sort,
            onTap: () => _showSortSheet(context),
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            label: stateAsync.valueOrNull?.gradeFilter ?? 'Grade',
            icon: Icons.trending_up,
            isActive: stateAsync.valueOrNull?.gradeFilter != null,
            onTap: () => _showGradeFilter(context),
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            label: stateAsync.valueOrNull?.angleFilter != null 
                ? '${stateAsync.value!.angleFilter}°' 
                : 'Angle',
            icon: Icons.rotate_right,
            isActive: stateAsync.valueOrNull?.angleFilter != null,
            onTap: () => _showAngleFilter(context),
          ),
          if (stateAsync.valueOrNull?.gradeFilter != null || stateAsync.valueOrNull?.angleFilter != null) ...[
            const SizedBox(width: 8),
            _FilterChipButton(
              label: 'Clear',
              icon: Icons.close,
              onTap: () {
                 ref.read(routeListProvider.notifier).clearFilters();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteList(BuildContext context) {
    final stateAsync = ref.watch(routeListProvider);

    return stateAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accentPrimary),
      ),
      error: (err, stack) => Center(
        child: Text('Error loading routes: $err', style: AppTypography.body),
      ),
      data: (state) {
        if (state.filteredRoutes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text('No routes found', style: AppTypography.subtitle),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(routeListProvider.notifier).refresh(),
          color: AppColors.accentPrimary,
          backgroundColor: AppColors.surfaceVariant,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.filteredRoutes.length,
            itemBuilder: (context, index) {
              return _RouteCard(
                route: state.filteredRoutes[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RouteDetailScreen(route: state.filteredRoutes[index]),
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

  void _showSortSheet(BuildContext context) {
    final currentOption = ref.read(routeListProvider).valueOrNull?.sortOption;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort By', style: AppTypography.title),
              const SizedBox(height: 16),
              ...RouteSortOption.values.map((option) {
                final isSelected = currentOption == option;
                return ListTile(
                  title: Text(option.label, style: AppTypography.body),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.accentPrimary)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {
                    ref.read(routeListProvider.notifier).setSortOption(option);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showGradeFilter(BuildContext context) {
    final currentGrade = ref.read(routeListProvider).valueOrNull?.gradeFilter;
    final grades = List.generate(18, (i) => 'V$i');
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter by Grade', style: AppTypography.title),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: grades.map((g) {
                  final isSelected = currentGrade == g;
                  return ChoiceChip(
                    label: Text(g),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(routeListProvider.notifier).setGradeFilter(isSelected ? null : g);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAngleFilter(BuildContext context) {
    final currentAngle = ref.read(routeListProvider).valueOrNull?.angleFilter;
    final angles = [0, 15, 25, 30, 35, 40, 45, 50];
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter by Angle', style: AppTypography.title),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: angles.map((a) {
                  final isSelected = currentAngle == a;
                  return ChoiceChip(
                    label: Text('$a°'),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(routeListProvider.notifier).setAngleFilter(isSelected ? null : a);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Route Card ────────────────────────────────────────────
class _RouteCard extends ConsumerWidget {
  const _RouteCard({required this.route, required this.onTap});
  final ClimbingRouteModel route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
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
                        if (route.isBenchmark)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentYellow.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '⭐ Benchmark',
                              style: AppTypography.label.copyWith(
                                color: AppColors.accentYellow,
                                fontSize: 10,
                              ),
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
                      ref.watch(favoritesProvider); // Trigger rebuilds when favorites change
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

// ─── Filter Chip Button ─────────────────────────────────────
class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentPrimary.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.accentPrimary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? AppColors.accentPrimary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: isActive ? AppColors.accentPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
