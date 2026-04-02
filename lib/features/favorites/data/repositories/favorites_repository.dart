import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the per-user favorites subcollection:
///   users/{uid}/favorites/{itemId}  →  { type: 'task'|'provider', addedAt }
class FavoritesRepository {
  final FirebaseFirestore _db;

  FavoritesRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference _col(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  /// Stream all favorite item IDs for a user, mapped by type.
  Stream<List<FavoriteItem>> watchFavorites(String uid) {
    return _col(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return FavoriteItem(
                itemId: doc.id,
                type: data['type'] as String? ?? 'task',
                addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
              );
            }).toList());
  }

  /// Add an item to favorites.
  Future<void> addFavorite(String uid, String itemId, String type) async {
    await _col(uid).doc(itemId).set({
      'type': type,
      'addedAt': Timestamp.now(),
    });
  }

  /// Remove an item from favorites.
  Future<void> removeFavorite(String uid, String itemId) async {
    await _col(uid).doc(itemId).delete();
  }
}

class FavoriteItem {
  final String itemId;
  final String type; // 'task' or 'provider'
  final DateTime? addedAt;

  const FavoriteItem({
    required this.itemId,
    required this.type,
    this.addedAt,
  });
}

final favoritesRepositoryProvider =
    Provider<FavoritesRepository>((ref) => FavoritesRepository());
