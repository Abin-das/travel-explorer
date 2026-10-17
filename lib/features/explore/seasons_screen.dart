import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';
import '../../domain/entities/geography.dart';
import 'season_widgets.dart';

/// "Best Time to Visit": pick a month, see which destinations suit it.
class SeasonsScreen extends ConsumerStatefulWidget {
  const SeasonsScreen({super.key});

  @override
  ConsumerState<SeasonsScreen> createState() => _SeasonsScreenState();
}

class _SeasonsScreenState extends ConsumerState<SeasonsScreen> {
  int _month = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final countryId = ref.watch(selectedCountryIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Best Time to Visit')),
      body: AsyncView(
        value: ref.watch(catalogProvider),
        builder: (cat) {
          final dests = cat.destinationsIn(countryId: countryId);
          final good = dests.where((d) => d.season.isGoodMonth(_month)).toList();
          final other = dests.where((d) => !d.season.isGoodMonth(_month)).toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpace.xxxl),
            children: [
              _MonthPicker(selected: _month, onChanged: (m) => setState(() => _month = m)),
              const SizedBox(height: AppSpace.lg),
              const Padding(padding: AppSpace.screen, child: CuratedSeasonNote()),
              SectionHeader('Great in ${monthShort(_month)}', subtitle: plural(good.length, 'destination')),
              if (good.isEmpty)
                const EmptyState(
                  compact: true,
                  icon: Icons.cloud_rounded,
                  title: 'No ideal picks',
                  message: 'Try a different month.',
                ),
              for (final d in good) _SeasonDestination(destination: d, month: _month),
              if (other.isNotEmpty) ...[
                const SectionHeader('Better at another time'),
                for (final d in other) _SeasonDestination(destination: d, month: _month),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// All twelve months as a 2×6 grid; a dot marks the current month.
class _MonthPicker extends StatelessWidget {
  const _MonthPicker({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().month;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, 0),
      child: Column(
        children: [
          for (final half in const [1, 7]) ...[
            if (half == 7) const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                for (var m = half; m < half + 6; m++) ...[
                  if (m != half) const SizedBox(width: AppSpace.sm),
                  Expanded(child: _monthButton(context, m, now)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _monthButton(BuildContext context, int m, int now) {
    final isSelected = m == selected;
    final fg = isSelected ? context.colors.onPrimary : context.colors.onSurface;
    return Semantics(
      selected: isSelected,
      button: true,
      label: '${monthShort(m)}${m == now ? ', this month' : ''}',
      excludeSemantics: true,
      child: Material(
        color: isSelected ? context.colors.primary : context.palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smAll,
          side: BorderSide(color: isSelected ? Colors.transparent : context.palette.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(m),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm + 2, horizontal: 2),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    monthShort(m),
                    maxLines: 1,
                    style: context.text.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: m == now ? (isSelected ? fg : context.colors.primary) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeasonDestination extends StatelessWidget {
  const _SeasonDestination({required this.destination, required this.month});
  final Destination destination;
  final int month;

  @override
  Widget build(BuildContext context) {
    final s = destination.season;
    final rainy = s.rainyMonths.contains(month);
    final peak = s.peakMonths.contains(month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.md),
      child: SurfaceCard(
        onTap: () => context.push(Routes.destination(destination.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: AppRadius.mdAll,
                    child: DestinationCover(destination: destination),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(destination.name, style: context.text.titleMedium),
                      Text('Best: ${monthRange(s.bestMonths)} · ${s.recommendedSeason}', style: context.text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (s.isGoodMonth(month))
                  const Pill(label: 'Recommended', icon: Icons.thumb_up_rounded, color: AppColors.visited),
                if (rainy)
                  const Pill(label: 'Rainy season', icon: Icons.water_drop_rounded, color: AppColors.oceanBlue),
                if (peak) const Pill(label: 'Peak season', icon: Icons.groups_rounded, color: AppColors.warmOrange),
                if (s.offMonths.contains(month))
                  const Pill(label: 'Off-season', icon: Icons.nights_stay_rounded, color: AppColors.slate),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            MonthStrip(guide: s),
          ],
        ),
      ),
    );
  }
}
