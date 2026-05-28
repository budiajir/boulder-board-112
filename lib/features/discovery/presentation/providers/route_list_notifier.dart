import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/climbing_route_model.dart';
import '../../data/repositories/route_repository_impl.dart';

enum RouteSortOption { mostClimbed, newest, highestRated, gradeAsc, gradeDesc }

extension RouteSortOptionExt on RouteSortOption {
  String get label {
    switch (this) {
      case RouteSortOption.mostClimbed:
        return 'Most Climbed';
      case RouteSortOption.newest:
        return 'Newest';
      case RouteSortOption.highestRated:
        return 'Highest Rated';
      case RouteSortOption.gradeAsc:
        return 'Beginner to Pro';
      case RouteSortOption.gradeDesc:
        return 'Pro to Beginner';
    }
  }
}

class RouteListState {
  const RouteListState({
    this.allRoutes = const [],
    this.searchQuery = '',
    this.gradeFilter,
    this.minGrade,
    this.maxGrade,
    this.angleFilter,
    this.sortOption = RouteSortOption.mostClimbed,
  });

  final List<ClimbingRouteModel> allRoutes;
  final String searchQuery;
  final String? gradeFilter;
  final int? minGrade;
  final int? maxGrade;
  final int? angleFilter;
  final RouteSortOption sortOption;

  List<ClimbingRouteModel> get filteredRoutes {
    var result = List<ClimbingRouteModel>.from(allRoutes);

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((r) {
        return r.name.toLowerCase().contains(query) ||
            r.setterName.toLowerCase().contains(query) ||
            r.grade.toLowerCase().contains(query);
      }).toList();
    }

    if (gradeFilter != null) {
      result = result.where((r) => r.grade == gradeFilter).toList();
    }

    if (minGrade != null || maxGrade != null) {
      result = result.where((r) {
        final gradeNum = int.tryParse(r.grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (minGrade != null && gradeNum < minGrade!) return false;
        if (maxGrade != null && gradeNum > maxGrade!) return false;
        return true;
      }).toList();
    }

    if (angleFilter != null) {
      result = result.where((r) => r.angle == angleFilter).toList();
    }

    switch (sortOption) {
      case RouteSortOption.mostClimbed:
        result.sort((a, b) => b.sendCount.compareTo(a.sendCount));
        break;
      case RouteSortOption.newest:
        result.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
        break;
      case RouteSortOption.highestRated:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case RouteSortOption.gradeAsc:
        result.sort((a, b) {
          final aNum = int.tryParse(a.grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final bNum = int.tryParse(b.grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return aNum.compareTo(bNum);
        });
        break;
      case RouteSortOption.gradeDesc:
        result.sort((a, b) {
          final aNum = int.tryParse(a.grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final bNum = int.tryParse(b.grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return bNum.compareTo(aNum);
        });
        break;
    }

    return result;
  }

  RouteListState copyWith({
    List<ClimbingRouteModel>? allRoutes,
    String? searchQuery,
    String? gradeFilter,
    int? minGrade,
    int? maxGrade,
    int? angleFilter,
    RouteSortOption? sortOption,
    bool clearGradeFilter = false,
  }) {
    return RouteListState(
      allRoutes: allRoutes ?? this.allRoutes,
      searchQuery: searchQuery ?? this.searchQuery,
      gradeFilter: clearGradeFilter ? null : (gradeFilter ?? this.gradeFilter),
      minGrade: minGrade ?? this.minGrade,
      maxGrade: maxGrade ?? this.maxGrade,
      angleFilter: angleFilter ?? this.angleFilter,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class RouteListNotifier extends AsyncNotifier<RouteListState> {
  @override
  Future<RouteListState> build() async {
    final repo = RouteRepositoryImpl();
    final routes = await repo.getRoutes();
    return RouteListState(allRoutes: routes);
  }

  void setSearchQuery(String query) {
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(searchQuery: query));
    }
  }

  void setGradeFilter(String? grade) {
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(gradeFilter: grade, clearGradeFilter: grade == null));
    }
  }

  void setAngleFilter(int? angle) {
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(angleFilter: angle));
    }
  }

  void setSortOption(RouteSortOption option) {
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(sortOption: option));
    }
  }
  
  void clearFilters() {
    if (state.hasValue) {
      state = AsyncData(RouteListState(allRoutes: state.value!.allRoutes));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = RouteRepositoryImpl();
    final routes = await repo.getRoutes();
    state = AsyncData(RouteListState(allRoutes: routes));
  }
}

final routeListProvider = AsyncNotifierProvider<RouteListNotifier, RouteListState>(RouteListNotifier.new);
