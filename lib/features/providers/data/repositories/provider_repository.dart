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
    Query q = _col
        .where('role', whereIn: [UserRole.provider.name, UserRole.both.name])
        .orderBy('lastActiveAt', descending: true)
        .limit(limit);

    if (categoryId != null) {
      q = q.where('serviceCategories', arrayContains: categoryId);
    }

    return q.snapshots().map(
      (snap) => snap.docs.map((d) => UserModelExt.fromFirestore(d)).toList(),
    );
  }
}

final providerRepositoryProvider =
    Provider<ProviderRepository>((ref) => ProviderRepository());
