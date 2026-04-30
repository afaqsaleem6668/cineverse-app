import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  // ── Favorites ──────────────────────────────────────────────────────────────

  static Future<void> addFavorite(Map<String, dynamic> item) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc('${item['media_type']}_${item['id']}')
        .set({
      ...item,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeFavorite(String mediaType, int id) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc('${mediaType}_$id')
        .delete();
  }

  static Stream<bool> isFavoriteStream(String mediaType, int id) {
    if (_uid == null) return Stream.value(false);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc('${mediaType}_$id')
        .snapshots()
        .map((doc) => doc.exists);
  }

  static Stream<QuerySnapshot> favoritesStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // ── Watchlist ──────────────────────────────────────────────────────────────

  static Future<void> addToWatchlist(Map<String, dynamic> item) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('watchlist')
        .doc('${item['media_type']}_${item['id']}')
        .set({
      ...item,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeFromWatchlist(String mediaType, int id) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('watchlist')
        .doc('${mediaType}_$id')
        .delete();
  }

  static Stream<bool> isInWatchlistStream(String mediaType, int id) {
    if (_uid == null) return Stream.value(false);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('watchlist')
        .doc('${mediaType}_$id')
        .snapshots()
        .map((doc) => doc.exists);
  }

  static Stream<QuerySnapshot> watchlistStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(_uid)
        .collection('watchlist')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // ── Reviews count ──────────────────────────────────────────────────────────

  static Stream<int> reviewsCountStream() {
    if (_uid == null) return Stream.value(0);
    final email = _auth.currentUser?.email ?? '';
    return _db
        .collection('reviews')
        .where('userId', isEqualTo: email)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
