import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/geography.dart';
import '../../domain/entities/media.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/user_activity.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/labels.dart';
import '../utils/links.dart';
import 'scene_art.dart';

/// Prefix marking an [Place.imageUrls] entry as an on-device photo
/// (user submissions) rather than a network URL.
const localImagePrefix = 'local:';

/// Photos attached to a user-submitted place, as [TravelPhoto]s for galleries.
List<TravelPhoto> submissionPhotos(Place p) => [
  for (final u in p.imageUrls.where((u) => u.startsWith(localImagePrefix)))
    TravelPhoto(id: u, path: u.substring(localImagePrefix.length), addedAt: p.submission?.createdAt ?? DateTime.now()),
];

/// Image from the app's private photo directory. Handles missing files.
class LocalPhoto extends ConsumerWidget {
  const LocalPhoto({super.key, required this.path, this.fit = BoxFit.cover, this.cacheWidth = 900});

  final String path;
  final BoxFit fit;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(photoStorageProvider).resolve(path);
    if (file == null) return const MissingPhoto();
    return Image.file(
      file,
      fit: fit,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const MissingPhoto(),
    );
  }
}

class MissingPhoto extends StatelessWidget {
  const MissingPhoto({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.chip,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported_rounded, color: context.palette.muted),
              const SizedBox(height: 4),
              Text('Photo unavailable', style: context.text.labelSmall?.copyWith(color: context.palette.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wikimedia asks API/image clients to identify themselves.
const _imageHeaders = {'User-Agent': 'TravelExplorer/1.0 (Flutter; travel guide app)'};

/// A cached network photo that falls back to [fallback] while loading or offline.
class RemoteImage extends ConsumerWidget {
  const RemoteImage({super.key, required this.url, required this.fallback, this.fit = BoxFit.cover});

  final String url;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(remoteImagesEnabledProvider)) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: _imageHeaders,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

/// Cover for a place, in priority order: the user's own photo, a licensed
/// catalog photo, a photo attached to a user submission, generated artwork.
class PlaceCover extends ConsumerWidget {
  const PlaceCover({super.key, required this.place, this.heroTag, this.thumbnail = true});

  final Place place;
  final String? heroTag;

  /// Use a smaller rendition (cards, tiles). Detail headers pass false.
  final bool thumbnail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(coverPhotoForProvider(place.id));
    final art = SceneArt(theme: sceneForPlace(place), seed: place.id);
    Widget child;
    if (photo != null) {
      child = LocalPhoto(path: photo.path, cacheWidth: thumbnail ? 600 : 1400);
    } else if (place.photo != null) {
      child = RemoteImage(url: thumbnail ? place.photo!.thumbUrl : place.photo!.url, fallback: art);
    } else if (place.imageUrls.isNotEmpty && place.imageUrls.first.startsWith(localImagePrefix)) {
      child = LocalPhoto(path: place.imageUrls.first.substring(localImagePrefix.length));
    } else if (place.imageUrls.isNotEmpty) {
      child = RemoteImage(url: place.imageUrls.first, fallback: art);
    } else {
      child = art;
    }
    child = SizedBox.expand(child: child);
    return heroTag == null ? child : Hero(tag: heroTag!, child: child);
  }
}

class DestinationCover extends ConsumerWidget {
  const DestinationCover({super.key, required this.destination, this.heroTag, this.thumbnail = true});

  final Destination destination;
  final String? heroTag;
  final bool thumbnail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final art = SceneArt(theme: destination.theme, seed: destination.id);
    final photo = destination.photo;
    Widget child = photo != null
        ? RemoteImage(url: thumbnail ? photo.thumbUrl : photo.url, fallback: art)
        : destination.imageUrl != null
        ? RemoteImage(url: destination.imageUrl!, fallback: art)
        : art;
    child = SizedBox.expand(child: child);
    return heroTag == null ? child : Hero(tag: heroTag!, child: child);
  }
}

/// Licence attribution for a photo; tapping opens the file's source page.
class PhotoCredit extends StatelessWidget {
  const PhotoCredit({super.key, required this.photo});
  final RemotePhoto photo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Photo by ${photo.author}, ${photo.license}. Open source page.',
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => openExternal(context, photo.sourceUrl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_camera_outlined, size: 11, color: Colors.white70),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    photo.credit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark gradient at the bottom of an image so overlaid text stays legible.
class BottomScrim extends StatelessWidget {
  const BottomScrim({super.key, this.strength = 0.75});
  final double strength;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.35, 1],
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: strength),
          ],
        ),
      ),
    );
  }
}

/// Grid of local photos; tapping opens the full-screen viewer.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({super.key, required this.photos, this.onRemove, this.crossAxisCount = 3});

  final List<TravelPhoto> photos;
  final ValueChanged<TravelPhoto>? onRemove;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: photos.length,
      itemBuilder: (context, i) {
        final p = photos[i];
        return ClipRRect(
          borderRadius: AppRadius.smAll,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () => PhotoViewer.open(context, photos, i),
                child: Hero(
                  tag: 'photo-${p.id}',
                  child: LocalPhoto(path: p.path, cacheWidth: 400),
                ),
              ),
              if (onRemove != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onRemove!(p),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, size: 16, color: Colors.white, semanticLabel: 'Remove photo'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.photos, required this.initial});

  final List<TravelPhoto> photos;
  final int initial;

  static void open(BuildContext context, List<TravelPhoto> photos, int index) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => PhotoViewer(photos: photos, initial: index),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _pc = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.photos.length}', style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Hero(
              tag: 'photo-${widget.photos[i].id}',
              child: LocalPhoto(path: widget.photos[i].path, fit: BoxFit.contain, cacheWidth: null),
            ),
          ),
        ),
      ),
    );
  }
}
