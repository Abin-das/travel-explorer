import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/common.dart';
import '../../domain/entities/user_activity.dart';

/// Create a trip, or edit its title / destination / dates / length.
class TripFormScreen extends ConsumerStatefulWidget {
  const TripFormScreen({super.key, this.tripId, this.destinationId});
  final String? tripId;
  final String? destinationId;

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _title = TextEditingController();
  String? _destId;
  DateTime _start = DateTime.now().add(const Duration(days: 7));
  int _days = 3;
  Trip? _existing;

  @override
  void initState() {
    super.initState();
    _destId = widget.destinationId;
    final t = widget.tripId == null ? null : ref.read(tripProvider(widget.tripId!));
    if (t != null) {
      _existing = t;
      _title.text = t.title;
      _destId = t.destinationId;
      _start = t.startDate;
      _days = t.days.length;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_destId == null) {
      showSnack(context, 'Choose a destination');
      return;
    }
    final cat = ref.read(catalogProvider).value;
    final name = _title.text.trim().isEmpty
        ? '${cat?.destination(_destId)?.name ?? 'My'} ${_days <= 3 ? 'Weekend' : ''} Trip'.replaceAll('  ', ' ')
        : _title.text.trim();
    final n = ref.read(tripsProvider.notifier);
    if (_existing == null) {
      final t = await n.create(title: name, destinationId: _destId!, start: _start, days: _days);
      if (mounted) context.pushReplacement(Routes.trip(t.id));
      return;
    }
    // Resize days; activities from removed days move to the new last day.
    var days = [..._existing!.days];
    if (_days > days.length) {
      days = [...days, for (var i = days.length; i < _days; i++) TripDay(id: uuid.v4(), activities: const [])];
    } else if (_days < days.length) {
      final overflow = days.sublist(_days).expand((d) => d.activities).toList();
      days = days.sublist(0, _days);
      days[_days - 1] = days[_days - 1].copyWith(activities: [...days[_days - 1].activities, ...overflow]);
    }
    await n.put(_existing!.copyWith(title: name, destinationId: _destId, startDate: _start, days: days));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final countryId = ref.watch(selectedCountryIdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_existing == null ? 'Plan a trip' : 'Edit trip')),
      body: AsyncView(
        value: ref.watch(catalogProvider),
        builder: (cat) {
          final dests = cat.destinationsIn(countryId: countryId);
          if (_destId != null && !dests.any((d) => d.id == _destId) && cat.destination(_destId) != null) {
            dests.insert(0, cat.destination(_destId)!);
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpace.gutter),
            children: [
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Trip name', hintText: 'Munnar Weekend Trip'),
              ),
              const SizedBox(height: AppSpace.md),
              DropdownButtonFormField<String>(
                initialValue: _destId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Destination'),
                items: [
                  for (final d in dests)
                    DropdownMenuItem(value: d.id, child: Text('${d.name} · ${cat.region(d.regionId)?.name ?? ''}')),
                ],
                onChanged: (v) => setState(() => _destId = v),
              ),
              if (_destId != null) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Recommended: ${cat.destination(_destId)?.recommendedDuration ?? '—'} · '
                  'best ${monthRange(cat.destination(_destId)?.season.bestMonths ?? const [])}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpace.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: const Text('Start date'),
                subtitle: Text(formatDate(_start)),
                trailing: const Icon(Icons.edit_calendar_rounded),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _start,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (d != null) setState(() => _start = d);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range_rounded),
                title: const Text('Duration'),
                subtitle: Text(
                  '${plural(_days, 'day')} · ends ${formatShortDate(_start.add(Duration(days: _days - 1)))}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Fewer days',
                      onPressed: _days > 1 ? () => setState(() => _days--) : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text('$_days'),
                    IconButton(
                      tooltip: 'More days',
                      onPressed: _days < 30 ? () => setState(() => _days++) : null,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(_existing == null ? 'Create trip' : 'Save changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}
