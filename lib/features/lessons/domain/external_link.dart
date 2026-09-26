/// Links to material hosted elsewhere (YouTube, Telegram, any website).
/// Only http(s) links are accepted, so a lesson can never launch
/// `javascript:`, `file:` or app-internal schemes. The database enforces the
/// same rule.
enum LinkProvider { youtube, telegram, web }

/// Parses what an admin typed or pasted. Adds `https://` when the scheme is
/// missing; returns null for anything that is not a plain web link.
Uri? parseExternalLink(String input) {
  var text = input.trim();
  if (text.isEmpty || RegExp(r'\s').hasMatch(text)) return null;
  if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(text)) {
    if (text.contains(':')) return null; // mailto:, javascript:, …
    text = 'https://$text';
  }
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !(uri.scheme == 'https' || uri.scheme == 'http') ||
      !uri.host.contains('.') ||
      text.length > 2000) {
    return null;
  }
  return uri;
}

LinkProvider linkProviderOf(Uri uri) {
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m)\.'), '');
  if (host == 'youtu.be' ||
      host == 'youtube.com' ||
      host == 'music.youtube.com' ||
      host == 'youtube-nocookie.com') {
    return LinkProvider.youtube;
  }
  if (host == 't.me' || host == 'telegram.me' || host == 'telegram.org') {
    return LinkProvider.telegram;
  }
  return LinkProvider.web;
}

/// The video id of a YouTube link, for its thumbnail; null otherwise.
String? youtubeVideoId(Uri uri) {
  if (linkProviderOf(uri) != LinkProvider.youtube) return null;
  final valid = RegExp(r'^[A-Za-z0-9_-]{11}$');
  String? id;
  if (uri.host.toLowerCase().endsWith('youtu.be')) {
    id = uri.pathSegments.firstOrNull;
  } else if (uri.queryParameters['v'] case final v?) {
    id = v;
  } else if (uri.pathSegments.length >= 2 &&
      const {'shorts', 'embed', 'live', 'v'}.contains(uri.pathSegments[0])) {
    id = uri.pathSegments[1];
  }
  return id != null && valid.hasMatch(id) ? id : null;
}

String? youtubeThumbnail(Uri uri) => switch (youtubeVideoId(uri)) {
  final id? => 'https://img.youtube.com/vi/$id/hqdefault.jpg',
  null => null,
};
