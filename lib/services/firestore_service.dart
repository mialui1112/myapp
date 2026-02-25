import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/manga.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? getCurrentUserId() => _auth.currentUser?.uid;

  // FAVORITES SECTION

  Future<void> addFavorite(Map<String, dynamic> mangaData) async {
    final uid = getCurrentUserId();
    if (uid == null) return;
    final endpoint = mangaData['endpoint'];
    if (endpoint == null) return;

    final docRef = _db.collection('users').doc(uid).collection('favorites').doc(endpoint);
    await docRef.set({
      'name': mangaData['name'],
      'thumb_url': mangaData['thumb_url'],
      'endpoint': endpoint,
      'favoritedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String endpoint) async {
    final uid = getCurrentUserId();
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('favorites').doc(endpoint).delete();
  }

  Stream<bool> isFavoriteStream(String endpoint) {
    final uid = getCurrentUserId();
    if (uid == null) return Stream.value(false);
    return _db.collection('users').doc(uid).collection('favorites').doc(endpoint).snapshots().map((s) => s.exists);
  }

  Stream<List<Manga>> getFavorites() {
    final uid = getCurrentUserId();
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('favoritedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Manga.fromFirestore(doc.data())).toList());
  }

  Stream<QuerySnapshot> getFavoritesStream() {
    final uid = getCurrentUserId();
    if (uid == null) return Stream.empty();
    return _db.collection('users').doc(uid).collection('favorites').orderBy('favoritedAt', descending: true).snapshots();
  }

  // HISTORY SECTION

  Future<void> addToHistory({
    required Map<String, dynamic> mangaData,
    required String chapterId,
    required String chapterName,
  }) async {
    final uid = getCurrentUserId();
    if (uid == null) return;
    final endpoint = mangaData['endpoint'];
    if (endpoint == null) return;

    final docRef = _db.collection('users').doc(uid).collection('history').doc(endpoint);

    await docRef.set({
      'name': mangaData['name'],
      'thumb_url': mangaData['thumb_url'],
      'endpoint': endpoint,
      'last_read_chapter_id': chapterId,
      'last_read_chapter_name': chapterName,
      'last_read_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getHistoryStream() {
    final uid = getCurrentUserId();
    if (uid == null) return Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('history')
        .orderBy('last_read_at', descending: true)
        .snapshots();
  }

  // TOKEN MANAGEMENT

  Future<void> saveUserToken(String token, String userId) async {
    final tokenRef = _db.collection('users').doc(userId).collection('tokens').doc(token);
    await tokenRef.set({
      'createdAt': FieldValue.serverTimestamp(),
      'platform': 'mobile' // Or more specific platform info
    });
  }
}
