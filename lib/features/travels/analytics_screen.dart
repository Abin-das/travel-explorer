import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/insights.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/common.dart';
import 'achievements_screen.dart' show AchievementBadge;

Color chartColor(BuildContext context) => context.isDark ? AppColors.chartDark : AppColors.chartLight;

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travelStatsProvider);
    final ach = ref.watch(achievementsProvider);
    final totals = [
      (Icons.public_rounded, s.countries, 'Countries'),
      (Icons.location_city_rounded, s.regions, 'States'),
      (Icons.apartment_rounded, s.cities, 'Cities'),
      (Icons.place_rounded, s.attractions, 'Attractions'),
      (Icons.diamond_rounded, s.hiddenGems, 'Hidden gems'),
      (Icons.restaurant_rounded, s.foodSpots, 'Food spots'),
      (Icons.photo_library_rounded, s.photos, 'Photos'),
      (Icons.ramen_dining_rounded, s.dishesTried, 'Dishes tried'),
    ];
    final totalCat = s.byCategory.values.fold(0, (a, b) => a + b);
    final cats = s.byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Travel Analytics')),
      body: s.placesVisited == 0
          ? EmptyState(
              icon: Icons.insights_rounded,
              title: 'No data yet',
              message: 'Charts appear once you mark places as visited.',
              actionLabel: 'Explore places',
              onAction: () => context.go(Routes.explore),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.xxxl),
              children: [
                ResponsiveGrid(
                  minTileWidth: 100,
                  spacing: AppSpace.sm,
                  children: [for (final (i, v, l) in totals) StatTile(icon: i, value: v, label: l)],
                ),
                const DetailHeading('Places visited by state'),
                SurfaceCard(
                  child: _HBarList(rows: [for (final e in s.byRegion.entries) (e.key, e.value, '${e.value}')]),
                ),
                const DetailHeading('Places visited by category'),
                Text(
                  'A place can belong to several categories, so shares are of all category tags.',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: AppSpace.sm),
                SurfaceCard(
                  child: _HBarList(
                    rows: [
                      for (final e in cats)
                        (e.key.label, e.value, '${(e.value * 100 / (totalCat == 0 ? 1 : totalCat)).round()}%'),
                    ],
                  ),
                ),
                const DetailHeading('Monthly travel activity'),
                Text('Places visited per month, last 12 months. Tap a bar for details.', style: context.text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                SurfaceCard(child: _MonthlyChart(monthly: s.monthly)),
                DetailHeading('Achievements (${ach.where((a) => a.unlocked).length}/${ach.length})'),
                Wrap(
                  spacing: AppSpace.md,
                  runSpacing: AppSpace.md,
                  children: [
                    for (final a in ach.where((a) => a.unlocked))
                      SizedBox(width: 96, child: AchievementBadge(achievement: a, compact: true)),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push(Routes.achievements),
                  child: const Text('See all achievements'),
                ),
              ],
            ),
    );
  }
}

/// Horizontal bars with the label above and the value directly at the bar end.
/// Single series → one hue; every value is also printed as text.
class _HBarList extends StatelessWidget {
  const _HBarList({required this.rows});
  final List<(String, int, String)> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return Text('No data yet', style: context.text.bodySmall);
    final max = rows.map((r) => r.$2).reduce((a, b) => a > b ? a : b).toDouble();
    final color = chartColor(context);
    return Column(
      children: [
        for (final (label, v, text) in rows)
          Semantics(
            label: '$label: $text',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.text.bodyMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: v / max),
                                duration: AppDurations.slow,
                                curve: Curves.easeOutCubic,
                                builder: (_, t, _) => Container(
                                  height: 12,
                                  width: (c.maxWidth * t).clamp(4, c.maxWidth),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      SizedBox(
                        width: 44,
                        child: Text(text, textAlign: TextAlign.right, style: context.text.labelLarge),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.monthly});
  final Map<DateTime, int> monthly;

  @override
  Widget build(BuildContext context) {
    final entries = monthly.entries.toList();
    final maxY = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);
    final top = (maxY < 4 ? 4 : maxY + 1).toDouble();
    final color = chartColor(context);
    final muted = context.palette.muted;
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: top,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: (top / 4).ceilToDouble(),
            getDrawingHorizontalLine: (_) => FlLine(color: context.palette.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (top / 4).ceilToDouble(),
                getTitlesWidget: (v, _) => Text('${v.toInt()}', style: context.text.labelSmall?.copyWith(color: muted)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      monthShort(entries[i].key.month).substring(0, 1),
                      style: context.text.labelSmall?.copyWith(color: muted),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => context.colors.inverseSurface,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${formatMonthYear(entries[group.x].key)}\n${plural(rod.toY.toInt(), 'place')}',
                context.text.labelMedium!.copyWith(color: context.colors.onInverseSurface),
              ),
            ),
          ),
          barGroups: [
            for (final (i, e) in entries.indexed)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: e.value.toDouble(),
                    color: color,
                    width: 12,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
        ),
        duration: AppDurations.slow,
      ),
    );
  }
}
