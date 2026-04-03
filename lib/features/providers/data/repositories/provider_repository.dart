import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/data/models/user_model.dart';

class ProviderRepository {
  final FirebaseFirestore _db;

  ProviderRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection(AppConstants.usersCol);

  /// Query users who are providers (role = provider or both),
  /// optionally filtered by category via serviceCategories array-contains.
  Stream<List<UserModel>> watchProviders({
    String? categoryId,
    int limit = AppConstants.pageSize,
  }) {
    // Firestore doesn't support whereIn + arrayContains + orderBy together.
    // Fetch all providers, filter by category client-side.
    Query q = _col
        .where('role', whereIn: [UserRole.provider.name, UserRole.both.name])
        .orderBy('lastActiveAt', descending: true)
        .limit(limit);

    return q.snapshots().map((snap) {
      var providers = snap.docs.map((d) => UserModelExt.fromFirestore(d)).toList();
      if (categoryId != null) {
        providers = providers.where((p) => p.serviceCategories.contains(categoryId)).toList();
      }
      return providers;
    });
  }
}

final providerRepositoryProvider =
    Provider<ProviderRepository>((ref) => ProviderRepository());
