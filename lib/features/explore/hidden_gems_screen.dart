import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../domain/entities/place.dart';
import 'place_browser.dart';
import 'place_filters.dart';

class HiddenGemsScreen extends ConsumerWidget {
  const HiddenGemsScreen({super.key, this.destinationId});
  final String? destinationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryId = ref.watch(selectedCountryIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Hidden Gems')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-gem',
        backgroundColor: AppColors.hiddenGem,
        foregroundColor: Colors.white,
        onPressed: () => context.push(
          '${Routes.addPlace}?kind=hiddenGem${destinationId == null ? '' : '&destination=$destinationId'}',
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add New Place'),
      ),
      body: AsyncView(
        value: ref.watch(catalogProvider),
        builder: (cat) {
          final dest = cat.destination(destinationId);
          final gems = dest != null
              ? cat.placesAt(dest.id, kind: PlaceKind.hiddenGem)
              : cat.placesIn(countryId: countryId, kind: PlaceKind.hiddenGem);
          return PlaceBrowser(
            catalog: cat,
            places: gems,
            quickFilters: const [
              PlaceFilter.nature,
              PlaceFilter.adventure,
              PlaceFilter.familyFriendly,
              PlaceFilter.notVisited,
            ],
            emptyTitle: 'No hidden gems yet',
            emptyMessage: 'Know a secret spot? Add it — it stays private on your device.',
            header: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpace.lg),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lgAll,
                  gradient: LinearGradient(
                    colors: [AppColors.hiddenGem.withValues(alpha: 0.9), AppColors.oceanBlue.withValues(alpha: 0.9)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.diamond_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dest == null ? 'Off the beaten path' : 'Hidden gems around ${dest.name}',
                            style: context.text.titleMedium?.copyWith(color: Colors.white),
                          ),
                          Text(
                            'Quieter waterfalls, viewpoints and trails. Check access notes before you go.',
                            style: context.text.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
