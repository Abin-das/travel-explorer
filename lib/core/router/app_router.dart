import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../domain/entities/place.dart';
import '../../features/bucket/bucket_screen.dart';
import '../../features/explore/category_screen.dart';
import '../../features/explore/destination_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/explore/hidden_gems_screen.dart';
import '../../features/explore/home_screen.dart';
import '../../features/explore/place_detail_screen.dart';
import '../../features/explore/region_screen.dart';
import '../../features/explore/search_screen.dart';
import '../../features/explore/seasons_screen.dart';
import '../../features/food/food_explorer_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/onboarding/country_select_screen.dart';
import '../../features/places/add_place_screen.dart';
import '../../features/places/my_places_screen.dart';
import '../../features/profile/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/travels/achievements_screen.dart';
import '../../features/travels/analytics_screen.dart';
import '../../features/travels/memory_detail_screen.dart';
import '../../features/travels/memory_editor_screen.dart';
import '../../features/travels/my_travels_screen.dart';
import '../../features/travels/visited_in_destination_screen.dart';
import '../../features/trips/trip_detail_screen.dart';
import '../../features/trips/trip_form_screen.dart';
import 'app_shell.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Fade + slight upward slide used for every pushed page.
Page<void> _page(GoRouterState state, Widget child) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 320),
  reverseTransitionDuration: const Duration(milliseconds: 240),
  transitionsBuilder: (context, animation, secondary, child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  },
);

GoRoute _route(String path, Widget Function(GoRouterState s) build) =>
    GoRoute(path: path, parentNavigatorKey: _rootKey, pageBuilder: (context, state) => _page(state, build(state)));

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    redirect: (context, state) {
      final hasCountry = ref.read(settingsProvider).countryId != null;
      if (!hasCountry && state.matchedLocation != Routes.welcome) return Routes.welcome;
      return null;
    },
    routes: [
      _route(Routes.welcome, (_) => const CountrySelectScreen(onboarding: true)),
      _route(Routes.countries, (_) => const CountrySelectScreen(onboarding: false)),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.explore, builder: (_, _) => const ExploreScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.map, builder: (_, _) => const MapScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.travels,
                builder: (_, s) {
                  final tab = s.uri.queryParameters['tab'];
                  // Keyed by tab so a deep link re-opens on the requested tab.
                  return MyTravelsScreen(key: ValueKey(tab), initialTab: tab);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
      _route(Routes.bucket, (s) => BucketScreen(initialTab: s.uri.queryParameters['tab'])),
      _route(Routes.search, (_) => const SearchScreen()),
      _route('/region/:id', (s) => RegionScreen(regionId: s.pathParameters['id']!)),
      _route('/destination/:id', (s) => DestinationScreen(destinationId: s.pathParameters['id']!)),
      _route('/place/:id', (s) => PlaceDetailScreen(placeId: s.pathParameters['id']!)),
      _route(
        '/category/:name',
        (s) => CategoryScreen(
          category: PlaceCategory.values.firstWhere(
            (c) => c.name == s.pathParameters['name'],
            orElse: () => PlaceCategory.mountains,
          ),
        ),
      ),
      _route(Routes.gems, (s) => HiddenGemsScreen(destinationId: s.uri.queryParameters['destination'])),
      _route(Routes.food, (s) => FoodExplorerScreen(destinationId: s.uri.queryParameters['destination'])),
      _route(Routes.seasons, (_) => const SeasonsScreen()),
      _route(
        Routes.addPlace,
        (s) => AddPlaceScreen(
          editId: s.uri.queryParameters['edit'],
          initialKind: PlaceKind.values.where((k) => k.name == s.uri.queryParameters['kind']).firstOrNull,
          initialDestinationId: s.uri.queryParameters['destination'],
        ),
      ),
      _route(Routes.myPlaces, (_) => const MyPlacesScreen()),
      _route('/memory/new', (s) => MemoryEditorScreen(placeId: s.uri.queryParameters['place'])),
      _route('/memory/:id', (s) => MemoryDetailScreen(memoryId: s.pathParameters['id']!)),
      _route('/memory/:id/edit', (s) => MemoryEditorScreen(memoryId: s.pathParameters['id'])),
      _route('/visited/:id', (s) => VisitedInDestinationScreen(destinationId: s.pathParameters['id']!)),
      _route(Routes.newTrip, (s) => TripFormScreen(destinationId: s.uri.queryParameters['destination'])),
      _route('/trip/:id', (s) => TripDetailScreen(tripId: s.pathParameters['id']!)),
      _route('/trip/:id/edit', (s) => TripFormScreen(tripId: s.pathParameters['id'])),
      _route(Routes.analytics, (_) => const AnalyticsScreen()),
      _route(Routes.achievements, (_) => const AchievementsScreen()),
      _route(Routes.settings, (_) => const SettingsScreen()),
      _route(Routes.notifications, (_) => const NotificationsScreen()),
    ],
  );
});
