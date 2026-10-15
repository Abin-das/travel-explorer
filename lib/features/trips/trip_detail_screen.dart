import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/catalog.dart';
import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/user_activity.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});
  final String tripId;

  Future<void> _update(WidgetRef ref, Trip t, int dayIndex, List<TripActivity> acts) {
    final days = [...t.days];
    days[dayIndex] = days[dayIndex].copyWith(activities: acts);
    return ref.read(tripsProvider.notifier).put(t.copyWith(days: days));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripProvider(tripId));
    final cat = ref.watch(catalogProvider).value;
    if (trip == null || cat == null) {
      return Scaffold(
        appBar: AppBar(),
        body: trip == null
            ? const EmptyState(icon: Icons.event_busy_rounded, title: 'Trip not found', message: '')
            : const SkeletonList(),
      );
    }
    final dest = cat.destination(trip.destinationId);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                tooltip: 'Edit trip',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => context.push('/trip/${trip.id}/edit'),
              ),
              IconButton(
                tooltip: 'Delete trip',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: 'Delete trip?',
                    message: 'The plan will be removed. Your visits are not affected.',
                    confirmLabel: 'Delete',
                    destructive: true,
                  );
                  if (!ok) return;
                  await ref.read(tripsProvider.notifier).delete(trip.id);
                  if (context.mounted) context.pop();
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (dest != null) DestinationCover(destination: dest),
                  const BottomScrim(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 0),
            sliver: SliverList.list(
              children: [
                Text(
                  '${dest?.name ?? ''} · Duration: ${plural(trip.days.length, 'Day')}',
                  style: context.text.titleMedium,
                ),
                Text('${formatDate(trip.startDate)} – ${formatDate(trip.endDate)}', style: context.text.bodySmall),
                const SizedBox(height: AppSpace.md),
                AnimatedProgressBar(
                  value: trip.totalActivities == 0 ? 0 : trip.completedActivities / trip.totalActivities,
                ),
                const SizedBox(height: AppSpace.sm),
                const SampleDataNote(
                  text:
                      'Ticking an activity marks the plan item done — it does not mark the place as visited. '
                      'Use "Mark as Visited" on the place page for that.',
                ),
              ],
            ),
          ),
          for (var i = 0; i < trip.days.length; i++)
            SliverToBoxAdapter(
              child: _DayCard(
                trip: trip,
                dayIndex: i,
                catalog: cat,
                onChanged: (acts) => _update(ref, trip, i, acts),
                onMove: (act, to) async {
                  final days = [...trip.days];
                  days[i] = days[i].copyWith(activities: days[i].activities.where((a) => a.id != act.id).toList());
                  days[to] = days[to].copyWith(activities: [...days[to].activities, act]);
                  await ref.read(tripsProvider.notifier).put(trip.copyWith(days: days));
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxxl)),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.trip,
    required this.dayIndex,
    required this.catalog,
    required this.onChanged,
    required this.onMove,
  });

  final Trip trip;
  final int dayIndex;
  final Catalog catalog;
  final ValueChanged<List<TripActivity>> onChanged;
  final void Function(TripActivity act, int toDay) onMove;

  @override
  Widget build(BuildContext context) {
    final day = trip.days[dayIndex];
    final date = trip.startDate.add(Duration(days: dayIndex));
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 0),
      child: SurfaceCard(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.sm, AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(100)),
                  child: Text(
                    'Day ${dayIndex + 1}',
                    style: context.text.labelLarge?.copyWith(color: context.colors.onPrimary),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text(formatDayMonth(date), style: context.text.bodySmall)),
                TextButton.icon(
                  onPressed: () => _addActivity(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (day.activities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                child: Text('Nothing planned yet', style: context.text.bodySmall),
              )
            else
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorderItem: (from, to) {
                  final list = [...day.activities];
                  list.insert(to, list.removeAt(from));
                  onChanged(list);
                },
                children: [
                  for (final (i, a) in day.activities.indexed)
                    _ActivityTile(
                      key: ValueKey(a.id),
                      index: i,
                      activity: a,
                      place: catalog.place(a.placeId),
                      days: trip.days.length,
                      dayIndex: dayIndex,
                      onToggle: () =>
                          onChanged([for (final x in day.activities) x.id == a.id ? x.copyWith(done: !x.done) : x]),
                      onDelete: () => onChanged(day.activities.where((x) => x.id != a.id).toList()),
                      onMove: (to) => onMove(a, to),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addActivity(BuildContext context) async {
    final result = await showModalBottomSheet<TripActivity>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddActivitySheet(catalog: catalog, destinationId: trip.destinationId),
    );
    if (result != null) onChanged([...trip.days[dayIndex].activities, result]);
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    super.key,
    required this.index,
    required this.activity,
    required this.place,
    required this.days,
    required this.dayIndex,
    required this.onToggle,
    required this.onDelete,
    required this.onMove,
  });

  final int index;
  final TripActivity activity;
  final Place? place;
  final int days;
  final int dayIndex;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Checkbox(value: activity.done, onChanged: (_) => onToggle()),
        title: Text(
          activity.title,
          style: TextStyle(
            decoration: activity.done ? TextDecoration.lineThrough : null,
            color: activity.done ? context.palette.muted : null,
          ),
        ),
        subtitle: place == null ? null : Text(place!.kind.label, style: TextStyle(color: place!.kind.color)),
        onTap: place == null ? null : () => context.push(Routes.place(place!.id)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (v) {
                if (v == 'delete') onDelete();
                if (v.startsWith('day')) onMove(int.parse(v.substring(3)));
              },
              itemBuilder: (_) => [
                for (var d = 0; d < days; d++)
                  if (d != dayIndex) PopupMenuItem(value: 'day$d', child: Text('Move to Day ${d + 1}')),
                const PopupMenuItem(value: 'delete', child: Text('Remove')),
              ],
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_indicator_rounded, semanticLabel: 'Drag to reorder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddActivitySheet extends StatefulWidget {
  const _AddActivitySheet({required this.catalog, required this.destinationId});
  final Catalog catalog;
  final String destinationId;

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final places = widget.catalog.placesAt(widget.destinationId)..sort((a, b) => a.kind.index.compareTo(b.kind.index));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, sc) => ListView(
        controller: sc,
        padding: EdgeInsets.fromLTRB(
          AppSpace.gutter,
          0,
          AppSpace.gutter,
          MediaQuery.viewInsetsOf(ctx).bottom + AppSpace.lg,
        ),
        children: [
          Text('Add activity', style: ctx.text.titleLarge),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _custom,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Custom: Shopping, Return journey…'),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              IconButton.filled(
                tooltip: 'Add custom activity',
                onPressed: () {
                  if (_custom.text.trim().isEmpty) return;
                  Navigator.pop(context, TripActivity(id: uuid.v4(), title: _custom.text.trim()));
                },
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text('Attractions & food spots here', style: ctx.text.titleSmall),
          for (final p in places)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: p.kind.color.withValues(alpha: 0.15),
                child: Icon(p.kind.icon, color: p.kind.color, size: 20),
              ),
              title: Text(p.name),
              subtitle: Text(p.visitDuration ?? p.kind.label),
              trailing: const Icon(Icons.add_circle_outline_rounded, color: AppColors.deepTeal),
              onTap: () => Navigator.pop(context, TripActivity(id: uuid.v4(), title: p.name, placeId: p.id)),
            ),
        ],
      ),
    );
  }
}
