import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/service_listing_model.dart';

class ServiceListingRepository {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  ServiceListingRepository({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference get _col =>
      _db.collection(AppConstants.serviceListingsCol);

  // ── Create ────────────────────────────────────────────────────────────────
  Future<String> createListing(ServiceListingModel listing,
      {List<File> photos = const []}) async {
    final id = _uuid.v4();

    final urls = <String>[];
    for (final f in photos) {
      final ext = f.path.split('.').last;
      final ref = _storage
          .ref('${AppConstants.serviceListingPhotosPath}/$id/${_uuid.v4()}.$ext');
      final t = await ref.putFile(f);
      urls.add(await t.ref.getDownloadURL());
    }

    final now = DateTime.now();
    await _col.doc(id).set({
      ...listing
          .copyWith(id: id, photoUrls: urls, createdAt: now)
          .toJson(),
      'createdAt': Timestamp.fromDate(now),
    });
    return id;
  }

  // ── Read ──────────────────────────────────────────────────────────────────
  Stream<List<ServiceListingModel>> watchMyListings(String providerId) => _col
      .where('providerId', isEqualTo: providerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => ServiceListingModelExt.fromFirestore(d)).toList());

  Stream<List<ServiceListingModel>> watchActiveListings({
    String? categoryId,
    int limit = AppConstants.pageSize,
  }) {
    Query q = _col
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (categoryId != null) q = q.where('categoryId', isEqualTo: categoryId);
    return q.snapshots().map(
        (s) => s.docs.map((d) => ServiceListingModelExt.fromFirestore(d)).toList());
  }

  Stream<ServiceListingModel?> watchListing(String listingId) =>
      _col.doc(listingId).snapshots().map(
            (s) => s.exists ? ServiceListingModelExt.fromFirestore(s) : null,
          );

  // ── Upload photos ─────────────────────────────────────────────────────────
  Future<List<String>> uploadPhotos(String listingId, List<File> photos) async {
    final urls = <String>[];
    for (final f in photos) {
      final ext = f.path.split('.').last;
      final ref = _storage.ref(
          '${AppConstants.serviceListingPhotosPath}/$listingId/${_uuid.v4()}.$ext');
      final t = await ref.putFile(f);
      urls.add(await t.ref.getDownloadURL());
    }
    return urls;
  }

  // ── Update ────────────────────────────────────────────────────────────────
  Future<void> updateListing(String listingId, Map<String, dynamic> data) async {
    await _col.doc(listingId).update(data);
  }

  Future<void> toggleActive(String listingId, bool isActive) async {
    await _col.doc(listingId).update({'isActive': isActive});
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> deleteListing(String listingId) async {
    await _col.doc(listingId).delete();
  }
}

final serviceListingRepositoryProvider =
    Provider<ServiceListingRepository>((ref) => ServiceListingRepository());
