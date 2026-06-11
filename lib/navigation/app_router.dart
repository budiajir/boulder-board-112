import 'package:flutter/material.dart';
import '../features/discovery/screens/route_list_screen.dart';
import '../features/board/screens/board_view_screen.dart';
import '../features/editor/screens/route_editor_screen.dart';
import '../features/logbook/screens/logbook_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Main navigation shell with bottom tab bar.
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RouteListScreen(),
    BoardViewScreen(),
    RouteEditorScreen(),
    LogbookScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _navItem(0, Icons.explore_outlined, Icons.explore, 'Discover'),
              _navItem(1, Icons.grid_view_outlined, Icons.grid_view, 'Board'),
              _navItem(2, Icons.add_circle_outline, Icons.add_circle, 'Create'),
              _navItem(
                  3, Icons.menu_book_outlined, Icons.menu_book, 'Logbook'),
              _navItem(
                  4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      int index, IconData iconOutlined, IconData iconFilled, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? iconFilled : iconOutlined,
                  key: ValueKey(isSelected),
                  size: 24,
                  color: isSelected
                      ? AppColors.accentPrimary
                      : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  fontSize: 10,
                  color: isSelected
                      ? AppColors.accentPrimary
                      : AppColors.textTertiary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
