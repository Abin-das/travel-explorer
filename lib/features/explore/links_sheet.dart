import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/links.dart';
import '../../core/widgets/common.dart';
import '../../domain/entities/user_activity.dart';

/// Edit the user's map link and Instagram reels for a place.
Future<void> showLinksSheet(BuildContext context, String placeId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LinksSheet(placeId: placeId),
  );
}

class _LinksSheet extends ConsumerStatefulWidget {
  const _LinksSheet({required this.placeId});
  final String placeId;

  @override
  ConsumerState<_LinksSheet> createState() => _LinksSheetState();
}

class _LinksSheetState extends ConsumerState<_LinksSheet> {
  late final PlaceLinks _initial =
      ref.read(linksForProvider(widget.placeId)) ?? PlaceLinks(placeId: widget.placeId, updatedAt: DateTime.now());
  late final _map = TextEditingController(text: _initial.mapUrl ?? '');
  final _reel = TextEditingController();
  late List<String> _reels = [..._initial.reelUrls];
  String? _mapError;
  String? _reelError;

  @override
  void dispose() {
    _map.dispose();
    _reel.dispose();
    super.dispose();
  }

  void _addReel() {
    final url = normaliseUrl(_reel.text);
    setState(() {
      if (url == null || !isInstagramLink(url)) {
        _reelError = 'Paste an Instagram link (instagram.com/reel/…)';
        return;
      }
      _reelError = null;
      if (!_reels.contains(url)) _reels = [..._reels, url];
      _reel.clear();
    });
  }

  Future<void> _save() async {
    final raw = _map.text.trim();
    final mapUrl = raw.isEmpty ? null : normaliseUrl(raw);
    if (raw.isNotEmpty && (mapUrl == null || !isMapLink(mapUrl))) {
      setState(() => _mapError = 'Paste a Google Maps / Apple Maps link');
      return;
    }
    if (_reel.text.trim().isNotEmpty) {
      _addReel();
      if (_reelError != null) return;
    }
    await ref
        .read(linksProvider.notifier)
        .save(_initial.copyWith(mapUrl: mapUrl, clearMap: mapUrl == null, reelUrls: _reels));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        MediaQuery.viewInsetsOf(context).bottom + AppSpace.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Links', style: context.text.titleLarge),
            Text('Saved only on this device.', style: context.text.bodySmall),
            const SizedBox(height: AppSpace.lg),
            TextField(
              controller: _map,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'Map link',
                hintText: 'https://maps.app.goo.gl/…',
                prefixIcon: const Icon(Icons.map_rounded),
                errorText: _mapError,
              ),
              onChanged: (_) => setState(() => _mapError = null),
            ),
            const SizedBox(height: AppSpace.lg),
            Text('Instagram reels', style: context.text.titleSmall),
            const SizedBox(height: AppSpace.sm),
            for (final r in _reels)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.play_circle_fill_rounded),
                title: Text(reelLabel(r), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() => _reels = _reels.where((x) => x != r).toList()),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _reel,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: 'https://www.instagram.com/reel/…',
                      prefixIcon: const Icon(Icons.link_rounded),
                      errorText: _reelError,
                      errorMaxLines: 2,
                    ),
                    onSubmitted: (_) => _addReel(),
                    onChanged: (_) => setState(() => _reelError = null),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: IconButton.filledTonal(tooltip: 'Add reel', onPressed: _addReel, icon: const Icon(Icons.add)),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save links')),
            ),
          ],
        ),
      ),
    );
  }
}

/// "instagram.com/reel/C9x…" style label for a reel URL.
String reelLabel(String url) {
  final u = Uri.tryParse(url);
  if (u == null) return url;
  final path = u.pathSegments.where((s) => s.isNotEmpty).take(2).join('/');
  return '${u.host.replaceFirst('www.', '')}/$path';
}

/// Card listing the saved map link and reels, with an edit action.
class LinksCard extends ConsumerWidget {
  const LinksCard({super.key, required this.placeId});
  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(linksForProvider(placeId));
    final empty = links == null || links.isEmpty;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, color: context.colors.primary),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text('Links', style: context.text.titleMedium)),
              TextButton(onPressed: () => showLinksSheet(context, placeId), child: Text(empty ? 'Add' : 'Edit')),
            ],
          ),
          if (empty)
            Text('Save a Google Maps link and Instagram reels about this place.', style: context.text.bodySmall),
          if (links?.mapUrl != null)
            _LinkRow(
              icon: Icons.map_rounded,
              title: 'Open saved map link',
              subtitle: Uri.tryParse(links!.mapUrl!)?.host ?? '',
              onTap: () => openExternal(context, links.mapUrl!),
            ),
          for (final r in links?.reelUrls ?? const <String>[])
            _LinkRow(
              icon: Icons.play_circle_fill_rounded,
              title: 'Instagram reel',
              subtitle: reelLabel(r),
              onTap: () => openExternal(context, r),
            ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: context.colors.primaryContainer,
        child: Icon(icon, color: context.colors.primary, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      onTap: onTap,
    );
  }
}
