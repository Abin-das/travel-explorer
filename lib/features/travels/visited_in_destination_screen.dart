import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/insights.dart';
import '../../application/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common.dart';

/// All places the user visited within one destination.
class VisitedInDestinationScreen extends ConsumerWidget {
  const VisitedInDestinationScreen({super.key, required this.destinationId});
  final String destinationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(catalogProvider).value;
    final d = cat?.destination(destinationId);
    final visited = ref.watch(visitedPlacesProvider).where((v) => v.place.destinationId == destinationId).toList();
    final total = cat?.sightCount(destinationId) ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(d == null ? 'Visited places' : '${d.name} — visited')),
      body: visited.isEmpty
          ? const EmptyState(icon: Icons.luggage_rounded, title: 'Nothing visited here yet', message: '')
          : ListView(
              padding: const EdgeInsets.all(AppSpace.gutter),
              children: [
                Text(
                  '${plural(visited.length, 'place')} visited of $total sights in the guide',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpace.sm),
                AnimatedProgressBar(value: total == 0 ? 0 : visited.length / total),
                const SizedBox(height: AppSpace.lg),
                for (final v in visited)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: PlaceTile(place: v.place, subtitle: 'Visited ${formatDate(v.visit.visitedOn)}'),
                  ),
              ],
            ),
    );
  }
}
