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
import '../../domain/entities/user_activity.dart';

/// Journal card: cover photo (or place art), name, date, note, photo count.
class MemoryCard extends ConsumerWidget {
  const MemoryCard({super.key, required this.memory});
  final TravelMemory memory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(catalogProvider).value;
    final place = cat?.place(memory.placeId);
    return SurfaceCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(Routes.memory(memory.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (memory.photos.isNotEmpty)
                    LocalPhoto(path: memory.photos.first.path, cacheWidth: 500)
                  else if (place != null)
                    PlaceCover(place: place)
                  else
                    const MissingPhoto(),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Pill(
                      label: '${memory.photos.length}',
                      icon: Icons.photo_library_rounded,
                      color: Colors.black.withValues(alpha: 0.45),
                      solid: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memory.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                Text(
                  '${place?.name ?? 'Unknown place'} · ${formatShortDate(memory.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
                if (memory.note.isNotEmpty)
                  Text(memory.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
