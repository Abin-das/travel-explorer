import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/catalog.dart';
import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/utils/links.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';
import '../../domain/entities/common.dart';
import '../../domain/entities/geography.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/user_activity.dart';
import 'location_picker.dart';

const _other = '__other__';

/// Create or edit a user-submitted place. Saved locally with
/// [SubmissionStatus.localOnly]; never shared without a backend + moderation.
class AddPlaceScreen extends ConsumerStatefulWidget {
  const AddPlaceScreen({super.key, this.editId, this.initialKind, this.initialDestinationId});

  final String? editId;
  final PlaceKind? initialKind;
  final String? initialDestinationId;

  @override
  ConsumerState<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends ConsumerState<AddPlaceScreen> {
  // Captured up front: `ref` must not be used in dispose().
  late final _storage = ref.read(photoStorageProvider);

  @override
  void initState() {
    super.initState();
    _storage;
  }

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _regionText = TextEditingController();
  final _cityText = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _desc = TextEditingController();
  final _best = TextEditingController();
  final _hours = TextEditingController();
  final _tips = TextEditingController();
  final _dishes = TextEditingController();
  final _price = TextEditingController();
  final _mapLink = TextEditingController();
  final _reels = TextEditingController();

  PlaceKind _kind = PlaceKind.hiddenGem;
  String _countryId = 'in';
  String? _regionId;
  String? _destinationId;
  final Set<PlaceCategory> _cats = {};
  final Set<FoodCategory> _foodCats = {};
  bool _family = false;
  EntryType _entry = EntryType.unknown;
  List<TravelPhoto> _photos = [];
  final List<TravelPhoto> _added = [];
  final List<TravelPhoto> _removed = [];
  Place? _editing;
  bool _initialised = false;
  bool _saved = false;
  bool _saving = false;
  bool _beenHere = false;
  DateTime _visitDate = DateTime.now();
  int? _rating;

  @override
  void dispose() {
    // Clean up photos picked during an abandoned edit.
    if (!_saved) {
      final storage = _storage;
      for (final p in _added) {
        storage.delete(p.path);
      }
    }
    for (final c in [
      _name,
      _regionText,
      _cityText,
      _lat,
      _lng,
      _desc,
      _best,
      _hours,
      _tips,
      _dishes,
      _price,
      _mapLink,
      _reels,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _init(Catalog cat) {
    if (_initialised) return;
    _initialised = true;
    _countryId = ref.read(selectedCountryIdProvider);
    _kind = widget.initialKind ?? PlaceKind.hiddenGem;
    final dest = cat.destination(widget.initialDestinationId);
    if (dest != null) {
      _countryId = dest.countryId;
      _regionId = dest.regionId;
      _destinationId = dest.id;
    }
    final p = widget.editId == null ? null : cat.place(widget.editId);
    if (p != null && p.isUserSubmitted) {
      _editing = p;
      _kind = p.kind;
      _name.text = p.name;
      _countryId = p.countryId;
      _regionId = p.regionId ?? (p.regionName != null ? _other : null);
      _regionText.text = p.regionName ?? '';
      _destinationId = p.destinationId ?? (p.cityName != null ? _other : null);
      _cityText.text = p.cityName ?? '';
      _lat.text = p.location.lat.toString();
      _lng.text = p.location.lng.toString();
      _desc.text = p.description;
      _best.text = p.bestTime ?? '';
      _hours.text = p.visitingHours ?? '';
      _tips.text = p.tips.join('\n');
      _dishes.text = p.famousDishes.join(', ');
      _price.text = p.priceRange ?? '';
      _cats.addAll(p.categories.where((c) => c != PlaceCategory.food));
      _foodCats.addAll(p.foodCategories);
      _family = p.familyFriendly;
      _entry = p.entry;
      _photos = submissionPhotos(p);
      final links = ref.read(linksForProvider(p.id));
      _mapLink.text = links?.mapUrl ?? '';
      _reels.text = links?.reelUrls.join('\n') ?? '';
    }
  }

  List<String> get _reelUrls => _reels.text
      .split(RegExp(r'[\s,]+'))
      .map(normaliseUrl)
      .whereType<String>()
      .where(isInstagramLink)
      .toSet()
      .toList();

  /// Fills coordinates from a pasted Google Maps link when it contains them.
  void _onMapLinkChanged(String v) {
    final url = normaliseUrl(v);
    final point = url == null ? null : coordinatesFromMapLink(url);
    if (point != null && _point != point) {
      setState(() {
        _lat.text = point.lat.toStringAsFixed(6);
        _lng.text = point.lng.toStringAsFixed(6);
      });
      showSnack(context, 'Location filled in from the map link');
    }
  }

  GeoPoint? get _point {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) return null;
    return GeoPoint(lat, lng);
  }

  GeoPoint _defaultCenter(Catalog cat) =>
      _point ?? cat.destination(_destinationId)?.center ?? cat.country(_countryId)?.center ?? const GeoPoint(20, 78);

  Future<void> _pickPhotos() async {
    try {
      final picked = await ref.read(photoStorageProvider).pickFromGallery();
      setState(() {
        _photos = [..._photos, ...picked];
        _added.addAll(picked);
      });
    } catch (e) {
      if (mounted) showSnack(context, 'Could not open the photo library');
    }
  }

  Future<void> _save(Catalog cat) async {
    if (!_form.currentState!.validate()) return;
    final point = _point;
    if (point == null) {
      showSnack(context, 'Set a location by dropping a pin or entering coordinates');
      return;
    }
    final reelProblem = _reels.text
        .split(RegExp(r'[\s,]+'))
        .where((s) => s.trim().isNotEmpty)
        .any((s) => normaliseUrl(s) == null || !isInstagramLink(normaliseUrl(s)!));
    if (reelProblem) {
      showSnack(context, 'Reel links must be Instagram links (instagram.com/reel/…)');
      return;
    }
    if (_kind != PlaceKind.foodSpot && _cats.isEmpty) {
      showSnack(context, 'Pick at least one category');
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final regionId = _regionId == _other ? null : _regionId;
    final destId = _destinationId == _other ? null : _destinationId;
    final place = Place(
      id: _editing?.id ?? 'user.${uuid.v4()}',
      kind: _kind,
      countryId: _countryId,
      regionId: regionId,
      regionName: regionId == null && _regionText.text.trim().isNotEmpty ? _regionText.text.trim() : null,
      destinationId: destId,
      cityName: destId == null && _cityText.text.trim().isNotEmpty ? _cityText.text.trim() : null,
      name: _name.text.trim(),
      description: _desc.text.trim(),
      location: point,
      categories: _kind == PlaceKind.foodSpot ? const [PlaceCategory.food] : _cats.toList(),
      foodCategories: _kind == PlaceKind.foodSpot ? _foodCats.toList() : const [],
      popularity: _kind == PlaceKind.hiddenGem ? 20 : 40,
      bestTime: _best.text.trim().isEmpty ? null : _best.text.trim(),
      visitingHours: _hours.text.trim().isEmpty ? null : _hours.text.trim(),
      entry: _entry,
      tips: _tips.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      familyFriendly: _family,
      famousDishes: _kind == PlaceKind.foodSpot
          ? _dishes.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : const [],
      priceRange: _kind == PlaceKind.foodSpot && _price.text.trim().isNotEmpty ? _price.text.trim() : null,
      imageUrls: [for (final p in _photos) '$localImagePrefix${p.path}'],
      source: DataSource.userSubmitted,
      submission: Submission(
        status: SubmissionStatus.localOnly,
        createdAt: _editing?.submission?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    await ref.read(customPlacesProvider.notifier).save(place);
    if (_beenHere) {
      await ref.read(visitsProvider.notifier).markVisited(SubjectType.place, place.id, on: _visitDate, rating: _rating);
    }
    await ref
        .read(linksProvider.notifier)
        .save(PlaceLinks(placeId: place.id, mapUrl: normaliseUrl(_mapLink.text), reelUrls: _reelUrls, updatedAt: now));
    final storage = ref.read(photoStorageProvider);
    for (final p in _removed) {
      await storage.delete(p.path);
    }
    _saved = true;
    if (!mounted) return;
    showSnack(context, _editing == null ? '${place.name} added — saved on this device' : 'Changes saved');
    if (_editing == null) {
      context.pushReplacement(Routes.place(place.id));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.editId == null ? 'Add New Place' : 'Edit Place')),
      body: AsyncView(
        value: ref.watch(catalogProvider),
        builder: (cat) {
          _init(cat);
          return _buildForm(context, cat);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, Catalog cat) {
    final regions = cat.regionsOf(_countryId);
    final dests = _regionId == null || _regionId == _other
        ? const <Destination>[]
        : cat.destinationsIn(regionId: _regionId);
    final countries = [...cat.countries]..sort((a, b) => a.name.compareTo(b.name));
    final point = _point;

    return Form(
      key: _form,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.sm,
          AppSpace.gutter,
          AppSpace.xxxl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          const SampleDataNote(
            text:
                'Places you add are saved only on this device and are not visible to other users. '
                'Community sharing will require review once a backend is connected.',
          ),
          const SizedBox(height: AppSpace.lg),
          Text('This place is a…', style: context.text.titleSmall),
          const SizedBox(height: AppSpace.sm),
          SegmentedButton<PlaceKind>(
            segments: [
              for (final k in PlaceKind.values)
                ButtonSegment(value: k, icon: Icon(k.icon), label: Text(k.label.split(' ').last)),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: AppSpace.lg),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Place name *'),
            validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a name' : null,
          ),
          const SizedBox(height: AppSpace.md),
          DropdownButtonFormField<String>(
            initialValue: _countryId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Country *'),
            items: [for (final c in countries) DropdownMenuItem(value: c.id, child: Text('${c.flag}  ${c.name}'))],
            onChanged: (v) => setState(() {
              _countryId = v!;
              _regionId = null;
              _destinationId = null;
            }),
          ),
          const SizedBox(height: AppSpace.md),
          DropdownButtonFormField<String>(
            key: ValueKey('region-$_countryId'),
            initialValue: _regionId,
            isExpanded: true,
            decoration: InputDecoration(labelText: '${cat.country(_countryId)?.regionLabel ?? 'State'} *'),
            items: [
              for (final r in regions) DropdownMenuItem(value: r.id, child: Text(r.name)),
              const DropdownMenuItem(value: _other, child: Text('Other (type it)')),
            ],
            validator: (v) => v == null ? 'Choose one' : null,
            onChanged: (v) => setState(() {
              _regionId = v;
              _destinationId = v == _other ? _other : null;
            }),
          ),
          if (_regionId == _other) ...[
            const SizedBox(height: AppSpace.md),
            TextFormField(
              controller: _regionText,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'State / region name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the region' : null,
            ),
          ],
          const SizedBox(height: AppSpace.md),
          if (_regionId != _other)
            DropdownButtonFormField<String>(
              key: ValueKey('dest-$_regionId'),
              initialValue: _destinationId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'City / destination *'),
              items: [
                for (final d in dests) DropdownMenuItem(value: d.id, child: Text(d.name)),
                const DropdownMenuItem(value: _other, child: Text('Other (type it)')),
              ],
              validator: (v) => v == null ? 'Choose one' : null,
              onChanged: (v) => setState(() => _destinationId = v),
            ),
          if (_destinationId == _other) ...[
            const SizedBox(height: AppSpace.md),
            TextFormField(
              controller: _cityText,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'City / town name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the city' : null,
            ),
          ],
          const DetailHeading('Location'),
          TextFormField(
            controller: _mapLink,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Map link (optional)',
              hintText: 'Paste a Google Maps link',
              prefixIcon: Icon(Icons.map_rounded),
              helperText: 'Full Google Maps links also fill in the coordinates.',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final url = normaliseUrl(v);
              return url == null || !isMapLink(url) ? 'Paste a Google Maps / Apple Maps link' : null;
            },
            onChanged: _onMapLinkChanged,
          ),
          const SizedBox(height: AppSpace.md),
          OutlinedButton.icon(
            onPressed: () async {
              final p = await LocationPickerScreen.open(context, _defaultCenter(cat), hasPin: point != null);
              if (p != null) {
                setState(() {
                  _lat.text = p.lat.toStringAsFixed(6);
                  _lng.text = p.lng.toStringAsFixed(6);
                });
              }
            },
            icon: Icon(point == null ? Icons.add_location_alt_rounded : Icons.edit_location_alt_rounded),
            label: Text(point == null ? 'Drop a pin on the map' : 'Pinned — tap to adjust'),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: TextFormField(
                  controller: _lng,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const DetailHeading('Details'),
          if (_kind != PlaceKind.foodSpot) ...[
            Text('Category *', style: context.text.titleSmall),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in PlaceCategory.values.where((c) => c != PlaceCategory.food))
                  AppChip(
                    label: c.label,
                    icon: c.icon,
                    selected: _cats.contains(c),
                    onTap: () => setState(() => _cats.contains(c) ? _cats.remove(c) : _cats.add(c)),
                  ),
              ],
            ),
          ] else ...[
            Text('Food category', style: context.text.titleSmall),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in FoodCategory.values)
                  AppChip(
                    label: c.label,
                    icon: c.icon,
                    selected: _foodCats.contains(c),
                    onTap: () => setState(() => _foodCats.contains(c) ? _foodCats.remove(c) : _foodCats.add(c)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            TextFormField(
              controller: _dishes,
              decoration: const InputDecoration(labelText: 'Famous dishes', hintText: 'Comma separated'),
            ),
            const SizedBox(height: AppSpace.md),
            TextFormField(
              controller: _price,
              decoration: const InputDecoration(labelText: 'Price range (optional)', hintText: 'e.g. ₹–₹₹'),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          TextFormField(
            controller: _desc,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Description *', alignLabelWithHint: true),
            validator: (v) => (v == null || v.trim().length < 10) ? 'Add a short description (10+ characters)' : null,
          ),
          const SizedBox(height: AppSpace.md),
          TextFormField(
            controller: _best,
            decoration: const InputDecoration(
              labelText: 'Best time to visit',
              hintText: 'e.g. October – February, mornings',
            ),
          ),
          const SizedBox(height: AppSpace.md),
          TextFormField(
            controller: _hours,
            decoration: const InputDecoration(labelText: 'Recommended visiting hours', hintText: 'e.g. 6 am – 10 am'),
          ),
          const SizedBox(height: AppSpace.md),
          TextFormField(
            controller: _tips,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Travel tips',
              hintText: 'One tip per line',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          DropdownButtonFormField<EntryType>(
            initialValue: _entry,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Entry'),
            items: [
              for (final e in EntryType.values)
                DropdownMenuItem(
                  value: e,
                  child: Text(e.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _entry = v!),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _family,
            onChanged: (v) => setState(() => _family = v),
            title: const Text('Family friendly'),
          ),
          const DetailHeading('Instagram reels'),
          TextFormField(
            controller: _reels,
            keyboardType: TextInputType.url,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Reel links (optional)',
              hintText: 'https://www.instagram.com/reel/…',
              helperText: 'One link per line. They open in Instagram.',
              prefixIcon: Icon(Icons.play_circle_fill_rounded),
            ),
          ),
          if (ref.watch(visitForProvider(_editing?.id ?? '')) == null) ...[
            const DetailHeading('Your visit'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _beenHere,
              onChanged: (v) => setState(() => _beenHere = v),
              title: Text(_kind == PlaceKind.foodSpot ? "I've eaten here" : "I've already been here"),
              subtitle: const Text('Adds it to your travel history and stats'),
            ),
            if (_beenHere) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: const Text('Visited on'),
                subtitle: Text(formatDate(_visitDate)),
                trailing: const Icon(Icons.edit_calendar_rounded),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _visitDate,
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _visitDate = d);
                },
              ),
              Text('My rating', style: context.text.titleSmall),
              RatingStars(value: _rating, onChanged: (v) => setState(() => _rating = v), size: 32),
            ],
          ],
          const DetailHeading('Photos'),
          if (_photos.isNotEmpty) ...[
            PhotoGrid(
              photos: _photos,
              onRemove: (p) => setState(() {
                _photos = _photos.where((x) => x.id != p.id).toList();
                if (_added.any((a) => a.id == p.id)) {
                  _added.removeWhere((a) => a.id == p.id);
                  ref.read(photoStorageProvider).delete(p.path);
                } else {
                  _removed.add(p);
                }
              }),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          OutlinedButton.icon(
            onPressed: _pickPhotos,
            icon: const Icon(Icons.add_photo_alternate_rounded),
            label: const Text('Add photos from gallery'),
          ),
          const SizedBox(height: AppSpace.xl),
          FilledButton.icon(
            onPressed: _saving ? null : () => _save(cat),
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded),
            label: Text(_editing == null ? 'Save place' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}
