import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/common.dart';
import '../../domain/entities/user_activity.dart';

/// Bottom sheet to mark (or edit) a visit: date + personal rating.
/// Returns true when the visit was saved.
Future<bool> showVisitSheet(
  BuildContext context,
  WidgetRef ref, {
  required String placeId,
  required String name,
}) async {
  final existing = ref.read(visitForProvider(placeId));
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _VisitSheet(placeId: placeId, name: name, existing: existing),
  );
  return saved ?? false;
}

class _VisitSheet extends ConsumerStatefulWidget {
  const _VisitSheet({required this.placeId, required this.name, this.existing});
  final String placeId;
  final String name;
  final Visit? existing;

  @override
  ConsumerState<_VisitSheet> createState() => _VisitSheetState();
}

class _VisitSheetState extends ConsumerState<_VisitSheet> {
  late DateTime _date = widget.existing?.visitedOn ?? DateTime.now();
  late int? _rating = widget.existing?.rating;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'When did you visit?',
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(editing ? 'Edit your visit' : 'Mark as visited', style: context.text.titleLarge),
            Text(widget.name, style: context.text.bodySmall),
            const SizedBox(height: AppSpace.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: const Text('Visited on'),
              subtitle: Text(formatDate(_date)),
              trailing: const Icon(Icons.edit_calendar_rounded),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpace.sm),
            Text('Your rating (private)', style: context.text.titleSmall),
            const SizedBox(height: 4),
            RatingStars(value: _rating, onChanged: (v) => setState(() => _rating = v), size: 34),
            const SizedBox(height: AppSpace.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_rounded),
                label: Text(editing ? 'Save changes' : 'Mark as visited'),
                onPressed: () async {
                  final n = ref.read(visitsProvider.notifier);
                  if (editing) {
                    await n.put(
                      widget.existing!.copyWith(visitedOn: _date, rating: _rating, clearRating: _rating == null),
                    );
                  } else {
                    await n.markVisited(SubjectType.place, widget.placeId, on: _date, rating: _rating);
                  }
                  if (context.mounted) Navigator.pop(context, true);
                },
              ),
            ),
            if (editing) ...[
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  label: const Text('Remove visited status'),
                  onPressed: () async {
                    final mems = ref.read(memoriesForPlaceProvider(widget.placeId)).length;
                    final ok = await confirmAction(
                      context,
                      title: 'Remove visit?',
                      message: mems == 0
                          ? 'This place will no longer count as visited.'
                          : 'This also deletes ${plural(mems, 'memory', 'memories')} and their photos for this place.',
                      confirmLabel: 'Remove',
                      destructive: true,
                    );
                    if (!ok) return;
                    await ref.read(visitsProvider.notifier).unmark(widget.placeId);
                    if (context.mounted) Navigator.pop(context, false);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for editing the personal note on a place.
Future<void> showNoteSheet(BuildContext context, WidgetRef ref, String placeId) async {
  final current = ref.read(noteForProvider(placeId))?.text ?? '';
  final controller = TextEditingController(text: current);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        MediaQuery.viewInsetsOf(ctx).bottom + AppSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal note', style: ctx.text.titleLarge),
          Text('Only stored on this device.', style: ctx.text.bodySmall),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Plans, impressions, tips for next time…'),
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              if (current.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await ref.read(notesProvider.notifier).setNote(placeId, '');
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Delete note'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await ref.read(notesProvider.notifier).setNote(placeId, controller.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save note'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  controller.dispose();
}

/// Brief full-screen checkmark celebration after marking a visit.
void showVisitedCelebration(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            onEnd: () => Future.delayed(const Duration(milliseconds: 500), () {
              if (entry.mounted) entry.remove();
            }),
            builder: (context, t, _) => Opacity(
              opacity: t.clamp(0, 1),
              child: Transform.scale(
                scale: 0.5 + t * 0.5,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    color: AppColors.visited,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.visited.withValues(alpha: 0.5), blurRadius: 40)],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 56),
                      Text(
                        'Visited!',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
}
