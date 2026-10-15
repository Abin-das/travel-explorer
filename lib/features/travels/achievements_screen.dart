import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/insights.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../domain/entities/user_activity.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = [...ref.watch(achievementsProvider)]
      ..sort((a, b) => (b.unlocked ? 1 : 0).compareTo(a.unlocked ? 1 : 0));
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpace.gutter),
        itemCount: list.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Text(
              'Calculated from the visits, memories and plans saved on this device.',
              style: context.text.bodySmall,
            );
          }
          final a = list[i - 1];
          return FadeSlideIn(
            index: i,
            child: SurfaceCard(
              child: Row(
                children: [
                  SizedBox(width: 64, child: AchievementBadge(achievement: a, compact: true, showLabel: false)),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(a.title, style: context.text.titleMedium)),
                            if (a.unlocked)
                              const Pill(label: 'Unlocked', icon: Icons.check_rounded, color: AppColors.visited),
                          ],
                        ),
                        Text(a.description, style: context.text.bodySmall),
                        const SizedBox(height: AppSpace.sm),
                        AnimatedProgressBar(value: a.ratio, color: a.unlocked ? AppColors.visited : null, height: 6),
                        const SizedBox(height: 4),
                        Text('${a.progress.clamp(0, a.target)} / ${a.target}', style: context.text.labelSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({super.key, required this.achievement, this.compact = false, this.showLabel = true});
  final Achievement achievement;
  final bool compact;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final icon = _icons[a.id] ?? Icons.emoji_events_rounded;
    return Semantics(
      label: '${a.title}, ${a.unlocked ? 'unlocked' : 'locked, ${a.progress} of ${a.target}'}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: a.ratio,
                  strokeWidth: 4,
                  backgroundColor: context.palette.chip,
                  color: a.unlocked ? AppColors.bucket : context.colors.primary,
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: a.unlocked ? const LinearGradient(colors: [AppColors.bucket, AppColors.warmOrange]) : null,
                  color: a.unlocked ? null : context.palette.chip,
                ),
                child: Icon(icon, color: a.unlocked ? Colors.white : context.palette.muted),
              ),
            ],
          ),
          if (showLabel) ...[
            const SizedBox(height: 6),
            Text(
              a.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: a.unlocked ? null : context.palette.muted),
            ),
          ],
        ],
      ),
    );
  }
}

const _icons = <String, IconData>{
  'first': Icons.flag_rounded,
  'ten': Icons.explore_rounded,
  'fifty': Icons.public_rounded,
  'gems': Icons.diamond_rounded,
  'food': Icons.ramen_dining_rounded,
  'mountain': Icons.terrain_rounded,
  'beach': Icons.beach_access_rounded,
  'waterfall': Icons.water_rounded,
  'heritage': Icons.account_balance_rounded,
  'states': Icons.map_rounded,
  'memories': Icons.auto_stories_rounded,
  'photos': Icons.photo_camera_rounded,
  'planner': Icons.event_note_rounded,
  'globe': Icons.flight_takeoff_rounded,
};
