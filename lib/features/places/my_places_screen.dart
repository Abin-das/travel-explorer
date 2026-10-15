import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common.dart';

/// Places the user has submitted on this device.
class MyPlacesScreen extends ConsumerWidget {
  const MyPlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = [...ref.watch(customPlacesProvider)]
      ..sort((a, b) => (b.submission?.updatedAt ?? DateTime(0)).compareTo(a.submission?.updatedAt ?? DateTime(0)));
    return Scaffold(
      appBar: AppBar(title: const Text('Places I added')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-place',
        onPressed: () => context.push(Routes.addPlace),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add place'),
      ),
      body: places.isEmpty
          ? EmptyState(
              icon: Icons.add_location_alt_rounded,
              title: 'No places added yet',
              message: 'Add hidden gems, attractions or food spots that are missing from the guide.',
              actionLabel: 'Add a place',
              onAction: () => context.push(Routes.addPlace),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, 100),
              itemCount: places.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
              itemBuilder: (_, i) => i == 0
                  ? const SampleDataNote(
                      text: 'Saved on this device only (status: local draft). Not visible to other users.',
                    )
                  : PlaceTile(
                      place: places[i - 1],
                      trailing: IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => context.push(Routes.editPlace(places[i - 1].id)),
                      ),
                    ),
            ),
    );
  }
}
