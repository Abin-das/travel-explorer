import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/catalog.dart';
import '../../application/insights.dart';
import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common.dart';
import '../../domain/entities/geography.dart';
import '../../domain/entities/user_activity.dart';
import '../travels/achievements_screen.dart' show AchievementBadge;
import '../travels/memory_widgets.dart';
import 'profile_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final settings = ref.watch(settingsProvider);
    final s = ref.watch(travelStatsProvider);
    final ach = ref.watch(achievementsProvider).where((a) => a.unlocked).toList();
    final memories = [...ref.watch(memoriesProvider)]..sort((a, b) => b.date.compareTo(a.date));
    final cat = ref.watch(catalogProvider).value;
    final favourites = _favourites(ref, cat);
    final country = cat?.country(settings.countryId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: context.text.headlineMedium),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.xxxl),
        children: [
          Padding(
            padding: AppSpace.screen,
            child: Column(
              children: [
                const SizedBox(height: AppSpace.md),
                GestureDetector(onTap: () => _editProfile(context, ref), child: const ProfileAvatar(radius: 48)),
                const SizedBox(height: AppSpace.md),
                Text(profile.displayName, style: context.text.headlineMedium),
                if (profile.bio.isNotEmpty)
                  Text(profile.bio, textAlign: TextAlign.center, style: context.text.bodyMedium),
                Text('Exploring ${country?.name ?? ''} ${country?.flag ?? ''}', style: context.text.bodySmall),
                const SizedBox(height: AppSpace.md),
                OutlinedButton.icon(
                  onPressed: () => _editProfile(context, ref),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit profile'),
                ),
              ],
            ),
          ),
          if (settings.showStatsOnProfile) ...[
            const SectionHeader('Travel statistics'),
            Padding(
              padding: AppSpace.screen,
              child: Row(
                children: [
                  for (final (v, l) in [
                    (s.placesVisited, 'Places'),
                    (s.cities, 'Cities'),
                    (s.regions, 'States'),
                    (s.photos, 'Photos'),
                  ])
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedCount(value: v, style: context.text.headlineMedium),
                          Text(l, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          SectionHeader(
            'Achievements',
            subtitle: ach.isEmpty ? 'Visit places to unlock badges' : null,
            action: 'See all',
            onAction: () => context.push(Routes.achievements),
          ),
          if (ach.isNotEmpty)
            SizedBox(
              height: scaledHeight(context, 112, textShare: 0.7),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: AppSpace.screen,
                itemCount: ach.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
                itemBuilder: (_, i) => SizedBox(width: 90, child: AchievementBadge(achievement: ach[i], compact: true)),
              ),
            ),
          if (memories.isNotEmpty) ...[
            SectionHeader('Travel memories', action: 'Journal', onAction: () => context.go(Routes.travels)),
            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: AppSpace.screen,
                itemCount: memories.length.clamp(0, 8),
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
                itemBuilder: (_, i) => SizedBox(width: 180, child: MemoryCard(memory: memories[i])),
              ),
            ),
          ],
          if (favourites.isNotEmpty) ...[
            const SectionHeader('Favourite destinations', subtitle: 'Where you\'ve visited the most'),
            HorizontalList(
              height: 180,
              itemCount: favourites.length,
              itemBuilder: (_, i) => DestinationCard(destination: favourites[i], width: 200, height: 180),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          Padding(
            padding: AppSpace.screen,
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.public_rounded),
                    title: const Text('Change default country'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.countries),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_location_alt_rounded),
                    title: const Text('Places I added'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.myPlaces),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_rounded),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.settings),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Destinations ranked by visited places, falling back to saved ones.
  List<Destination> _favourites(WidgetRef ref, Catalog? cat) {
    if (cat == null) return const [];
    final counts = <String, int>{};
    for (final v in ref.watch(visitedPlacesProvider)) {
      final id = v.place.destinationId;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    for (final b in ref.watch(bucketProvider).where((b) => b.subjectType == SubjectType.destination)) {
      counts.putIfAbsent(b.subjectId, () => 0);
    }
    final ids = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return ids.map(cat.destination).nonNulls.take(8).toList();
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _EditProfileSheet(),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final _name = TextEditingController(text: ref.read(profileProvider).displayName);
  late final _bio = TextEditingController(text: ref.read(profileProvider).bio);

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        MediaQuery.viewInsetsOf(context).bottom + AppSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Edit profile', style: context.text.titleLarge),
          const SizedBox(height: AppSpace.lg),
          const ProfileAvatar(radius: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.photo_rounded),
                label: const Text('Change photo'),
                onPressed: () async {
                  try {
                    final path = await ref.read(photoStorageProvider).pickSingleRelative();
                    if (path != null) await ref.read(profileProvider.notifier).save(p.copyWith(avatarPath: path));
                  } catch (_) {
                    if (context.mounted) showSnack(context, 'Could not open the photo library');
                  }
                },
              ),
              if (p.avatarPath != null)
                TextButton(
                  onPressed: () => ref.read(profileProvider.notifier).save(p.copyWith(clearAvatar: true)),
                  child: const Text('Remove'),
                ),
            ],
          ),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _bio,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Short bio', hintText: 'Mountains over beaches, always.'),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final name = _name.text.trim().isEmpty ? 'Explorer' : _name.text.trim();
                await ref
                    .read(profileProvider.notifier)
                    .save(ref.read(profileProvider).copyWith(displayName: name, bio: _bio.text.trim()));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
