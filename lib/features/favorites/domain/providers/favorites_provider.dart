import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/repositories/favorites_repository.dart';

/// Streams the current user's favorite IDs so widgets can check membership.
final favoritesProvider = StreamProvider<List<FavoriteItem>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) return Stream.value([]);
  return ref.watch(favoritesRepositoryProvider).watchFavorites(uid);
});

/// Convenience — set of favorited item IDs for O(1) lookup.
final favoriteIdsProvider = Provider<Set<String>>((ref) {
  final items = ref.watch(favoritesProvider).valueOrNull ?? [];
  return items.map((e) => e.itemId).toSet();
});

/// Toggle helper — call from UI.
Future<void> toggleFavorite(
  WidgetRef ref, {
  required String itemId,
  required String type,
}) async {
  final uid = ref.read(currentUserProvider).valueOrNull?.uid;
  if (uid == null) return;
  final repo = ref.read(favoritesRepositoryProvider);
  final isFav = ref.read(favoriteIdsProvider).contains(itemId);
  if (isFav) {
    await repo.removeFavorite(uid, itemId);
  } else {
    await repo.addFavorite(uid, itemId, type);
  }
}
