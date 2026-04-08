import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../domain/models/bid_model.dart';

class BidRepository {
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  BidRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference _bidsCol(String taskId) => _db
      .collection(AppConstants.tasksCol)
      .doc(taskId)
      .collection(AppConstants.bidsCol);

  // ── Helpers ───────────────────────────────────────────────────────────────
  static BidModel _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final json = <String, dynamic>{...data, 'bidId': doc.id};
    // Convert Firestore Timestamp → ISO-8601 string for json_serializable
    if (json['createdAt'] is Timestamp) {
      json['createdAt'] =
          (json['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    return BidModel.fromJson(json);
  }

  // ── Write ─────────────────────────────────────────────────────────────────
  /// Check if a provider already has a bid on a task.
  Future<bool> hasExistingBid(String taskId, String providerId) async {
    final snap = await _bidsCol(taskId)
        .where('providerId', isEqualTo: providerId)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Submit a bid and increment the task's bidCount.
  /// Throws if this provider already has a bid on this task.
  Future<String> submitBid(String taskId, BidModel bid) async {
    if (await hasExistingBid(taskId, bid.providerId)) {
      throw Exception('You have already submitted a bid for this task');
    }

    final id  = _uuid.v4();
    final now = DateTime.now();

    await _bidsCol(taskId).doc(id).set({
      ...bid.copyWith(bidId: id, taskId: taskId, createdAt: now).toJson(),
      'createdAt': Timestamp.fromDate(now), // override ISO string with Timestamp
    });

    // bidCount increment may fail if provider doesn't have task-level write
    // permission. This is non-critical — the bid itself was already created.
    try {
      await _db.collection(AppConstants.tasksCol).doc(taskId).update({
        'bidCount': FieldValue.increment(1),
      });
    } catch (_) {
      // Silently accept — a Cloud Function trigger on bid creation is the
      // proper long-term solution for maintaining bidCount.
    }

    return id;
  }

  // ── Read ──────────────────────────────────────────────────────────────────
  /// Real-time stream of all bids for a task, newest first.
  Stream<List<BidModel>> getBidsStream(String taskId) => _bidsCol(taskId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(_fromFirestore).toList());

  /// Real-time stream of all bids submitted by a provider.
  /// Uses collectionGroup query with fallback to empty list on error
  /// (index may not exist yet or collectionGroup rules may not apply).
  Stream<List<BidModel>> watchMyBids(String providerId) {
    try {
      return _db
          .collectionGroup(AppConstants.bidsCol)
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(_fromFirestore).toList())
          .handleError((_) => <BidModel>[]);
    } catch (_) {
      return Stream.value(<BidModel>[]);
    }
  }

  // ── Accept / Reject ───────────────────────────────────────────────────────
  /// Accept a bid: sets bid → accepted, all other pending bids → rejected,
  /// and updates the task status to assigned.
  Future<void> acceptBid(
    String taskId,
    String bidId,
    String providerId,
    String providerName,
  ) async {
    final batch    = _db.batch();
    final bidsSnap = await _bidsCol(taskId).get();

    for (final doc in bidsSnap.docs) {
      if (doc.id == bidId) {
        batch.update(doc.reference, {'status': BidStatus.accepted.name});
      } else {
        final data = doc.data() as Map<String, dynamic>;
        if (data['status'] == BidStatus.pending.name) {
          batch.update(doc.reference, {'status': BidStatus.rejected.name});
        }
      }
    }

    batch.update(
      _db.collection(AppConstants.tasksCol).doc(taskId),
      {
        'status':               TaskStatus.assigned.name,
        'assignedProviderId':   providerId,
        'assignedProviderName': providerName,
        'updatedAt':            Timestamp.now(),
      },
    );

    await batch.commit();
  }

  /// Reject a single bid without affecting the task.
  Future<void> rejectBid(String taskId, String bidId) async {
    await _bidsCol(taskId)
        .doc(bidId)
        .update({'status': BidStatus.rejected.name});
  }
}

final bidRepositoryProvider =
    Provider<BidRepository>((ref) => BidRepository());
