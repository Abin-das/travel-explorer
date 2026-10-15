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
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/user_activity.dart';

/// Create or edit a travel memory (title, date, rating, note, photos).
class MemoryEditorScreen extends ConsumerStatefulWidget {
  const MemoryEditorScreen({super.key, this.placeId, this.memoryId});
  final String? placeId;
  final String? memoryId;

  @override
  ConsumerState<MemoryEditorScreen> createState() => _MemoryEditorScreenState();
}

class _MemoryEditorScreenState extends ConsumerState<MemoryEditorScreen> {
  // Captured up front: `ref` must not be used in dispose().
  late final _storage = ref.read(photoStorageProvider);
  final _title = TextEditingController();
  final _note = TextEditingController();
  String? _placeId;
  late DateTime _date;
  int? _rating;
  List<TravelPhoto> _photos = [];
  final List<TravelPhoto> _added = [];
  TravelMemory? _existing;
  bool _saved = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _storage;
    _placeId = widget.placeId;
    _date = ref.read(visitForProvider(widget.placeId ?? ''))?.visitedOn ?? DateTime.now();
    if (widget.memoryId != null) {
      final m = ref.read(memoriesProvider).where((m) => m.id == widget.memoryId).firstOrNull;
      if (m != null) {
        _existing = m;
        _placeId = m.placeId;
        _title.text = m.title;
        _note.text = m.note;
        _date = m.date;
        _rating = m.rating;
        _photos = [...m.photos];
      }
    }
  }

  @override
  void dispose() {
    if (!_saved) {
      final s = _storage;
      for (final p in _added) {
        s.delete(p.path);
      }
    }
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _addPhotos({bool camera = false}) async {
    try {
      final storage = ref.read(photoStorageProvider);
      final picked = camera ? await storage.pickFromCamera() : await storage.pickFromGallery();
      if (picked.isEmpty) return;
      setState(() {
        _photos = [..._photos, ...picked];
        _added.addAll(picked);
      });
    } catch (e) {
      if (mounted) showSnack(context, camera ? 'Camera unavailable' : 'Could not open the photo library');
    }
  }

  void _removePhoto(TravelPhoto p) {
    setState(() => _photos = _photos.where((x) => x.id != p.id).toList());
    if (_added.any((a) => a.id == p.id)) {
      _added.removeWhere((a) => a.id == p.id);
      ref.read(photoStorageProvider).delete(p.path);
    }
    // Photos that belonged to the saved memory are deleted on save.
  }

  Future<void> _save() async {
    if (_placeId == null) {
      showSnack(context, 'Choose the place this memory belongs to');
      return;
    }
    setState(() => _busy = true);
    final wasVisited = ref.read(visitForProvider(_placeId!)) != null;
    final m = await ref
        .read(memoriesProvider.notifier)
        .save(
          id: _existing?.id,
          placeId: _placeId!,
          title: _title.text,
          date: _date,
          note: _note.text,
          rating: _rating,
          photos: _photos,
        );
    _saved = true;
    if (!mounted) return;
    showSnack(context, wasVisited ? 'Memory saved' : 'Memory saved — place marked as visited');
    if (_existing == null) {
      context.pushReplacement(Routes.memory(m.id));
    } else {
      context.pop();
    }
  }

  Future<void> _pickPlace(Catalog cat) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PlacePickerSheet(catalog: cat),
    );
    if (id != null) {
      setState(() {
        _placeId = id;
        _date = ref.read(visitForProvider(id))?.visitedOn ?? _date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = ref.watch(catalogProvider).value;
    final place = cat?.place(_placeId);
    final visited = _placeId != null && ref.watch(visitForProvider(_placeId!)) != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'New memory' : 'Edit memory'),
        actions: [
          if (_existing != null)
            IconButton(
              tooltip: 'Delete memory',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Delete memory?',
                  message: 'Its ${plural(_existing!.photos.length, 'photo')} will be removed from this device.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (!ok) return;
                await ref.read(memoriesProvider.notifier).delete(_existing!.id);
                if (context.mounted) context.go(Routes.travels);
              },
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.sm,
          AppSpace.gutter,
          AppSpace.xxxl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          SurfaceCard(
            onTap: widget.placeId == null && _existing == null && cat != null ? () => _pickPlace(cat) : null,
            padding: const EdgeInsets.all(AppSpace.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: ClipRRect(
                    borderRadius: AppRadius.mdAll,
                    child: place == null
                        ? ColoredBox(color: context.palette.chip, child: const Icon(Icons.add_location_rounded))
                        : PlaceCover(place: place),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place?.name ?? 'Choose a place', style: context.text.titleMedium),
                      Text(
                        place == null ? 'Tap to pick where this happened' : cat!.placeLocation(place),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (widget.placeId == null && _existing == null) const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          if (place != null && !visited) ...[
            const SizedBox(height: AppSpace.sm),
            const SampleDataNote(text: 'Saving a memory will also mark this place as visited on the chosen date.'),
          ],
          const SizedBox(height: AppSpace.lg),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title', hintText: 'Sunrise over the tea hills'),
          ),
          const SizedBox(height: AppSpace.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_rounded),
            title: const Text('Visit date'),
            subtitle: Text(formatDate(_date)),
            trailing: const Icon(Icons.edit_calendar_rounded),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          Text('Your rating', style: context.text.titleSmall),
          RatingStars(value: _rating, onChanged: (v) => setState(() => _rating = v), size: 32),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _note,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Personal notes',
              hintText: 'What made this place special?',
              alignLabelWithHint: true,
            ),
          ),
          DetailHeading('Photos (${_photos.length})'),
          if (_photos.isNotEmpty) ...[
            PhotoGrid(photos: _photos, onRemove: _removePhoto),
            const SizedBox(height: AppSpace.md),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addPhotos,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Gallery'),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addPhotos(camera: true),
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: const Text('Camera'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save memory'),
          ),
        ],
      ),
    );
  }
}

class _PlacePickerSheet extends ConsumerStatefulWidget {
  const _PlacePickerSheet({required this.catalog});
  final Catalog catalog;

  @override
  ConsumerState<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends ConsumerState<_PlacePickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final visited = ref.watch(visitedPlacesProvider).map((v) => v.place).toList();
    final visitedIds = visited.map((p) => p.id).toSet();
    final countryId = ref.watch(selectedCountryIdProvider);
    bool match(Place p) => _q.isEmpty || p.name.toLowerCase().contains(_q.toLowerCase());
    final others =
        widget.catalog.placesIn(countryId: countryId).where((p) => !visitedIds.contains(p.id) && match(p)).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final v = visited.where(match).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (ctx, sc) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.sm),
            child: AppSearchField(hint: 'Search places', onChanged: (s) => setState(() => _q = s)),
          ),
          Expanded(
            child: ListView(
              controller: sc,
              children: [
                if (v.isNotEmpty) const _Label('Visited'),
                for (final p in v) _tile(p, true),
                const _Label('All places'),
                for (final p in others) _tile(p, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Place p, bool visited) => ListTile(
    leading: Icon(
      visited ? Icons.check_circle_rounded : Icons.place_outlined,
      color: visited ? AppColors.visited : null,
    ),
    title: Text(p.name),
    subtitle: Text(widget.catalog.placeLocation(p)),
    onTap: () => Navigator.pop(context, p.id),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, 4),
    child: Text(text, style: context.text.labelLarge?.copyWith(color: context.colors.primary)),
  );
}
