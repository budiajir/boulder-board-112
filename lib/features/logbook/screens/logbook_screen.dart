import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/grade_badge.dart';
import '../../../core/widgets/star_rating.dart';
import '../data/models/log_entry.dart';
import '../presentation/providers/logbook_notifier.dart';

/// Logbook screen showing climbing statistics and log entries.
class LogbookScreen extends ConsumerWidget {
  const LogbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final logbookAsync = ref.watch(logbookProvider);

                    return logbookAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.accentPrimary),
                      ),
                      error: (err, stack) => Center(
                        child: Text('Error: $err', style: AppTypography.body),
                      ),
                      data: (state) {
                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildStatsRow(state),
                            const SizedBox(height: 16),
                            _buildGradeChart(state),
                            const SizedBox(height: 20),
                            Text('Recent Activity',
                                style: AppTypography.title
                                    .copyWith(fontSize: 16)),
                            const SizedBox(height: 12),
                            if (state.entries.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text('No logs yet. Go send some routes!',
                                      style: AppTypography.bodySmall),
                                ),
                              )
                            else
                              ...state.entries.map(
                                (entry) => _LogEntryCard(entry: entry),
                              ),
                            const SizedBox(height: 80),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Text('My Logbook', style: AppTypography.display),
    );
  }

  Widget _buildStatsRow(LogbookState state) {
    return Row(
      children: [
        _StatCard(
          label: 'Total Sends',
          value: '${state.totalSends}',
          icon: Icons.check_circle,
          color: AppColors.accentGreen,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'This Month',
          value: '${state.thisMonthSends}',
          icon: Icons.calendar_today,
          color: AppColors.accentPrimary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Avg Grade',
          value: 'V${state.averageGrade.toStringAsFixed(1)}',
          icon: Icons.trending_up,
          color: AppColors.accentYellow,
        ),
      ],
    );
  }

  Widget _buildGradeChart(LogbookState state) {
    final dist = state.gradeDistribution;
    if (dist.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxVal = dist.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grade Distribution', style: AppTypography.label),
          const SizedBox(height: 12),
          ...dist.entries.map((entry) {
            final fraction = maxVal > 0 ? entry.value / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(entry.key,
                        style: AppTypography.label
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 18,
                        backgroundColor: AppColors.surface,
                        valueColor: AlwaysStoppedAnimation(
                            AppColors.accentPrimary.withValues(alpha: 0.7)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${entry.value}',
                      style: AppTypography.label
                          .copyWith(color: AppColors.textPrimary),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: AppTypography.headline.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.label.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─── Log Entry Card ────────────────────────────────────────
class _LogEntryCard extends StatelessWidget {
  const _LogEntryCard({required this.entry});
  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: entry.isSent
                    ? AppColors.accentGreen.withValues(alpha: 0.15)
                    : AppColors.accentYellow.withValues(alpha: 0.15),
              ),
              child: Icon(
                entry.isSent ? Icons.check : Icons.refresh,
                size: 18,
                color: entry.isSent
                    ? AppColors.accentGreen
                    : AppColors.accentYellow,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.routeName,
                          style: AppTypography.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      GradeBadge(
                          grade: entry.routeGrade,
                          size: GradeBadgeSize.small),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.isSent
                        ? 'Sends: ${entry.attempts == 1 ? "Flash! ⚡" : "1"} · Attempts: ${entry.attempts}'
                        : 'Attempts: ${entry.attempts} · In Progress',
                    style: AppTypography.bodySmall,
                  ),
                  if (entry.isSent && entry.rating > 0) ...[
                    const SizedBox(height: 4),
                    StarRating(rating: entry.rating, size: 14),
                  ],
                  if (entry.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.notes,
                      style: AppTypography.label.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Date
            Text(
              _formatDate(entry.date),
              style: AppTypography.label,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
