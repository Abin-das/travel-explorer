import 'common.dart';

/// A remote, freely licensed photo with the attribution its licence requires.
class RemotePhoto {
  const RemotePhoto({required this.url, required this.author, required this.license, required this.sourceUrl});

  /// Full-size (≈1280 px) image URL.
  final String url;
  final String author;
  final String license;

  /// Page describing the file (author, licence terms).
  final String sourceUrl;

  /// A smaller rendition for cards and thumbnails, when the host supports it.
  String get thumbUrl => url.contains('/1280px-') ? url.replaceFirst('/1280px-', '/500px-') : url;

  String get credit => '$author · $license';

  Json toJson() => {'url': url, 'author': author, 'license': license, 'sourceUrl': sourceUrl};

  factory RemotePhoto.fromJson(Json j) => RemotePhoto(
    url: j['url'] as String,
    author: j['author'] as String? ?? '',
    license: j['license'] as String? ?? '',
    sourceUrl: j['sourceUrl'] as String? ?? '',
  );
}

/// Descriptive text quoted from an external source, kept with its citation.
class SourcedText {
  const SourcedText({
    required this.text,
    required this.history,
    required this.sourceTitle,
    required this.sourceUrl,
    this.sourceName = 'Wikipedia',
    this.license = 'CC BY-SA 4.0',
  });

  final String text;

  /// Short excerpt of the source's history section; empty if it has none.
  final String history;
  final String sourceTitle;
  final String sourceUrl;
  final String sourceName;
  final String license;
}

/// Photo + sourced description for one catalog entry.
class WikiEntry {
  const WikiEntry({required this.photo, required this.about});
  final RemotePhoto photo;
  final SourcedText about;
}
