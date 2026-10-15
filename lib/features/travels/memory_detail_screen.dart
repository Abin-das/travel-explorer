import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';

class MemoryDetailScreen extends ConsumerWidget {
  const MemoryDetailScreen({super.key, required this.memoryId});
  final String memoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(memoriesProvider).where((m) => m.id == memoryId).firstOrNull;
    final cat = ref.watch(catalogProvider).value;
    if (m == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.auto_stories_rounded,
          title: 'Memory not found',
          message: 'It may have been deleted.',
        ),
      );
    }
    final place = cat?.place(m.placeId);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => context.push(Routes.editMemory(m.id)),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (m.photos.isNotEmpty)
                    GestureDetector(
                      onTap: () => PhotoViewer.open(context, m.photos, 0),
                      child: LocalPhoto(path: m.photos.first.path, cacheWidth: 1200),
                    )
                  else if (place != null)
                    PlaceCover(place: place),
                  const BottomScrim(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.xxxl),
            sliver: SliverList.list(
              children: [
                Text(m.title, style: context.text.headlineLarge),
                const SizedBox(height: AppSpace.sm),
                InkWell(
                  onTap: place == null ? null : () => context.push(Routes.place(place.id)),
                  child: Row(
                    children: [
                      Icon(Icons.place_rounded, size: 18, color: context.colors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place == null ? 'Unknown place' : '${place.name}, ${cat!.placeLocation(place)}',
                          style: context.text.titleSmall?.copyWith(color: context.colors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Visited on ${formatDate(m.date)} · ${plural(m.photos.length, 'photo')}',
                  style: context.text.bodySmall,
                ),
                if (m.rating != null) ...[const SizedBox(height: AppSpace.sm), RatingStars(value: m.rating, size: 20)],
                if (m.note.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.lg),
                  Text(m.note, style: context.text.bodyLarge),
                ],
                DetailHeading('Photo collection (${m.photos.length})'),
                if (m.photos.isEmpty)
                  Text('No photos yet. Tap edit to add some.', style: context.text.bodyMedium)
                else
                  PhotoGrid(photos: m.photos),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
