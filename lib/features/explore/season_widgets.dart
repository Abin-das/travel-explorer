import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/common.dart';
import '../../domain/entities/season.dart';

/// 12-month strip highlighting best / rainy / peak months.
class MonthStrip extends StatelessWidget {
  const MonthStrip({super.key, required this.guide});
  final SeasonGuide guide;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().month;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two rows of six so each month gets a readable three-letter label.
        for (final half in const [1, 7]) ...[
          if (half == 7) const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              for (var m = half; m < half + 6; m++) ...[
                if (m != half) const SizedBox(width: AppSpace.xs + 2),
                Expanded(
                  child: _MonthCell(
                    month: m,
                    best: guide.bestMonths.contains(m),
                    rainy: guide.rainyMonths.contains(m),
                    peak: guide.peakMonths.contains(m),
                    current: m == now,
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _Key(color: SeasonFit.best.color, label: 'Best months'),
            const _Key(color: AppColors.oceanBlue, icon: Icons.water_drop_rounded, label: 'Rainy'),
            const _Key(icon: Icons.groups_rounded, label: 'Peak crowds'),
            const _Key(border: true, label: 'This month'),
          ],
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.month,
    required this.best,
    required this.rainy,
    required this.peak,
    required this.current,
  });

  final int month;
  final bool best;
  final bool rainy;
  final bool peak;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final bg = best
        ? SeasonFit.best.color
        : rainy
        ? AppColors.oceanBlue.withValues(alpha: 0.14)
        : context.palette.chip;
    final fg = best
        ? Colors.white
        : rainy
        ? AppColors.oceanBlue
        : context.palette.muted;
    final status = [if (best) 'best time', if (rainy) 'rainy', if (peak) 'peak crowds', if (current) 'this month'];

    return Semantics(
      label: '${monthShort(month)}${status.isEmpty ? '' : ': ${status.join(', ')}'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm, horizontal: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: current ? context.colors.onSurface : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                monthShort(month),
                maxLines: 1,
                style: context.text.labelMedium?.copyWith(
                  color: best ? Colors.white : context.colors.onSurface,
                  fontWeight: best || current ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (rainy) Icon(Icons.water_drop_rounded, size: 12, color: fg),
                  if (peak) Icon(Icons.groups_rounded, size: 14, color: fg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({this.color, this.icon, this.border = false, required this.label});
  final Color? color;
  final IconData? icon;
  final bool border;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 14, color: color ?? context.palette.muted)
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: border ? Border.all(color: context.colors.onSurface, width: 2) : null,
            ),
          ),
        const SizedBox(width: 4),
        Text(label, style: context.text.labelSmall),
      ],
    );
  }
}

class SeasonCardView extends StatelessWidget {
  const SeasonCardView({super.key, required this.card, this.width = 230});
  final SeasonCard card;
  final double width;

  IconData get _icon => switch (card.name.toLowerCase()) {
    final n when n.contains('monsoon') || n.contains('wet') || n.contains('rain') => Icons.water_drop_rounded,
    final n when n.contains('winter') => Icons.ac_unit_rounded,
    final n when n.contains('spring') => Icons.local_florist_rounded,
    final n when n.contains('autumn') => Icons.eco_rounded,
    _ => Icons.wb_sunny_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = card.fit.color;
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.withValues(alpha: context.isDark ? 0.32 : 0.16),
            c.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: c),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text(card.name, style: context.text.titleMedium)),
              Flexible(
                child: Pill(label: card.fit.label, color: c, solid: true),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(card.months, style: context.text.labelMedium?.copyWith(color: context.palette.muted)),
          const SizedBox(height: AppSpace.sm),
          Text(
            card.bestFor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall?.copyWith(color: c),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(card.weather, overflow: TextOverflow.fade, style: context.text.bodySmall),
          ),
          if (card.activities.isNotEmpty)
            Text(
              card.activities.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall,
            ),
        ],
      ),
    );
  }
}

/// Explicit disclaimer: this is curated guidance, not live weather.
class CuratedSeasonNote extends StatelessWidget {
  const CuratedSeasonNote({super.key});

  @override
  Widget build(BuildContext context) => const SampleDataNote(
    text:
        'Curated seasonal guidance based on typical conditions — not a live weather forecast. '
        'Check a forecast service before travelling.',
  );
}
