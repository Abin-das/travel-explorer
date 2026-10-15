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
import '../../core/widgets/scene_art.dart';
import '../../domain/entities/geography.dart';
import '../../domain/entities/place.dart';
import '../profile/profile_avatar.dart';

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
            const SliverToBoxAdapter(child: _Header()),
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

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final country = ref.watch(catalogProvider).value?.country(ref.watch(selectedCountryIdProvider));
    final notices = ref.watch(noticesProvider).length;
    final top = MediaQuery.paddingOf(context).top;
    final name = profile.displayName.trim().isEmpty ? 'Explorer' : profile.displayName.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpace.gutter, top + AppSpace.md, AppSpace.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(onTap: () => context.go(Routes.profile), child: const ProfileAvatar(radius: 22)),
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
                        Text('Exploring', style: context.text.bodySmall),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${country?.name ?? '…'} ${country?.flag ?? ''}',
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleSmall,
                              ),
                            ),
                            Icon(Icons.expand_more_rounded, size: 20, color: context.colors.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.push(Routes.notifications),
                icon: Badge(
                  isLabelVisible: notices > 0,
                  label: Text('$notices'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          Text('${greetingFor(DateTime.now())}, $name!', style: context.text.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Where would you like to explore today?',
            style: context.text.bodyLarge?.copyWith(color: context.palette.muted),
          ),
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
        ],
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
    final destinations = ref.watch(countryDestinationsProvider);
    final regions = catalog.regionsOf(countryId);
    final gems = ref.watch(featuredGemsProvider);
    final recent = ref
        .watch(settingsProvider)
        .recentDestinationIds
        .map(catalog.destination)
        .whereType<Destination>()
        .toList();
    final trending =
        catalog.placesIn(countryId: countryId, kind: PlaceKind.attraction).where((p) => p.popularity >= 85).toList()
          ..sort((a, b) => b.popularity.compareTo(a.popularity));
    final food = catalog.placesIn(countryId: countryId, kind: PlaceKind.foodSpot)
      ..sort((a, b) => b.popularity.compareTo(a.popularity));

    if (destinations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpace.xl),
        child: Column(
          children: [
            EmptyState(
              icon: Icons.travel_explore_rounded,
              title: 'No curated guide for this country yet',
              message:
                  'You can still add places you know, track visits and plan trips. '
                  'Curated content for more countries can be added via the backend later.',
              actionLabel: 'Add a place',
              onAction: () => context.push(Routes.addPlace),
            ),
            TextButton(onPressed: () => context.push(Routes.countries), child: const Text('Change country')),
            const _ProgressCard(),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpace.lg),
        const _ProgressCard(),
        const SizedBox(height: AppSpace.sm),
        _QuickLinks(),
        SectionHeader(
          'Popular Destinations',
          subtitle: 'Hand-picked places to start with',
          action: 'See states',
          onAction: () => _openStates(context, catalog, countryId),
        ),
        HorizontalList(
          height: 320,
          itemCount: destinations.length.clamp(0, 10),
          itemBuilder: (_, i) => DestinationCard(destination: destinations[i], hero: true),
        ),
        const SectionHeader('Explore by Category'),
        SizedBox(
          height: scaledHeight(context, 104, textShare: 0.7),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: AppSpace.screen,
            children: [
              _CategoryBubble(
                label: 'Hidden Gems',
                icon: Icons.diamond_rounded,
                color: AppColors.hiddenGem,
                onTap: () => context.push(Routes.gems),
              ),
              for (final c in exploreCategories)
                _CategoryBubble(
                  label: c.label,
                  icon: c.icon,
                  scene: sceneForCategory(c),
                  onTap: () => context.push(Routes.category(c.name)),
                ),
            ],
          ),
        ),
        SectionHeader('${catalog.country(countryId)?.regionLabel ?? 'State'}s to explore'),
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
        if (trending.isNotEmpty) ...[
          const SectionHeader('Trending Places', subtitle: 'Most-loved attractions in the guide'),
          HorizontalList(
            height: 262,
            itemCount: trending.length.clamp(0, 10),
            itemBuilder: (_, i) => PlaceCard(place: trending[i]),
          ),
        ],
        if (gems.isNotEmpty) ...[
          SectionHeader(
            'Hidden Gems',
            subtitle: recent.isEmpty
                ? 'Lesser-known spots worth the detour'
                : 'Starting near places you explored recently',
            action: 'See all',
            onAction: () => context.push(Routes.gems),
          ),
          HorizontalList(
            height: 262,
            itemCount: gems.length.clamp(0, 10),
            itemBuilder: (_, i) => PlaceCard(place: gems[i]),
          ),
        ],
        if (recent.isNotEmpty) ...[
          const SectionHeader('Continue Exploring'),
          HorizontalList(
            height: 180,
            itemCount: recent.length,
            itemBuilder: (_, i) => DestinationCard(destination: recent[i], width: 200, height: 180),
          ),
        ],
        if (food.isNotEmpty) ...[
          SectionHeader(
            'Food Explorer',
            subtitle: 'Local flavours to seek out',
            action: 'See all',
            onAction: () => context.push(Routes.food),
          ),
          HorizontalList(
            height: 290,
            itemCount: food.length.clamp(0, 8),
            itemBuilder: (_, i) => FoodSpotCard(place: food[i], width: 230),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xl, AppSpace.gutter, 0),
          child: _AddPlaceBanner(),
        ),
      ],
    );
  }

  void _openStates(BuildContext context, Catalog catalog, String countryId) {
    final regions = catalog.regionsOf(countryId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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

class _QuickLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.diamond_rounded, 'Hidden\nGems', AppColors.hiddenGem, Routes.gems),
      (Icons.restaurant_rounded, 'Food\nExplorer', AppColors.foodSpot, Routes.food),
      (Icons.wb_sunny_rounded, 'Best Time\nto Visit', AppColors.bucket, Routes.seasons),
      (Icons.add_location_alt_rounded, 'Add a\nPlace', AppColors.oceanBlue, Routes.addPlace),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, 0),
      child: Row(
        children: [
          for (final (icon, label, color, route) in items)
            Expanded(
              child: InkWell(
                borderRadius: AppRadius.mdAll,
                onTap: () => context.push(route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: AppRadius.mdAll),
                        child: Icon(icon, color: color),
                      ),
                      const SizedBox(height: 6),
                      Text(label, textAlign: TextAlign.center, style: context.text.labelSmall),
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

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({required this.label, required this.icon, required this.onTap, this.scene, this.color});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final SceneTheme? scene;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpace.md),
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: ClipRRect(
                  borderRadius: AppRadius.lgAll,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (scene != null) SceneArt(theme: scene!, seed: label) else ColoredBox(color: color!),
                      ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
                      Icon(icon, color: Colors.white, size: 28),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(travelStatsProvider);
    final level = ref.watch(explorerLevelProvider);
    final empty = s.placesVisited == 0;
    final stats = [
      (Icons.check_circle_rounded, s.placesVisited, 'Places visited'),
      (Icons.explore_rounded, s.cities, 'Destinations'),
      (Icons.bookmark_rounded, s.bucketRemaining, 'Bucket list'),
      (Icons.photo_library_rounded, s.photos, 'Photos'),
    ];
    final onCard = Colors.white.withValues(alpha: 0.78);

    return Padding(
      padding: AppSpace.screen,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.xlAll,
          gradient: const LinearGradient(
            colors: [AppColors.deepTeal, Color(0xFF0E6F78), AppColors.oceanBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: AppColors.deepTeal.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => context.go(Routes.travels),
            child: Stack(
              children: [
                // Decorative ridge line along the bottom edge.
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 90,
                  child: Opacity(opacity: 0.16, child: _RidgeDecoration()),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'My Travel Progress',
                              style: context.text.titleMedium?.copyWith(color: Colors.white),
                            ),
                          ),
                          Text('View all', style: context.text.labelMedium?.copyWith(color: onCard)),
                          Icon(Icons.chevron_right_rounded, color: onCard, size: 20),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
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
                                  style: context.text.headlineSmall?.copyWith(color: Colors.white),
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
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      ResponsiveGrid(
                        minTileWidth: 72,
                        spacing: AppSpace.sm,
                        children: [
                          for (final (icon, value, label) in stats) _GlassStat(icon: icon, value: value, label: label),
                        ],
                      ),
                      if (empty) ...[
                        const SizedBox(height: AppSpace.md),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.deepTeal,
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () => context.push(Routes.search),
                          icon: const Icon(Icons.travel_explore_rounded),
                          label: const Text('Find a place'),
                        ),
                      ],
                    ],
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

/// Animated ring showing progress to the next explorer level.
class _LevelRing extends StatelessWidget {
  const _LevelRing({required this.level});
  final ExplorerLevel level;

  @override
  Widget build(BuildContext context) {
    final size = scaledHeight(context, 84, textShare: 0.4);
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          AnimatedCount(
            value: value,
            style: context.text.titleLarge?.copyWith(color: Colors.white),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.text.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

class _RidgeDecoration extends StatelessWidget {
  const _RidgeDecoration();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _RidgePainter());
}

class _RidgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()..color = Colors.white;
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(0, h * 0.7)
        ..lineTo(w * 0.18, h * 0.25)
        ..lineTo(w * 0.32, h * 0.6)
        ..lineTo(w * 0.5, h * 0.05)
        ..lineTo(w * 0.68, h * 0.55)
        ..lineTo(w * 0.82, h * 0.3)
        ..lineTo(w, h * 0.65)
        ..lineTo(w, h)
        ..close(),
      p,
    );
  }

  @override
  bool shouldRepaint(_RidgePainter oldDelegate) => false;
}

class _AddPlaceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: () => context.push(Routes.addPlace),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: context.colors.tertiaryContainer, borderRadius: AppRadius.mdAll),
            child: Icon(Icons.add_location_alt_rounded, color: context.colors.tertiary),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Know a place we missed?', style: context.text.titleMedium),
                Text(
                  'Add a hidden gem, attraction or food spot. It stays private on this device.',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 120, radius: AppRadius.lg),
          const SizedBox(height: AppSpace.xl),
          const Skeleton(width: 180, height: 20),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            height: 300,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                Skeleton(width: 240, height: 300, radius: AppRadius.lg),
                SizedBox(width: AppSpace.md),
                Skeleton(width: 240, height: 300, radius: AppRadius.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
