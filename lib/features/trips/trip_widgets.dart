import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';
import '../../domain/entities/user_activity.dart';

class TripList extends ConsumerWidget {
  const TripList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = [...ref.watch(tripsProvider)]..sort((a, b) => a.startDate.compareTo(b.startDate));
    final today = DateTime.now();
    final upcoming = trips.where((t) => !t.endDate.isBefore(DateTime(today.year, today.month, today.day))).toList();
    final past = trips.where((t) => !upcoming.contains(t)).toList().reversed.toList();
    return Stack(
      children: [
        if (trips.isEmpty)
          EmptyState(
            icon: Icons.event_note_rounded,
            title: 'No trips planned',
            message: 'Create a trip, pick a destination and organise attractions and food spots day by day.',
            actionLabel: 'Plan a trip',
            onAction: () => context.push(Routes.newTrip),
          )
        else
          ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 120),
            children: [
              if (upcoming.isNotEmpty) ...[
                Text('Upcoming', style: context.text.titleLarge),
                const SizedBox(height: AppSpace.sm),
                for (final t in upcoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: TripCard(trip: t),
                  ),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                Text('Past trips', style: context.text.titleLarge),
                const SizedBox(height: AppSpace.sm),
                for (final t in past)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: TripCard(trip: t),
                  ),
              ],
            ],
          ),
        if (trips.isNotEmpty)
          Positioned(
            right: AppSpace.lg,
            bottom: AppSpace.lg,
            child: FloatingActionButton.extended(
              heroTag: 'new-trip',
              onPressed: () => context.push(Routes.newTrip),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New trip'),
            ),
          ),
      ],
    );
  }
}

class TripCard extends ConsumerWidget {
  const TripCard({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(catalogProvider).value?.destination(trip.destinationId);
    final total = trip.totalActivities;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(Routes.trip(trip.id)),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 112,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.lg)),
              child: d == null ? const MissingPhoto() : DestinationCover(destination: d),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                  Text('${d?.name ?? ''} · ${plural(trip.days.length, 'day')}', style: context.text.bodySmall),
                  Text(
                    '${formatShortDate(trip.startDate)} – ${formatShortDate(trip.endDate)}',
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  AnimatedProgressBar(value: total == 0 ? 0 : trip.completedActivities / total, height: 6),
                  const SizedBox(height: 4),
                  Text('${trip.completedActivities}/$total activities done', style: context.text.labelSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
