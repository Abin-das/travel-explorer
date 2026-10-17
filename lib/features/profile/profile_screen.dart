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
    final level = ref.watch(explorerLevelProvider);
    final allAch = ref.watch(achievementsProvider);
    final ach = allAch.where((a) => a.unlocked).toList();
    final memories = [...ref.watch(memoriesProvider)]..sort((a, b) => b.date.compareTo(a.date));
    final cat = ref.watch(catalogProvider).value;
    final favourites = _favourites(ref, cat);
    final country = cat?.country(settings.countryId);
    final top = MediaQuery.paddingOf(context).top;
    const avatarRadius = 52.0;
    final bannerHeight = top + 130;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.xxxl),
        children: [
          // Cover banner with the avatar overlapping its bottom edge.
          SizedBox(
            height: bannerHeight + avatarRadius,
            child: Stack(
              children: [
                Container(
                  height: bannerHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.deepTeal, Color(0xFF0E6F78), AppColors.oceanBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
                  ),
                ),
                Positioned(
                  top: top + AppSpace.xs,
                  left: AppSpace.gutter,
                  right: AppSpace.sm,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Profile', style: context.text.headlineSmall?.copyWith(color: Colors.white)),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        color: Colors.white,
                        icon: const Icon(Icons.settings_rounded),
                        onPressed: () => context.push(Routes.settings),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _editProfile(context, ref),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: context.colors.surface,
                              shape: BoxShape.circle,
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
                            ),
                            child: const ProfileAvatar(radius: avatarRadius),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.warmOrange,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.colors.surface, width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: AppSpace.screen,
            child: Column(
              children: [
                const SizedBox(height: AppSpace.md),
                Text(profile.displayName, textAlign: TextAlign.center, style: context.text.headlineMedium),
                if (profile.bio.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.bio,
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(color: context.palette.muted),
                  ),
                ],
                const SizedBox(height: AppSpace.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  children: [
                    Pill(
                      label: 'Level ${level.level} · ${s.placesVisited == 0 ? 'New explorer' : level.title}',
                      icon: Icons.military_tech_rounded,
                      color: AppColors.warmOrange,
                    ),
                    if (country != null) Pill(label: '${country.flag} ${country.name}', color: AppColors.deepTeal),
                  ],
                ),
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
            const SizedBox(height: AppSpace.lg),
            Padding(
              padding: AppSpace.screen,
              child: SurfaceCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.lg, horizontal: AppSpace.sm),
                onTap: () => context.go(Routes.travels),
                child: Row(
                  children: [
                    for (final (i, (v, l, color)) in [
                      (s.placesVisited, 'Places', AppColors.visited),
                      (s.cities, 'Cities', AppColors.oceanBlue),
                      (s.regions, 'States', AppColors.deepTeal),
                      (s.photos, 'Photos', AppColors.warmOrange),
                    ].indexed) ...[
                      if (i > 0) Container(width: 1, height: 36, color: context.palette.line),
                      Expanded(
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AnimatedCount(
                                value: v,
                                style: context.text.headlineMedium?.copyWith(color: color),
                              ),
                            ),
                            Text(l, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          SectionHeader(
            'Achievements',
            subtitle: ach.isEmpty ? 'Visit places to unlock badges' : '${ach.length} of ${allAch.length} unlocked',
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
            SectionHeader(
              'Travel memories',
              action: 'Journal',
              onAction: () => context.go(Routes.travelsTab('journal')),
            ),
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
          const SectionHeader('More'),
          Padding(
            padding: AppSpace.screen,
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              child: Column(
                children: [
                  for (final (i, (icon, color, label, onTap)) in [
                    (Icons.bookmark_rounded, AppColors.bucket, 'Bucket list', () => context.push(Routes.bucket)),
                    (
                      Icons.insights_rounded,
                      AppColors.oceanBlue,
                      'Travel analytics',
                      () => context.push(Routes.analytics),
                    ),
                    (
                      Icons.add_location_alt_rounded,
                      AppColors.hiddenGem,
                      'Places I added',
                      () => context.push(Routes.myPlaces),
                    ),
                    (
                      Icons.public_rounded,
                      AppColors.deepTeal,
                      'Change default country',
                      () => context.push(Routes.countries),
                    ),
                    (Icons.settings_rounded, AppColors.slate, 'Settings', () => context.push(Routes.settings)),
                  ].indexed) ...[
                    if (i > 0) const Divider(height: 1, indent: 64),
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: AppRadius.smAll),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      title: Text(label),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: onTap,
                    ),
                  ],
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
