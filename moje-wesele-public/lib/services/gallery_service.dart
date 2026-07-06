import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/gallery_item.dart';

/// Dostęp do kolekcji `gallery` (osobna kolekcja Firestore — wspólna z
/// publiczną galerią gości). Panel organizatora może podglądać i usuwać wpisy.
class GalleryService {
  GalleryService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Strumień plików galerii (najnowsze pierwsze).
  Stream<List<GalleryItem>> watch() => _db
      .collection('gallery')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => GalleryItem({'id': d.id, ...d.data()}))
          .toList());

  /// Usuwa wpis z galerii (oryginał pozostaje w Cloudinary — jak w wersji web).
  Future<void> delete(String id) => _db.collection('gallery').doc(id).delete();
}
