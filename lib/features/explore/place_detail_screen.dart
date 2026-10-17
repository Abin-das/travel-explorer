import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/catalog.dart';
import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/directions.dart';
import '../../core/utils/labels.dart';
import '../../core/utils/links.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';
import '../../domain/entities/media.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/user_activity.dart';
import '../map/travel_map.dart';
import 'destination_screen.dart' show styleFor;
import 'links_sheet.dart';
import 'visit_sheet.dart';

class PlaceDetailScreen extends ConsumerWidget {
  const PlaceDetailScreen({super.key, required this.placeId});
  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final place = catalog.value?.place(placeId);
    return Scaffold(
      body: AsyncView(
        value: catalog,
        builder: (cat) => place == null
            ? EmptyState(
                icon: Icons.wrong_location_rounded,
                title: 'Place not found',
                message: 'It may have been deleted.',
                actionLabel: 'Go back',
                onAction: () => context.pop(),
              )
            : _PlaceBody(place: place, catalog: cat),
      ),
      bottomNavigationBar: place == null ? null : _ActionBar(place: place),
    );
  }
}

Future<void> _markVisited(BuildContext context, WidgetRef ref, Place p) async {
  final wasVisited = ref.read(visitForProvider(p.id)) != null;
  final ok = await showVisitSheet(context, ref, placeId: p.id, name: p.name);
  if (ok && !wasVisited && context.mounted) showVisitedCelebration(context);
}

/// Sticky bottom bar: bookmark, directions and the primary visit action.
class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = ref.watch(visitForProvider(place.id));
    final verb = place.isFood ? 'Tried' : 'Visited';
    return Container(
      decoration: BoxDecoration(
        color: context.palette.card,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
        child: Row(
          children: [
            _RoundAction(
              child: BookmarkButton(type: SubjectType.place, id: place.id, onImage: false, size: 22),
            ),
            const SizedBox(width: AppSpace.sm),
            _RoundAction(
              child: IconButton(
                tooltip: 'Directions',
                icon: const Icon(Icons.directions_rounded),
                onPressed: () => openDirections(context, place.location, label: place.name),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppDurations.medium,
                child: visit == null
                    ? FilledButton.icon(
                        key: const ValueKey('mark'),
                        onPressed: () => _markVisited(context, ref, place),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: Text('Mark as $verb', maxLines: 1, overflow: TextOverflow.ellipsis),
                      )
                    : FilledButton.icon(
                        key: const ValueKey('visited'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.visited),
                        onPressed: () => _markVisited(context, ref, place),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text(
                          '$verb · ${formatShortDate(visit.visitedOn)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(shape: BoxShape.circle, color: context.palette.chip),
    child: child,
  );
}

class _PlaceBody extends ConsumerWidget {
  const _PlaceBody({required this.place, required this.catalog});
  final Place place;
  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = place;
    final visit = ref.watch(visitForProvider(p.id));
    final note = ref.watch(noteForProvider(p.id));
    final memories = ref.watch(memoriesForPlaceProvider(p.id));
    final photos = [for (final m in memories) ...m.photos, ...submissionPhotos(p)];
    final dest = catalog.destination(p.destinationId);
    final top = MediaQuery.paddingOf(context).top;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          stretch: true,
          backgroundColor: context.colors.surface,
          leading: Padding(
            padding: const EdgeInsets.all(6),
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.35),
              child: BackButton(color: Colors.white, onPressed: () => context.pop()),
            ),
          ),
          actions: [
            if (p.isUserSubmitted)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  child: _OwnerMenu(place: p),
                ),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Stack(
              fit: StackFit.expand,
              children: [
                PlaceCover(place: p, thumbnail: false),
                // Darken top for the status bar & buttons, bottom for the sheet edge.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.25, 0.7, 1],
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
                if (p.photo != null && ref.watch(coverPhotoForProvider(p.id)) == null)
                  Positioned(
                    right: 12,
                    bottom: 36,
                    left: 80,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PhotoCredit(photo: p.photo!),
                    ),
                  ),
                if (photos.isNotEmpty)
                  Positioned(
                    left: 12,
                    bottom: 36,
                    child: Pill(
                      label: plural(photos.length, 'photo'),
                      icon: Icons.photo_library_rounded,
                      color: Colors.black.withValues(alpha: 0.45),
                      solid: true,
                    ),
                  ),
                SizedBox(height: top),
              ],
            ),
          ),
          // The content "sheet" overlaps the photo with rounded corners.
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(24),
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.xxl),
          sliver: SliverList.list(
            children: [
              _TitleBlock(place: p, catalog: catalog, visited: visit != null),
              const SizedBox(height: AppSpace.lg),
              _QuickFacts(place: p, catalog: catalog),
              const SizedBox(height: AppSpace.lg),
              _SecondaryActions(place: p, hasNote: note != null),
              if (visit != null) ...[
                const SizedBox(height: AppSpace.lg),
                _VisitCard(
                  place: p,
                  visit: visit,
                  photoCount: photos.length,
                  note: note?.text,
                  onEdit: () => _markVisited(context, ref, p),
                ),
              ] else if (note != null) ...[
                const SizedBox(height: AppSpace.lg),
                _NoteCard(placeId: p.id, text: note.text),
              ],
              if (p.isFood) ...[
                const _SectionTitle('My review'),
                _ReviewCard(place: p),
                const SizedBox(height: AppSpace.md),
                LinksCard(placeId: p.id),
              ],
              const _SectionTitle('About'),
              _AboutCard(place: p),
              if (p.about != null && p.about!.history.isNotEmpty) ...[
                const _SectionTitle('History'),
                _SourcedCard(icon: Icons.history_edu_rounded, text: p.about!.history, about: p.about!),
              ],
              const _SectionTitle('Plan your visit'),
              _PlanCard(place: p, catalog: catalog),
              if (p.famousDishes.isNotEmpty) ...[
                const _SectionTitle('Famous dishes'),
                Text('Tap a dish to add it to Foods I want to try.', style: context.text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final d in p.famousDishes) _DishWishChip(name: d)]),
              ],
              if (p.thingsToDo.isNotEmpty) ...[
                const _SectionTitle('Things to do'),
                SurfaceCard(child: BulletList(p.thingsToDo, icon: Icons.local_activity_rounded)),
              ],
              if (p.tips.isNotEmpty) ...[
                const _SectionTitle('Travel tips'),
                SurfaceCard(child: BulletList(p.tips, icon: Icons.lightbulb_rounded)),
              ],
              if (!p.isFood) ...[const _SectionTitle('Links'), LinksCard(placeId: p.id)],
              _SectionTitle(photos.isEmpty ? 'Your photos' : 'Your photos (${photos.length})'),
              if (photos.isEmpty)
                SurfaceCard(
                  onTap: () => context.push(Routes.newMemory(p.id)),
                  child: Row(
                    children: [
                      Icon(Icons.add_photo_alternate_rounded, color: context.colors.primary, size: 32),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Text(
                          'Add photos and a memory from your visit. Your first photo becomes this place\'s cover.',
                          style: context.text.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )
              else
                PhotoGrid(photos: photos.take(9).toList()),
              if (memories.isNotEmpty) ...[
                const _SectionTitle('Memories'),
                for (final m in memories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: SurfaceCard(
                      onTap: () => context.push(Routes.memory(m.id)),
                      child: Row(
                        children: [
                          Icon(Icons.auto_stories_rounded, color: context.colors.primary),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.title, style: context.text.titleSmall),
                                Text(
                                  '${formatShortDate(m.date)} · ${plural(m.photos.length, 'photo')}',
                                  style: context.text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
              ],
              const _SectionTitle('Location'),
              _LocationCard(place: p),
              if (dest != null) ...[const _SectionTitle('Part of'), DestinationTile(destination: dest)],
              const SizedBox(height: AppSpace.xl),
              p.isUserSubmitted
                  ? const SampleDataNote(
                      text:
                          'Added by you. Saved only on this device — it is not shared with other users. '
                          'When community features arrive, submissions will go through review before publishing.',
                    )
                  : const SampleDataNote(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.md),
    child: Text(text, style: context.text.titleLarge),
  );
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.place, required this.catalog, required this.visited});
  final Place place;
  final Catalog catalog;
  final bool visited;

  @override
  Widget build(BuildContext context) {
    final p = place;
    final location = [
      catalog.placeLocation(p),
      catalog.country(p.countryId)?.name,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Pill(label: p.kind.label, icon: p.kind.icon, color: p.kind.color, solid: true),
            if (visited) const VisitedBadge(compact: true),
            if (p.isUserSubmitted)
              const Pill(label: 'Added by you', icon: Icons.person_rounded, color: AppColors.oceanBlue),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Text(p.name, style: context.text.displaySmall),
        const SizedBox(height: AppSpace.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.place_rounded, size: 18, color: context.colors.primary),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(location, style: context.text.bodyLarge?.copyWith(color: context.palette.muted)),
            ),
          ],
        ),
        if (p.categories.any((c) => c != PlaceCategory.food) || p.foodCategories.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in p.categories.where((c) => c != PlaceCategory.food))
                AppChip(label: c.label, icon: c.icon, onTap: () => context.push(Routes.category(c.name))),
              for (final c in p.foodCategories) Pill(label: c.label, icon: c.icon, color: AppColors.foodSpot),
            ],
          ),
        ],
      ],
    );
  }
}

/// Horizontal strip of the key planning facts.
class _QuickFacts extends StatelessWidget {
  const _QuickFacts({required this.place, required this.catalog});
  final Place place;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final p = place;
    final dest = catalog.destination(p.destinationId);
    final facts = <(IconData, String, String)>[
      if (p.bestTime != null)
        (Icons.wb_sunny_rounded, 'Best time', p.bestTime!)
      else if (dest != null)
        (Icons.wb_sunny_rounded, 'Best time', monthRange(dest.season.bestMonths)),
      if (p.visitDuration != null) (Icons.timelapse_rounded, 'Duration', p.visitDuration!),
      if (!p.isFood || p.entry != EntryType.unknown) (Icons.confirmation_number_rounded, 'Entry', p.entry.label),
      if (p.priceRange != null) (Icons.payments_rounded, 'Price', p.priceRange!.split(' ').first),
      (
        p.familyFriendly ? Icons.family_restroom_rounded : Icons.hiking_rounded,
        'Good for',
        p.familyFriendly ? 'Families' : 'Active travellers',
      ),
    ];
    return ResponsiveGrid(
      minTileWidth: 140,
      spacing: AppSpace.sm,
      maxColumns: 3,
      children: [
        for (final (icon, label, value) in facts)
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: context.palette.card,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: context.palette.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: context.colors.primary),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: context.text.labelSmall?.copyWith(color: context.palette.muted)),
                      Text(value, style: context.text.titleSmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SecondaryActions extends ConsumerWidget {
  const _SecondaryActions({required this.place, required this.hasNote});
  final Place place;
  final bool hasNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      (Icons.add_a_photo_rounded, 'Add photos', () => context.push(Routes.newMemory(place.id))),
      (
        hasNote ? Icons.sticky_note_2_rounded : Icons.edit_note_rounded,
        hasNote ? 'Edit note' : 'Add note',
        () => showNoteSheet(context, ref, place.id),
      ),
      (Icons.map_rounded, 'View on map', () => _showMapSheet(context, ref, place)),
    ];
    return Row(
      children: [
        for (final (i, (icon, label, onTap)) in actions.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpace.sm),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                minimumSize: const Size(0, 64),
              ),
              onPressed: onTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(height: 4),
                  Text(label, textAlign: TextAlign.center, style: context.text.labelMedium),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

void _showMapSheet(BuildContext context, WidgetRef ref, Place place) {
  final style = styleFor(
    place,
    ref.read(visitsProvider).map((v) => v.subjectId).toSet(),
    ref.read(bucketProvider).map((b) => b.subjectId).toSet(),
  );
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.75,
      child: Column(
        children: [
          Expanded(
            child: TravelMap(
              center: place.location,
              zoom: 14,
              pins: [MapPin(id: place.id, point: place.location, style: style, label: place.name)],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(AppSpace.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => openDirections(ctx, place.location),
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Open in navigation app'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Our curated description, plus the sourced Wikipedia summary when available.
class _AboutCard extends StatefulWidget {
  const _AboutCard({required this.place});
  final Place place;

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    final about = p.about;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.description, style: context.text.bodyLarge),
          if (about != null && about.text.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            const Divider(),
            const SizedBox(height: AppSpace.md),
            AnimatedSize(
              duration: AppDurations.medium,
              alignment: Alignment.topCenter,
              child: Text(
                about.text,
                maxLines: _expanded ? null : 4,
                overflow: _expanded ? null : TextOverflow.fade,
                style: context.text.bodyMedium,
              ),
            ),
            if (about.text.length > 220)
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Show less' : 'Read more'),
              ),
            _SourceLine(about: about),
          ],
        ],
      ),
    );
  }
}

class _SourcedCard extends StatelessWidget {
  const _SourcedCard({required this.icon, required this.text, required this.about});
  final IconData icon;
  final String text;
  final SourcedText about;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.warmOrange),
              const SizedBox(width: AppSpace.md),
              Expanded(child: Text(text, style: context.text.bodyMedium)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          _SourceLine(about: about),
        ],
      ),
    );
  }
}

class _SourceLine extends StatelessWidget {
  const _SourceLine({required this.about});
  final SourcedText about;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.smAll,
      onTap: () => openExternal(context, about.sourceUrl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.menu_book_rounded, size: 14, color: context.palette.muted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Source: ${about.sourceName} — "${about.sourceTitle}" (${about.license})',
                style: context.text.labelSmall?.copyWith(color: context.palette.muted),
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 14, color: context.palette.muted),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.place, required this.catalog});
  final Place place;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final p = place;
    final dest = catalog.destination(p.destinationId);
    final rows = <Widget>[
      if (p.bestTime != null) InfoRow(icon: Icons.wb_sunny_rounded, label: 'Best time to visit', value: p.bestTime!),
      if (dest != null)
        InfoRow(
          icon: Icons.calendar_month_rounded,
          label: 'Season in ${dest.name}',
          value: '${monthRange(dest.season.bestMonths)} · ${dest.season.recommendedSeason}',
          hint: 'Curated guidance, not a forecast.',
        ),
      if (p.visitDuration != null)
        InfoRow(icon: Icons.timelapse_rounded, label: 'Recommended duration', value: p.visitDuration!),
      if (!p.isFood || p.entry != EntryType.unknown)
        InfoRow(icon: Icons.confirmation_number_rounded, label: 'Entry', value: p.entry.label, hint: p.entryNote),
      if (p.visitingHours != null)
        InfoRow(
          icon: Icons.schedule_rounded,
          label: p.isUserSubmitted ? 'Visiting hours' : 'Opening hours (indicative)',
          value: p.visitingHours!,
          hint: p.isUserSubmitted ? null : 'Not verified — confirm locally before visiting.',
        ),
      if (p.priceRange != null)
        InfoRow(
          icon: Icons.payments_rounded,
          label: 'Price range',
          value: p.priceRange!,
          hint: 'Indicative only; prices are not verified.',
        ),
      if (p.address != null) InfoRow(icon: Icons.location_on_rounded, label: 'Address', value: p.address!),
      if (p.locality != null)
        InfoRow(icon: Icons.account_tree_rounded, label: 'Administrative location', value: p.locality!),
      if (p.accessibility != null)
        InfoRow(icon: Icons.accessible_forward_rounded, label: 'Accessibility', value: p.accessibility!),
    ];
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
      child: Column(children: rows),
    );
  }
}

/// Food spots: personal rating (stored on the visit) and review note.
class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = ref.watch(visitForProvider(place.id));
    final note = ref.watch(noteForProvider(place.id));
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My rating', style: context.text.titleSmall),
          const SizedBox(height: 4),
          RatingStars(
            value: visit?.rating,
            size: 34,
            onChanged: (r) async {
              final n = ref.read(visitsProvider.notifier);
              if (visit == null) {
                await n.markVisited(SubjectType.place, place.id, rating: r);
                if (context.mounted) showSnack(context, 'Rated and marked as tried today — tap the date to change it');
              } else {
                await n.put(visit.copyWith(rating: r, clearRating: r == null));
              }
            },
          ),
          Text(
            visit == null ? 'Rating a spot marks it as tried.' : 'Private — only you can see this.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpace.md),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(note == null ? Icons.rate_review_outlined : Icons.rate_review_rounded),
            title: Text(note == null ? 'Write a review' : note.text, maxLines: 4, overflow: TextOverflow.ellipsis),
            subtitle: note == null ? const Text('What did you eat? Would you go back?') : null,
            trailing: Icon(note == null ? Icons.add_rounded : Icons.edit_rounded),
            onTap: () => showNoteSheet(context, ref, place.id),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.placeId, required this.text});
  final String placeId;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SurfaceCard(
    onTap: () => showNoteSheet(context, ref, placeId),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.sticky_note_2_rounded, color: context.colors.secondary),
        const SizedBox(width: AppSpace.md),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ],
    ),
  );
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.place,
    required this.visit,
    required this.photoCount,
    required this.onEdit,
    this.note,
  });
  final Place place;
  final Visit visit;
  final int photoCount;
  final String? note;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        color: AppColors.visited.withValues(alpha: context.isDark ? 0.18 : 0.08),
        border: Border.all(color: AppColors.visited.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.visited),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'Status: ${place.isFood ? 'Tried' : 'Visited'} ✓',
                  style: context.text.titleMedium?.copyWith(color: AppColors.visited),
                ),
              ),
              TextButton(onPressed: onEdit, child: const Text('Edit')),
            ],
          ),
          Text(
            '${place.isFood ? 'Tried' : 'Visited'} on: ${formatDate(visit.visitedOn)}',
            style: context.text.bodyMedium,
          ),
          Text('Photos: $photoCount', style: context.text.bodyMedium),
          if (visit.rating != null && !place.isFood) ...[
            const SizedBox(height: 4),
            RatingStars(value: visit.rating, size: 18),
          ],
          if (note != null && !place.isFood) ...[
            const SizedBox(height: AppSpace.sm),
            Text('Personal note:', style: context.text.labelMedium),
            Text('"$note"', style: context.text.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

class _LocationCard extends ConsumerWidget {
  const _LocationCard({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = place;
    final style = styleFor(
      p,
      ref.watch(visitsProvider).map((v) => v.subjectId).toSet(),
      ref.watch(bucketProvider).map((b) => b.subjectId).toSet(),
    );
    final mapLink = ref.watch(linksForProvider(p.id))?.mapUrl;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      onTap: () => _showMapSheet(context, ref, p),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              child: IgnorePointer(
                child: TravelMap(
                  center: p.location,
                  zoom: 13,
                  interactive: false,
                  pins: [MapPin(id: p.id, point: p.location, style: style, label: p.name)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.sm, AppSpace.sm),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${p.location.lat.toStringAsFixed(4)}, ${p.location.lng.toStringAsFixed(4)} (approx.)',
                  style: context.text.bodySmall,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (mapLink != null)
                      TextButton.icon(
                        onPressed: () => openExternal(context, mapLink),
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('My link'),
                      ),
                    TextButton.icon(
                      onPressed: () => openDirections(context, p.location),
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Directions'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerMenu extends ConsumerWidget {
  const _OwnerMenu({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      onSelected: (v) async {
        if (v == 'edit') context.push(Routes.editPlace(place.id));
        if (v == 'delete') {
          final ok = await confirmAction(
            context,
            title: 'Delete this place?',
            message: 'Your visit, notes, links and memories for it will also be removed.',
            confirmLabel: 'Delete',
            destructive: true,
          );
          if (!ok) return;
          await ref.read(customPlacesProvider.notifier).delete(place.id);
          if (context.mounted) context.pop();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit place')),
        PopupMenuItem(value: 'delete', child: Text('Delete place')),
      ],
    );
  }
}

class _DishWishChip extends ConsumerWidget {
  const _DishWishChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishes = ref.watch(dishWishesProvider);
    final cat = ref.watch(catalogProvider).value;
    final match = cat?.dishes.where((d) => d.name.toLowerCase() == name.toLowerCase()).firstOrNull;
    final added = wishes.any(
      (w) => (match != null && w.dishId == match.id) || (w.customName?.toLowerCase() == name.toLowerCase()),
    );
    return AppChip(
      label: name,
      icon: added ? Icons.bookmark_added_rounded : Icons.add_rounded,
      selected: added,
      onTap: () async {
        if (added) {
          context.push(Routes.bucketTab('food'));
          return;
        }
        final n = ref.read(dishWishesProvider.notifier);
        if (match != null) {
          await n.addDish(match.id);
        } else {
          await n.addCustom(name);
        }
        if (context.mounted) showSnack(context, '$name added to Foods I want to try');
      },
    );
  }
}
