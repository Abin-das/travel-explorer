import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/insights.dart';
import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';
import 'achievements_screen.dart' show AchievementBadge;
import 'memory_widgets.dart';

class MyTravelsScreen extends ConsumerWidget {
  const MyTravelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Travels', style: context.text.headlineMedium),
          actions: [
            IconButton(
              tooltip: 'Analytics',
              icon: const Icon(Icons.insights_rounded),
              onPressed: () => context.push(Routes.analytics),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'History'),
              Tab(text: 'Timeline'),
              Tab(text: 'Journal'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'new-memory',
          onPressed: () => context.push('/memory/new'),
          icon: const Icon(Icons.add_a_photo_rounded),
          label: const Text('New memory'),
        ),
        body: const TabBarView(children: [_Overview(), _History(), _Timeline(), _Journal()]),
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travelStatsProvider);
    final ach = ref.watch(achievementsProvider);
    final unlocked = ach.where((a) => a.unlocked).length;
    final stats = [
      (Icons.public_rounded, s.countries, 'Countries explored', AppColors.oceanBlue),
      (Icons.location_city_rounded, s.regions, 'States explored', AppColors.deepTeal),
      (Icons.apartment_rounded, s.cities, 'Cities explored', AppColors.tealLight),
      (Icons.place_rounded, s.attractions, 'Attractions visited', AppColors.attraction),
      (Icons.diamond_rounded, s.hiddenGems, 'Hidden gems discovered', AppColors.hiddenGem),
      (Icons.restaurant_rounded, s.foodSpots, 'Food spots visited', AppColors.foodSpot),
      (Icons.photo_library_rounded, s.photos, 'Photos uploaded', AppColors.warmOrange),
      (Icons.bookmark_rounded, s.bucketRemaining, 'Left on bucket list', AppColors.bucket),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 100),
      children: [
        ResponsiveGrid(
          minTileWidth: 140,
          children: [
            for (final (i, (icon, v, label, color)) in stats.indexed)
              FadeSlideIn(
                index: i,
                child: StatTile(icon: icon, value: v, label: label, color: color),
              ),
          ],
        ),
        SectionHeader(
          'Achievements',
          subtitle: '$unlocked of ${ach.length} unlocked',
          action: 'See all',
          onAction: () => context.push(Routes.achievements),
          padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.md),
        ),
        SizedBox(
          height: scaledHeight(context, 120, textShare: 0.7),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ach.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
            itemBuilder: (_, i) => SizedBox(width: 96, child: AchievementBadge(achievement: ach[i], compact: true)),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        SurfaceCard(
          onTap: () => context.push(Routes.analytics),
          child: Row(
            children: [
              Icon(Icons.insights_rounded, color: context.colors.primary, size: 32),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Travel analytics', style: context.text.titleMedium),
                    Text('Places by state, by category and month by month', style: context.text.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        SurfaceCard(
          onTap: () => context.push(Routes.myPlaces),
          child: Row(
            children: [
              Icon(Icons.add_location_alt_rounded, color: context.colors.tertiary, size: 32),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Places I added', style: context.text.titleMedium),
                    Text(plural(ref.watch(customPlacesProvider).length, 'place'), style: context.text.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ],
    );
  }
}

class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(travelHistoryProvider);
    if (history.isEmpty) return const _NoTravels();
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 100),
      children: [
        for (final c in history) ...[
          Row(
            children: [
              Text(c.country?.flag ?? '🌍', style: const TextStyle(fontSize: 26)),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text(c.country?.name ?? 'Other', style: context.text.headlineSmall)),
              Pill(label: plural(c.count, 'place')),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          for (final r in c.regions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: SurfaceCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(r.name, style: context.text.titleMedium),
                    subtitle: Text('${plural(r.cities.length, 'destination')} · ${plural(r.count, 'place')} visited'),
                    children: [
                      for (final city in r.cities)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.visited.withValues(alpha: 0.15),
                            child: Text('${city.places.length}', style: const TextStyle(color: AppColors.visited)),
                          ),
                          title: Text(city.name),
                          subtitle: Text('${plural(city.places.length, 'Place')} Visited'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => city.destinationId != null
                              ? context.push(Routes.visitedIn(city.destinationId!))
                              : _showPlaces(context, city),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpace.md),
        ],
      ],
    );
  }

  void _showPlaces(BuildContext context, CityHistory city) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.sm),
            child: Text(city.name, style: ctx.text.titleLarge),
          ),
          for (final v in city.places)
            ListTile(
              leading: const Icon(Icons.check_circle_rounded, color: AppColors.visited),
              title: Text(v.place.name),
              subtitle: Text(formatDate(v.visit.visitedOn)),
              onTap: () {
                Navigator.pop(ctx);
                context.push(Routes.place(v.place.id));
              },
            ),
        ],
      ),
    );
  }
}

class _Timeline extends ConsumerWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(timelineProvider);
    final catalog = ref.watch(catalogProvider).value;
    if (groups.isEmpty) return const _NoTravels();
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 100),
      children: [
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: Text(formatMonthYear(g.key), style: context.text.headlineSmall),
          ),
          for (final (i, v) in g.value.indexed)
            _TimelineEntry(visited: v, location: catalog?.placeLocation(v.place) ?? '', last: i == g.value.length - 1),
          const SizedBox(height: AppSpace.lg),
        ],
      ],
    );
  }
}

class _TimelineEntry extends ConsumerWidget {
  const _TimelineEntry({required this.visited, required this.location, required this.last});
  final VisitedPlace visited;
  final String location;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = [for (final m in ref.watch(memoriesForPlaceProvider(visited.place.id))) ...m.photos];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(color: AppColors.visited, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                ),
                if (!last) Expanded(child: Container(width: 2, color: context.palette.line)),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.lg),
              child: InkWell(
                borderRadius: AppRadius.smAll,
                onTap: () => context.push(Routes.place(visited.place.id)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${visited.place.name} — ${location.split(',').first}', style: context.text.titleMedium),
                    Text(formatDayMonth(visited.visit.visitedOn), style: context.text.bodySmall),
                    if (photos.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.sm),
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length.clamp(0, 6),
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => PhotoViewer.open(context, photos, i),
                            child: ClipRRect(
                              borderRadius: AppRadius.smAll,
                              child: SizedBox(width: 64, child: LocalPhoto(path: photos[i].path, cacheWidth: 200)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Journal extends ConsumerWidget {
  const _Journal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = [...ref.watch(memoriesProvider)]..sort((a, b) => b.date.compareTo(a.date));
    if (memories.isEmpty) {
      return EmptyState(
        icon: Icons.auto_stories_rounded,
        title: 'Your travel journal is empty',
        message: 'Create a memory with photos and notes from any place you\'ve visited.',
        actionLabel: 'Create a memory',
        onAction: () => context.push('/memory/new'),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 250,
        mainAxisSpacing: AppSpace.md,
        crossAxisSpacing: AppSpace.md,
      ),
      itemCount: memories.length,
      itemBuilder: (_, i) => FadeSlideIn(
        index: i,
        child: MemoryCard(memory: memories[i]),
      ),
    );
  }
}

class _NoTravels extends StatelessWidget {
  const _NoTravels();

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.luggage_rounded,
    title: 'No visits yet',
    message: 'Open any attraction and tap "Mark as Visited" to start your travel history.',
    actionLabel: 'Explore places',
    onAction: () => context.go(Routes.explore),
  );
}
