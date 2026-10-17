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
  const MyTravelsScreen({super.key, this.initialTab});

  /// One of [tabs]; opens on Overview when null or unknown.
  final String? initialTab;

  static const tabs = ['overview', 'history', 'timeline', 'journal'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      initialIndex: tabs.indexOf(initialTab ?? '').clamp(0, tabs.length - 1),
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'new-memory',
          onPressed: () => context.push('/memory/new'),
          icon: const Icon(Icons.add_a_photo_rounded),
          label: const Text('New memory'),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerScrolled) => [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: _Header(forceElevated: innerScrolled),
            ),
          ],
          body: const TabBarView(children: [_Overview(), _History(), _Timeline(), _Journal()]),
        ),
      ),
    );
  }
}

/// Collapsing gradient header with headline stats and pill-style tabs.
class _Header extends ConsumerWidget {
  const _Header({required this.forceElevated});
  final bool forceElevated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travelStatsProvider);
    final tabHeight = scaledHeight(context, 36, textShare: 1);
    final barHeight = tabHeight + AppSpace.md;
    final statsHeight = scaledHeight(context, 96, textShare: 0.9);
    final stats = [
      (s.placesVisited, 'Places'),
      (s.cities, 'Destinations'),
      (s.countries, 'Countries'),
      (s.photos, 'Photos'),
    ];

    return SliverAppBar(
      pinned: true,
      forceElevated: forceElevated,
      expandedHeight: kToolbarHeight + statsHeight + barHeight,
      backgroundColor: AppColors.deepTeal,
      foregroundColor: Colors.white,
      title: Text('My Travels', style: context.text.headlineSmall?.copyWith(color: Colors.white)),
      actions: [
        IconButton(
          tooltip: 'Analytics',
          icon: const Icon(Icons.insights_rounded),
          onPressed: () => context.push(Routes.analytics),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.deepTeal, Color(0xFF0E6F78), AppColors.oceanBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpace.gutter, kToolbarHeight, AppSpace.gutter, barHeight),
              child: Row(
                children: [
                  for (final (i, (value, label)) in stats.indexed) ...[
                    if (i > 0) Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2)),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AnimatedCount(
                              value: value,
                              style: context.text.headlineMedium?.copyWith(color: Colors.white),
                            ),
                          ),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(barHeight),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.md),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
            splashBorderRadius: BorderRadius.circular(100),
            labelColor: AppColors.deepTeal,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
            labelStyle: context.text.labelLarge,
            labelPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            tabs: [
              for (final t in const ['Overview', 'History', 'Timeline', 'Journal']) Tab(height: tabHeight, text: t),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tab's scroll view, offset below the pinned header.
class _TabBody extends StatelessWidget {
  const _TabBody({required this.name, required this.slivers});
  final String name;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: PageStorageKey(name),
      slivers: [
        SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
        ...slivers,
      ],
    );
  }
}

const _tabPadding = EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 100);

class _Overview extends ConsumerWidget {
  const _Overview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travelStatsProvider);
    final ach = ref.watch(achievementsProvider);
    final unlocked = ach.where((a) => a.unlocked).length;
    final stats = [
      (Icons.location_city_rounded, s.regions, 'States explored', AppColors.deepTeal),
      (Icons.place_rounded, s.attractions, 'Attractions visited', AppColors.attraction),
      (Icons.diamond_rounded, s.hiddenGems, 'Hidden gems found', AppColors.hiddenGem),
      (Icons.restaurant_rounded, s.foodSpots, 'Food spots visited', AppColors.foodSpot),
      (Icons.bookmark_rounded, s.bucketRemaining, 'Left on bucket list', AppColors.bucket),
      (Icons.auto_stories_rounded, ref.watch(memoriesProvider).length, 'Memories saved', AppColors.visited),
    ];
    return _TabBody(
      name: 'overview',
      slivers: [
        SliverPadding(
          padding: _tabPadding,
          sliver: SliverList.list(
            children: [
              const _PhotoWall(),
              SectionHeader(
                'Your Numbers',
                padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.md),
              ),
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
                padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.sm),
              ),
              AnimatedProgressBar(value: ach.isEmpty ? 0 : unlocked / ach.length, height: 6),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                height: scaledHeight(context, 120, textShare: 0.7),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ach.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
                  itemBuilder: (_, i) =>
                      SizedBox(width: 96, child: AchievementBadge(achievement: ach[i], compact: true)),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              _LinkCard(
                icon: Icons.insights_rounded,
                color: context.colors.primary,
                title: 'Travel analytics',
                subtitle: 'Places by state, by category and month by month',
                onTap: () => context.push(Routes.analytics),
              ),
              const SizedBox(height: AppSpace.md),
              _LinkCard(
                icon: Icons.add_location_alt_rounded,
                color: context.colors.tertiary,
                title: 'Places I added',
                subtitle: plural(ref.watch(customPlacesProvider).length, 'place'),
                onTap: () => context.push(Routes.myPlaces),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mosaic of the most recent memory photos; opens the full gallery.
class _PhotoWall extends ConsumerWidget {
  const _PhotoWall();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allPhotosProvider);
    if (all.isEmpty) {
      return _LinkCard(
        icon: Icons.add_a_photo_rounded,
        color: AppColors.visited,
        title: 'Start your photo wall',
        subtitle: 'Add a memory with photos from a place you visited.',
        onTap: () => context.push('/memory/new'),
      );
    }
    final photos = [for (final (p, _) in all) p];
    final extra = all.length - 3;

    Widget tile(int i, {bool caption = false, bool more = false}) => GestureDetector(
      onTap: () => PhotoViewer.open(context, photos, i),
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: Stack(
          fit: StackFit.expand,
          children: [
            LocalPhoto(path: photos[i].path, cacheWidth: caption ? 700 : 400),
            if (caption) ...[
              const BottomScrim(),
              Positioned(
                left: AppSpace.md,
                right: AppSpace.md,
                bottom: AppSpace.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      all[i].$2.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(color: Colors.white),
                    ),
                    Text(
                      formatShortDate(all[i].$2.date),
                      style: context.text.labelSmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
            if (more)
              ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Text('+$extra', style: context.text.headlineSmall?.copyWith(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Photo Wall',
          subtitle: plural(all.length, 'photo'),
          padding: const EdgeInsets.only(bottom: AppSpace.md),
        ),
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: tile(0, caption: true)),
              if (photos.length > 1) ...[
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tile(1)),
                      if (photos.length > 2) ...[
                        const SizedBox(height: AppSpace.sm),
                        Expanded(child: tile(2, more: extra > 0)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: AppRadius.mdAll),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                Text(subtitle, style: context.text.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(travelHistoryProvider);
    if (history.isEmpty) return const _TabBody(name: 'history', slivers: [_NoTravels()]);
    return _TabBody(
      name: 'history',
      slivers: [
        SliverPadding(
          padding: _tabPadding,
          sliver: SliverList.list(
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
                          // Own storage key, so it doesn't read the tab's scroll offset.
                          key: PageStorageKey('history-${c.country?.id}-${r.name}'),
                          initiallyExpanded: true,
                          title: Text(r.name, style: context.text.titleMedium),
                          subtitle: Text(
                            '${plural(r.cities.length, 'destination')} · ${plural(r.count, 'place')} visited',
                          ),
                          children: [
                            for (final city in r.cities)
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.visited.withValues(alpha: 0.15),
                                  child: Text(
                                    '${city.places.length}',
                                    style: const TextStyle(color: AppColors.visited),
                                  ),
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
          ),
        ),
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
    if (groups.isEmpty) return const _TabBody(name: 'timeline', slivers: [_NoTravels()]);
    return _TabBody(
      name: 'timeline',
      slivers: [
        SliverPadding(
          padding: _tabPadding,
          sliver: SliverList.list(
            children: [
              for (final g in groups) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.md),
                  child: Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(formatMonthYear(g.key), style: context.text.titleLarge),
                      Pill(label: plural(g.value.length, 'place'), color: AppColors.visited),
                    ],
                  ),
                ),
                for (final (i, v) in g.value.indexed)
                  _TimelineEntry(
                    visited: v,
                    location: catalog?.placeLocation(v.place) ?? '',
                    last: i == g.value.length - 1,
                  ),
                const SizedBox(height: AppSpace.md),
              ],
            ],
          ),
        ),
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
    final rating = visited.visit.rating;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: AppSpace.lg),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.visited,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.palette.card, width: 3),
                  ),
                  child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                ),
                if (!last) Expanded(child: Container(width: 2, color: context.palette.line)),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: SurfaceCard(
                onTap: () => context.push(Routes.place(visited.place.id)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(visited.place.name, style: context.text.titleMedium),
                              Text(
                                '${location.split(',').first} · ${formatDayMonth(visited.visit.visitedOn)}',
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (rating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 18, color: AppColors.bucket),
                              Text('$rating', style: context.text.labelLarge),
                            ],
                          ),
                      ],
                    ),
                    if (photos.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.md),
                      SizedBox(
                        height: 84,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length.clamp(0, 6),
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => PhotoViewer.open(context, photos, i),
                            child: ClipRRect(
                              borderRadius: AppRadius.smAll,
                              child: SizedBox(
                                width: i == 0 ? 120 : 84,
                                child: LocalPhoto(path: photos[i].path, cacheWidth: 300),
                              ),
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
      return _TabBody(
        name: 'journal',
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.auto_stories_rounded,
              title: 'Your travel journal is empty',
              message: 'Create a memory with photos and notes from any place you\'ve visited.',
              actionLabel: 'Create a memory',
              onAction: () => context.push('/memory/new'),
            ),
          ),
        ],
      );
    }
    return _TabBody(
      name: 'journal',
      slivers: [
        SliverPadding(
          padding: _tabPadding,
          sliver: SliverGrid.builder(
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
          ),
        ),
      ],
    );
  }
}

class _NoTravels extends StatelessWidget {
  const _NoTravels();

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    hasScrollBody: false,
    child: EmptyState(
      icon: Icons.luggage_rounded,
      title: 'No visits yet',
      message: 'Open any attraction and tap "Mark as Visited" to start your travel history.',
      actionLabel: 'Explore places',
      onAction: () => context.go(Routes.explore),
    ),
  );
}
