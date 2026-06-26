/// Element galerii z kolekcji `gallery` (osobna kolekcja Firestore).
/// Pola: `{uploadedBy, type('image'|'video'), url, fileSize, timestamp}`.
class GalleryItem {
  GalleryItem(this.raw);
  final Map<String, dynamic> raw;

  String get id => (raw['id'] as String?) ?? '';
  String get uploadedBy {
    final v = (raw['uploadedBy'] as String?)?.trim();
    return (v == null || v.isEmpty) ? 'Gość' : v;
  }

  String get type => (raw['type'] as String?) ?? 'image';
  bool get isVideo => type == 'video';
  String get url => (raw['url'] as String?) ?? '';
  int get fileSize => (raw['fileSize'] as num?)?.toInt() ?? 0;

  /// Znacznik czasu (ms) — obsługuje liczbę lub Firestore Timestamp.
  int get timestampMs {
    final t = raw['timestamp'];
    if (t is num) return t.toInt();
    // cloud_firestore Timestamp ma metodę millisecondsSinceEpoch przez toDate().
    try {
      final dyn = t as dynamic;
      final d = dyn.toDate();
      if (d is DateTime) return d.millisecondsSinceEpoch;
    } catch (_) {}
    return 0;
  }

  /// Miniatura (transformacja Cloudinary dla zdjęć; dla filmów — sam url).
  String get thumbUrl => isVideo
      ? url
      : _cld(url, 'c_fill,g_auto,w_400,h_400,f_auto,q_auto');

  /// Adres wymuszający pobranie pliku (Cloudinary fl_attachment).
  String get downloadUrl => _cld(url, 'fl_attachment');

  static String _cld(String url, String transform) {
    if (url.isEmpty || !url.contains('/upload/')) return url;
    return url.replaceFirst('/upload/', '/upload/$transform/');
  }
}
