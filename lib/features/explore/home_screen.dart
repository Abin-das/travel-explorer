import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/catalog.dart';
import '../../application/insights.dart';
import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';
import '../../domain/entities/geography.dart';
import '../../domain/entities/user_activity.dart';
import '../profile/profile_avatar.dart';
import '../travels/memory_widgets.dart';
import '../trips/trip_widgets.dart';

/// Home: a personal dashboard — progress, next trip, memories and bucket
/// list. Browsing the catalog lives behind search and the state chips.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(catalogDataProvider),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Hero()),
            SliverToBoxAdapter(
              child: AsyncView(
                value: catalog,
                onRetry: () => ref.invalidate(catalogDataProvider),
                loading: const _HomeSkeleton(),
                builder: (cat) => _HomeBody(catalog: cat),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxl)),
          ],
        ),
      ),
    );
  }
}

/// Gradient hero: profile, country, greeting, search and travel progress.
class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final country = ref.watch(catalogProvider).value?.country(ref.watch(selectedCountryIdProvider));
    final notices = ref.watch(noticesProvider).length;
    final top = MediaQuery.paddingOf(context).top;
    final name = profile.displayName.trim().isEmpty ? 'Explorer' : profile.displayName.trim();
    final onHero = Colors.white.withValues(alpha: 0.78);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepTeal, Color(0xFF0E6F78), AppColors.oceanBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(color: AppColors.deepTeal.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpace.gutter, top + AppSpace.md, AppSpace.md, AppSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go(Routes.profile),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const ProfileAvatar(radius: 21),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: InkWell(
                        borderRadius: AppRadius.smAll,
                        onTap: () => context.push(Routes.countries),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Exploring', style: context.text.bodySmall?.copyWith(color: onHero)),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${country?.name ?? '…'} ${country?.flag ?? ''}',
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.titleSmall?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                  const Icon(Icons.expand_more_rounded, size: 20, color: Colors.white),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Notifications',
                      color: Colors.white,
                      onPressed: () => context.push(Routes.notifications),
                      icon: Badge(
                        isLabelVisible: notices > 0,
                        backgroundColor: AppColors.warmOrange,
                        label: Text('$notices'),
                        child: const Icon(Icons.notifications_none_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xl),
                Text(
                  '${greetingFor(DateTime.now())}, $name!',
                  style: context.text.headlineLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text('Where would you like to go next?', style: context.text.bodyLarge?.copyWith(color: onHero)),
                const SizedBox(height: AppSpace.lg),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.sm),
                  child: Hero(
                    tag: 'search-bar',
                    child: Material(
                      type: MaterialType.transparency,
                      child: AppSearchField(onTap: () => context.push(Routes.search)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                const Padding(
                  padding: EdgeInsets.only(right: AppSpace.sm),
                  child: _ProgressPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Explorer level and headline stats, drawn as glass on the hero.
class _ProgressPanel extends ConsumerWidget {
  const _ProgressPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travelStatsProvider);
    final level = ref.watch(explorerLevelProvider);
    final empty = s.placesVisited == 0;
    final onCard = Colors.white.withValues(alpha: 0.78);
    final stats = [
      (Icons.explore_rounded, s.cities, 'Destinations'),
      (Icons.bookmark_rounded, s.bucketRemaining, 'Bucket list'),
      (Icons.photo_library_rounded, s.photos, 'Photos'),
    ];

    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(Routes.travels),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            children: [
              Row(
                children: [
                  _LevelRing(level: level),
                  const SizedBox(width: AppSpace.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warmOrange,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'LEVEL ${level.level}',
                            style: context.text.labelSmall?.copyWith(color: Colors.white, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          empty ? 'Start your journey' : level.title,
                          style: context.text.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          empty
                              ? 'Mark your first place as visited to begin.'
                              : level.nextTarget == null
                              ? 'Top level reached — keep exploring!'
                              : '${plural(level.remaining, 'more place')} to reach ${level.nextTitle}',
                          style: context.text.bodySmall?.copyWith(color: onCard),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: onCard),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  for (final (i, (icon, value, label)) in stats.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: _GlassStat(icon: icon, value: value, label: label),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.catalog});
  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryId = ref.watch(selectedCountryIdProvider);
    final regions = catalog.regionsOf(countryId);
    final memories = [...ref.watch(memoriesProvider)]..sort((a, b) => b.date.compareTo(a.date));
    final recent = ref
        .watch(settingsProvider)
        .recentDestinationIds
        .map(catalog.destination)
        .whereType<Destination>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpace.lg),
        const _QuickActions(),
        const _NextTrip(),
        if (memories.isNotEmpty) ...[
          SectionHeader(
            'Recent Memories',
            subtitle: '${plural(memories.length, 'moment')} saved',
            action: 'See all',
            onAction: () => context.go(Routes.travelsTab('journal')),
          ),
          HorizontalList(
            height: 230,
            itemCount: memories.length.clamp(0, 10),
            itemBuilder: (_, i) => SizedBox(width: 180, child: MemoryCard(memory: memories[i])),
          ),
        ],
        _BucketPreview(catalog: catalog),
        if (recent.isNotEmpty) ...[
          const SectionHeader('Continue Exploring', subtitle: 'Places you looked at recently'),
          HorizontalList(
            height: 150,
            itemCount: recent.length,
            itemBuilder: (_, i) => DestinationCard(destination: recent[i], width: 200, height: 150),
          ),
        ],
        if (regions.isNotEmpty) ...[
          SectionHeader(
            'Browse by ${catalog.country(countryId)?.regionLabel.toLowerCase() ?? 'state'}',
            action: 'See all',
            onAction: () => _openStates(context, catalog, countryId),
          ),
          SizedBox(
            height: scaledHeight(context, 46, textShare: 0.7),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppSpace.screen,
              itemCount: regions.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
              itemBuilder: (_, i) => AppChip(
                label: regions[i].name,
                icon: Icons.location_city_rounded,
                onTap: () => context.push(Routes.region(regions[i].id)),
              ),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xl, AppSpace.gutter, 0),
            child: SurfaceCard(
              onTap: () => context.push(Routes.countries),
              child: Row(
                children: [
                  Icon(Icons.public_rounded, color: context.colors.primary),
                  const SizedBox(width: AppSpace.md),
                  const Expanded(child: Text('No curated guide for this country yet. Change country?')),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _openStates(BuildContext context, Catalog catalog, String countryId) {
    final regions = catalog.regionsOf(countryId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Above the bottom navigation bar, so the last rows aren't hidden.
      useRootNavigator: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.xl),
          children: [
            Text(
              'Choose a ${catalog.country(countryId)?.regionLabel.toLowerCase() ?? 'state'}',
              style: ctx.text.titleLarge,
            ),
            const SizedBox(height: AppSpace.md),
            for (final r in regions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: ctx.colors.primaryContainer,
                  child: Text(r.name.characters.first, style: TextStyle(color: ctx.colors.primary)),
                ),
                title: Text(r.name),
                subtitle: Text(
                  '${plural(catalog.destinationsIn(regionId: r.id).length, 'destination')} · ${r.tagline}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(Routes.region(r.id));
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.event_note_rounded, 'Plan trip', AppColors.oceanBlue, Routes.newTrip),
      (Icons.add_photo_alternate_rounded, 'Add memory', AppColors.visited, '/memory/new'),
      (Icons.map_rounded, 'My map', AppColors.hiddenGem, Routes.map),
      (Icons.wb_sunny_rounded, 'Best time', AppColors.bucket, Routes.seasons),
    ];
    return Padding(
      padding: AppSpace.screen,
      // IntrinsicHeight + stretch keeps the tiles equal when a label wraps.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, (icon, label, color, route)) in items.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Material(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => route == Routes.map ? context.go(route) : context.push(route),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.md, horizontal: AppSpace.xs),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            child: Icon(icon, color: Colors.white, size: 20),
                          ),
                          const SizedBox(height: AppSpace.sm),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The soonest trip that hasn't ended, or a prompt to plan one.
class _NextTrip extends ConsumerWidget {
  const _NextTrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = ref.watch(tripsProvider).where((t) => !t.endDate.isBefore(today)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final trip = upcoming.firstOrNull;
    final daysAway = trip?.startDate.difference(today).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Your Next Trip',
          subtitle: trip == null
              ? null
              : daysAway! <= 0
              ? 'Happening now'
              : daysAway == 1
              ? 'Starts tomorrow'
              : 'Starts in $daysAway days',
          action: trip == null ? null : 'All trips',
          onAction: trip == null ? null : () => context.push(Routes.bucketTab('trips')),
        ),
        Padding(
          padding: AppSpace.screen,
          child: trip != null
              ? TripCard(trip: trip)
              : SurfaceCard(
                  onTap: () => context.push(Routes.newTrip),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: context.colors.primaryContainer,
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: Icon(Icons.flight_takeoff_rounded, color: context.colors.primary),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No trips planned', style: context.text.titleMedium),
                            Text('Plan day-by-day with places and food spots.', style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.add_rounded),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// A few bucket-list entries with thumbnails.
class _BucketPreview extends ConsumerWidget {
  const _BucketPreview({required this.catalog});
  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visited = {for (final v in ref.watch(visitsProvider)) v.subjectId};
    final items = [...ref.watch(bucketProvider).where((b) => !visited.contains(b.subjectId))]
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    if (items.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (final b in items) {
      if (rows.length == 3) break;
      final row = switch (b.subjectType) {
        SubjectType.place => switch (catalog.place(b.subjectId)) {
          final p? => _BucketRow(
            title: p.name,
            subtitle: catalog.placeLocation(p),
            cover: PlaceCover(place: p),
            onTap: () => context.push(Routes.place(p.id)),
          ),
          null => null,
        },
        SubjectType.destination => switch (catalog.destination(b.subjectId)) {
          final d? => _BucketRow(
            title: d.name,
            subtitle: catalog.destinationLocation(d),
            cover: DestinationCover(destination: d),
            onTap: () => context.push(Routes.destination(d.id)),
          ),
          null => null,
        },
      };
      if (row != null) rows.add(row);
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Bucket List',
          subtitle: '${plural(items.length, 'place')} waiting for you',
          action: 'See all',
          onAction: () => context.push(Routes.bucket),
        ),
        Padding(
          padding: AppSpace.screen,
          child: SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Column(
              children: [
                for (final (i, r) in rows.indexed) ...[if (i > 0) const Divider(height: 1, indent: 76), r],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BucketRow extends StatelessWidget {
  const _BucketRow({required this.title, required this.subtitle, required this.cover, required this.onTap});
  final String title;
  final String subtitle;
  final Widget cover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipRRect(borderRadius: AppRadius.smAll, child: cover),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.bookmark_rounded, color: AppColors.bucket),
    );
  }
}

/// Animated ring showing progress to the next explorer level.
class _LevelRing extends StatelessWidget {
  const _LevelRing({required this.level});
  final ExplorerLevel level;

  @override
  Widget build(BuildContext context) {
    final size = scaledHeight(context, 76, textShare: 0.4);
    return Semantics(
      label: '${level.placesVisited} places visited, ${(level.progress * 100).round()}% to next level',
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: level.progress),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: t,
                strokeWidth: 7,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                color: AppColors.warmOrange,
              ),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedCount(
                          value: level.placesVisited,
                          style: context.text.headlineMedium?.copyWith(color: Colors.white, height: 1),
                        ),
                        Text(
                          level.placesVisited == 1 ? 'place' : 'places',
                          style: context.text.labelSmall?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassStat extends StatelessWidget {
  const _GlassStat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.sm),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: AppRadius.mdAll),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              AnimatedCount(
                value: value,
                style: context.text.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.text.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(height: 84, radius: AppRadius.lg),
          SizedBox(height: AppSpace.xl),
          Skeleton(width: 180, height: 20),
          SizedBox(height: AppSpace.md),
          Skeleton(height: 112, radius: AppRadius.lg),
          SizedBox(height: AppSpace.xl),
          Skeleton(width: 180, height: 20),
          SizedBox(height: AppSpace.md),
          Skeleton(height: 180, radius: AppRadius.lg),
        ],
      ),
    );
  }
}
