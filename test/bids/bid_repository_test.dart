import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/bids/data/repositories/bid_repository.dart';
import 'package:neighbourgo/features/bids/domain/models/bid_model.dart';
import 'package:neighbourgo/features/tasks/data/models/task_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Firestore fakes — extended to support subcollections, batch, and .get()
// ─────────────────────────────────────────────────────────────────────────────

class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final bool _exists;
  final Map<String, dynamic>? _data;

  FakeDocumentSnapshot(
      {required this.id, bool exists = true, Map<String, dynamic>? data})
      : _exists = exists,
        _data = data;

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;
}

class FakeQueryDocumentSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic> _data;
  @override
  final DocumentReference<Map<String, dynamic>> reference;

  FakeQueryDocumentSnapshot({
    required this.id,
    required Map<String, dynamic> data,
    required this.reference,
  }) : _data = data;

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => _data;
}

class FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  FakeQuerySnapshot({required this.docs});
}

class FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final List<Map<String, dynamic>> _results;
  final FakeCollectionReference? _parent;
  String? lastOrderByField;
  bool? lastDescending;
  // where filters
  final List<_WhereClause> _whereClauses;

  FakeQuery(this._results, {FakeCollectionReference? parent, List<_WhereClause>? whereClauses})
      : _parent = parent,
        _whereClauses = whereClauses ?? [];

  List<Map<String, dynamic>> get _filteredResults {
    if (_whereClauses.isEmpty) return _results;
    return _results.where((data) {
      return _whereClauses.every((clause) => data[clause.field] == clause.value);
    }).toList();
  }

  @override
  Query<Map<String, dynamic>> where(Object field,
      {Object? isEqualTo,
      Object? isNotEqualTo,
      Object? isLessThan,
      Object? isLessThanOrEqualTo,
      Object? isGreaterThan,
      Object? isGreaterThanOrEqualTo,
      Object? arrayContains,
      Iterable<Object?>? arrayContainsAny,
      Iterable<Object?>? whereIn,
      Iterable<Object?>? whereNotIn,
      bool? isNull}) {
    final clauses = [..._whereClauses, _WhereClause(field as String, isEqualTo)];
    return FakeQuery(_results, parent: _parent, whereClauses: clauses);
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field,
      {bool descending = false}) {
    lastOrderByField = field as String;
    lastDescending = descending;
    return this;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots(
      {bool includeMetadataChanges = false,
      ListenSource source = ListenSource.defaultSource}) {
    final parent = _parent;
    final docs = _filteredResults.map((data) {
      final docId = data['bidId'] as String? ?? data['id'] as String? ?? 'doc-id';
      final ref = parent != null
          ? parent.docs.putIfAbsent(docId, () => FakeDocumentReference(id: docId, data: data, exists: true))
          : FakeDocumentReference(id: docId, data: data, exists: true);
      return FakeQueryDocumentSnapshot(id: docId, data: data, reference: ref);
    }).toList();
    return Stream.value(FakeQuerySnapshot(docs: docs));
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get(
      [GetOptions? options]) async {
    final parent = _parent;
    final docs = _filteredResults.map((data) {
      final docId = data['bidId'] as String? ?? data['id'] as String? ?? 'doc-id';
      final ref = parent != null
          ? parent.docs.putIfAbsent(docId, () => FakeDocumentReference(id: docId, data: data, exists: true))
          : FakeDocumentReference(id: docId, data: data, exists: true);
      return FakeQueryDocumentSnapshot(id: docId, data: data, reference: ref);
    }).toList();
    return FakeQuerySnapshot(docs: docs);
  }
}

class _WhereClause {
  final String field;
  final Object? value;
  _WhereClause(this.field, this.value);
}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  @override
  final String id;
  Map<String, dynamic>? _storedData;
  bool _exists;

  Map<String, dynamic>? lastSetData;
  Map<Object, Object?>? lastUpdateData;

  // Subcollections
  final Map<String, FakeCollectionReference> _subcollections = {};

  FakeDocumentReference(
      {required this.id, Map<String, dynamic>? data, bool exists = false})
      : _storedData = data,
        _exists = exists;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
      [GetOptions? options]) async {
    return FakeDocumentSnapshot(id: id, exists: _exists, data: _storedData);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    lastSetData = data;
    _storedData = data;
    _exists = true;
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    lastUpdateData = data;
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _subcollections.putIfAbsent(
        path, () => FakeCollectionReference());
  }

  FakeCollectionReference getSubcollection(String path) {
    return _subcollections.putIfAbsent(
        path, () => FakeCollectionReference());
  }

  void setSubcollection(String path, FakeCollectionReference col) {
    _subcollections[path] = col;
  }
}

class FakeCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Map<String, FakeDocumentReference> docs = {};
  late final FakeQuery _query;

  FakeCollectionReference({List<Map<String, dynamic>> queryResults = const []}) {
    _query = FakeQuery(queryResults, parent: this);
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    if (path == null) return FakeDocumentReference(id: 'auto-id');
    return docs.putIfAbsent(path, () => FakeDocumentReference(id: path));
  }

  void addDoc(String id,
      {Map<String, dynamic>? data, bool exists = false}) {
    docs[id] = FakeDocumentReference(id: id, data: data, exists: exists);
  }

  @override
  Query<Map<String, dynamic>> where(Object field,
      {Object? isEqualTo,
      Object? isNotEqualTo,
      Object? isLessThan,
      Object? isLessThanOrEqualTo,
      Object? isGreaterThan,
      Object? isGreaterThanOrEqualTo,
      Object? arrayContains,
      Iterable<Object?>? arrayContainsAny,
      Iterable<Object?>? whereIn,
      Iterable<Object?>? whereNotIn,
      bool? isNull}) {
    return _query.where(field, isEqualTo: isEqualTo);
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field,
      {bool descending = false}) {
    return _query.orderBy(field, descending: descending);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots(
      {bool includeMetadataChanges = false,
      ListenSource source = ListenSource.defaultSource}) {
    return _query.snapshots();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get(
      [GetOptions? options]) async {
    return _query.get();
  }

  FakeQuery get query => _query;
}

// Batch fake that records all updates
class FakeBatchUpdate {
  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, Object?> data;
  FakeBatchUpdate(this.ref, this.data);
}

class FakeWriteBatch extends Fake implements WriteBatch {
  final List<FakeBatchUpdate> updates = [];
  bool committed = false;

  @override
  void update(DocumentReference<Object?> document, Map<String, Object?> data) {
    updates.add(FakeBatchUpdate(
        document as DocumentReference<Map<String, dynamic>>, data));
  }

  @override
  Future<void> commit() async {
    committed = true;
    // Apply updates to fake doc references
    for (final u in updates) {
      if (u.ref is FakeDocumentReference) {
        (u.ref as FakeDocumentReference).lastUpdateData = u.data;
      }
    }
  }
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, FakeCollectionReference> _collections = {};
  FakeWriteBatch? lastBatch;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _collections.putIfAbsent(path, () => FakeCollectionReference());
  }

  FakeCollectionReference getCollection(String path) {
    return _collections.putIfAbsent(path, () => FakeCollectionReference());
  }

  void setCollection(String path, FakeCollectionReference col) {
    _collections[path] = col;
  }

  @override
  WriteBatch batch() {
    lastBatch = FakeWriteBatch();
    return lastBatch!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('BidRepository', () {
    group('submitBid', () {
      test('writes bid doc to tasks/{taskId}/bids subcollection', () async {
        final db = FakeFirebaseFirestore();
        // Pre-create task doc so incrementViewCount update works
        db.getCollection('tasks').addDoc('task-1', exists: true);
        final repo = BidRepository(db: db);

        const bid = BidModel(
          bidId: '',
          taskId: 'task-1',
          providerId: 'provider-1',
          providerName: 'Jane Provider',
          amount: 50.0,
          message: 'I can do this',
        );

        final bidId = await repo.submitBid('task-1', bid);

        expect(bidId, isNotEmpty);
        // Verify bid was written to subcollection
        final taskDoc = db.getCollection('tasks').docs['task-1']!;
        final bidsCol = taskDoc.getSubcollection('bids');
        final bidDoc = bidsCol.docs[bidId];
        expect(bidDoc, isNotNull);
        expect(bidDoc!.lastSetData, isNotNull);
        expect(bidDoc.lastSetData!['providerId'], 'provider-1');
        expect(bidDoc.lastSetData!['providerName'], 'Jane Provider');
        expect(bidDoc.lastSetData!['amount'], 50.0);
        expect(bidDoc.lastSetData!['message'], 'I can do this');
        expect(bidDoc.lastSetData!['createdAt'], isA<Timestamp>());
      });

      test('increments task bidCount', () async {
        final db = FakeFirebaseFirestore();
        db.getCollection('tasks').addDoc('task-1', exists: true);
        final repo = BidRepository(db: db);

        const bid = BidModel(
          bidId: '',
          taskId: 'task-1',
          providerId: 'provider-1',
          providerName: 'Jane',
          amount: 30.0,
        );

        await repo.submitBid('task-1', bid);

        final taskDoc = db.getCollection('tasks').docs['task-1']!;
        expect(taskDoc.lastUpdateData, isNotNull);
        expect(taskDoc.lastUpdateData!['bidCount'], isA<FieldValue>());
      });
    });

    group('getBidsStream', () {
      test('returns Stream<List<BidModel>> ordered by createdAt', () async {
        final db = FakeFirebaseFirestore();
        final now = DateTime.now();

        // Set up bids subcollection with query results
        final bidData1 = {
          'bidId': 'bid-1',
          'taskId': 'task-1',
          'providerId': 'prov-1',
          'providerName': 'Alice',
          'amount': 40.0,
          'status': 'pending',
          'createdAt': now.toIso8601String(),
        };
        final bidData2 = {
          'bidId': 'bid-2',
          'taskId': 'task-1',
          'providerId': 'prov-2',
          'providerName': 'Bob',
          'amount': 55.0,
          'status': 'pending',
          'createdAt': now.toIso8601String(),
        };

        // Create the subcollection with query results
        final bidsCol =
            FakeCollectionReference(queryResults: [bidData1, bidData2]);
        final taskDocRef =
            FakeDocumentReference(id: 'task-1', exists: true);
        taskDocRef.setSubcollection('bids', bidsCol);

        // Wire into Firestore: tasks collection with the task doc
        final tasksCol = FakeCollectionReference();
        tasksCol.docs['task-1'] = taskDocRef;
        db.setCollection('tasks', tasksCol);

        final repo = BidRepository(db: db);
        final bids = await repo.getBidsStream('task-1').first;

        expect(bids, isA<List<BidModel>>());
        expect(bids.length, 2);
        expect(bids[0].providerName, 'Alice');
        expect(bids[1].providerName, 'Bob');

        // Verify orderBy was called
        expect(bidsCol.query.lastOrderByField, 'createdAt');
        expect(bidsCol.query.lastDescending, true);
      });
    });

    group('acceptBid', () {
      test('sets bid status=accepted, rejects other pending bids', () async {
        final db = FakeFirebaseFirestore();

        // Set up bids subcollection with existing bids for .get()
        final bidsCol = FakeCollectionReference(queryResults: [
          {
            'bidId': 'bid-1',
            'taskId': 'task-1',
            'providerId': 'prov-1',
            'providerName': 'Alice',
            'amount': 40.0,
            'status': 'pending',
          },
          {
            'bidId': 'bid-2',
            'taskId': 'task-1',
            'providerId': 'prov-2',
            'providerName': 'Bob',
            'amount': 55.0,
            'status': 'pending',
          },
          {
            'bidId': 'bid-3',
            'taskId': 'task-1',
            'providerId': 'prov-3',
            'providerName': 'Charlie',
            'amount': 60.0,
            'status': 'rejected', // already rejected, should not be touched
          },
        ]);

        final taskDocRef = FakeDocumentReference(id: 'task-1', exists: true);
        taskDocRef.setSubcollection('bids', bidsCol);

        final tasksCol = FakeCollectionReference();
        tasksCol.docs['task-1'] = taskDocRef;
        db.setCollection('tasks', tasksCol);

        final repo = BidRepository(db: db);
        await repo.acceptBid('task-1', 'bid-1', 'prov-1', 'Alice');

        final batch = db.lastBatch!;
        expect(batch.committed, true);

        // Find updates by looking at the batch
        final bidUpdates = batch.updates
            .where((u) => u.ref is FakeDocumentReference)
            .toList();

        // Should have updates for: bid-1 (accepted), bid-2 (rejected pending),
        // and the task doc (assigned)
        // bid-3 was already rejected, so no update for it
        expect(bidUpdates.length, greaterThanOrEqualTo(3));

        // Check accepted bid
        final acceptedUpdate =
            bidUpdates.where((u) => u.data['status'] == 'accepted').toList();
        expect(acceptedUpdate.length, 1);

        // Check rejected bid (only bid-2 is pending, bid-3 was already rejected)
        final rejectedUpdates =
            bidUpdates.where((u) => u.data['status'] == 'rejected').toList();
        expect(rejectedUpdates.length, 1); // only bid-2

        // Check task update
        final taskUpdate = bidUpdates
            .where((u) => u.data.containsKey('assignedProviderId'))
            .toList();
        expect(taskUpdate.length, 1);
        expect(taskUpdate.first.data['status'], TaskStatus.assigned.name);
        expect(taskUpdate.first.data['assignedProviderId'], 'prov-1');
        expect(taskUpdate.first.data['assignedProviderName'], 'Alice');
        expect(taskUpdate.first.data['updatedAt'], isA<Timestamp>());
      });

      test('updates task status to assigned with provider details', () async {
        final db = FakeFirebaseFirestore();

        final bidsCol = FakeCollectionReference(queryResults: [
          {
            'bidId': 'bid-1',
            'taskId': 'task-1',
            'providerId': 'prov-1',
            'providerName': 'Alice',
            'amount': 40.0,
            'status': 'pending',
          },
        ]);

        final taskDocRef = FakeDocumentReference(id: 'task-1', exists: true);
        taskDocRef.setSubcollection('bids', bidsCol);

        final tasksCol = FakeCollectionReference();
        tasksCol.docs['task-1'] = taskDocRef;
        db.setCollection('tasks', tasksCol);

        final repo = BidRepository(db: db);
        await repo.acceptBid('task-1', 'bid-1', 'prov-1', 'Alice');

        final batch = db.lastBatch!;
        expect(batch.committed, true);

        // Find the task update in batch
        final taskUpdate = batch.updates
            .where((u) => u.data.containsKey('assignedProviderId'))
            .first;
        expect(taskUpdate.data['status'], 'assigned');
        expect(taskUpdate.data['assignedProviderId'], 'prov-1');
        expect(taskUpdate.data['assignedProviderName'], 'Alice');
      });
    });

    group('rejectBid', () {
      test('sets bid status=rejected', () async {
        final db = FakeFirebaseFirestore();

        // Create task doc with bids subcollection
        final taskDocRef = FakeDocumentReference(id: 'task-1', exists: true);
        final bidsCol = FakeCollectionReference();
        bidsCol.addDoc('bid-1', exists: true);
        taskDocRef.setSubcollection('bids', bidsCol);

        final tasksCol = FakeCollectionReference();
        tasksCol.docs['task-1'] = taskDocRef;
        db.setCollection('tasks', tasksCol);

        final repo = BidRepository(db: db);
        await repo.rejectBid('task-1', 'bid-1');

        final bidDoc = bidsCol.docs['bid-1']!;
        expect(bidDoc.lastUpdateData, isNotNull);
        expect(bidDoc.lastUpdateData!['status'], 'rejected');
      });
    });

    group('bid status validation', () {
      test('acceptBid does not reject already-rejected bids', () async {
        final db = FakeFirebaseFirestore();

        final bidsCol = FakeCollectionReference(queryResults: [
          {
            'bidId': 'bid-accept',
            'taskId': 'task-1',
            'providerId': 'prov-1',
            'providerName': 'Alice',
            'amount': 40.0,
            'status': 'pending',
          },
          {
            'bidId': 'bid-already-rejected',
            'taskId': 'task-1',
            'providerId': 'prov-2',
            'providerName': 'Bob',
            'amount': 50.0,
            'status': 'rejected',
          },
        ]);

        final taskDocRef = FakeDocumentReference(id: 'task-1', exists: true);
        taskDocRef.setSubcollection('bids', bidsCol);

        final tasksCol = FakeCollectionReference();
        tasksCol.docs['task-1'] = taskDocRef;
        db.setCollection('tasks', tasksCol);

        final repo = BidRepository(db: db);
        await repo.acceptBid(
            'task-1', 'bid-accept', 'prov-1', 'Alice');

        final batch = db.lastBatch!;

        // The already-rejected bid should NOT receive another rejection update
        // Only bid-accept gets status update + task doc update
        final rejectedUpdates = batch.updates
            .where((u) => u.data['status'] == 'rejected')
            .toList();
        expect(rejectedUpdates, isEmpty,
            reason:
                'Already-rejected bids should not be updated again');
      });

      test('BidStatus enum has correct values', () {
        expect(BidStatus.values.length, 3);
        expect(BidStatus.pending.name, 'pending');
        expect(BidStatus.accepted.name, 'accepted');
        expect(BidStatus.rejected.name, 'rejected');
      });

      test('BidModel defaults status to pending', () {
        const bid = BidModel(
          bidId: 'b1',
          taskId: 't1',
          providerId: 'p1',
          providerName: 'Test',
          amount: 25.0,
        );
        expect(bid.status, BidStatus.pending);
      });
    });

    group('duplicate bid prevention', () {
      test('submitBid throws if provider already has a bid on the task', () async {
        final db = FakeFirebaseFirestore();

        // Set up bids subcollection with existing bid from provider-1
        final bidsCol = FakeCollectionReference(queryResults: [
          {
            'bidId': 'existing-bid',
            'taskId': 'task-1',
            'providerId': 'provider-1',
            'providerName': 'Jane',
            'amount': 50.0,
            'status': 'pending',
            'createdAt': DateTime.now().toIso8601String(),
          },
        ]);

        final taskDocRef = FakeDocumentReference(id: 'task-1', exists: true);
        taskDocRef.setSubcollection('bids', bidsCol);

        final tasksCol = FakeCollectionReference();
        tasksCol.docs['task-1'] = taskDocRef;
        db.setCollection('tasks', tasksCol);

        final repo = BidRepository(db: db);

        const duplicateBid = BidModel(
          bidId: '',
          taskId: 'task-1',
          providerId: 'provider-1',
          providerName: 'Jane',
          amount: 60.0,
          message: 'Second bid attempt',
        );

        expect(
          () => repo.submitBid('task-1', duplicateBid),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('already submitted a bid'),
          )),
        );
      });

      test('submitBid succeeds when a different provider bids', () async {
        final db = FakeFirebaseFirestore();

        // Existing bid from provider-1
        final bidsCol = FakeCollectionReference(queryResults: [
          {
            'bidId': 'existing-bid',
            'taskId': 'task-1',
            'providerId': 'provider-1',
            'providerName': 'Jane',
            'amount': 50.0,
            'status': 'pending',
            'createdAt': DateTime.now().toIso8601String(),
          },
        ]);

        final taskDocRef = FakeDocumentReference(id: 'task-1', exists: true);
        taskDocRef.setSubcollection('bids', bidsCol);

        final tasksCol = FakeCollectionReference();
        tasksCol.docs['task-1'] = taskDocRef;
        db.setCollection('tasks', tasksCol);

        final repo = BidRepository(db: db);

        // Different provider submits — should succeed
        const newBid = BidModel(
          bidId: '',
          taskId: 'task-1',
          providerId: 'provider-2',
          providerName: 'Bob',
          amount: 45.0,
          message: 'I can help!',
        );

        final bidId = await repo.submitBid('task-1', newBid);
        expect(bidId, isNotEmpty);
      });

      test('hasExistingBid returns true when bid exists', () async {
        final db = FakeFirebaseFirestore();

        final bidsCol = FakeCollectionReference(queryResults: [
          {
            'bidId': 'bid-1',
            'taskId': 'task-1',
            'providerId': 'provider-1',
            'providerName': 'Jane',
            'amount': 50.0,
            'status': 'pending',
          },
        ]);

        final taskDocRef = FakeDocumentReference(id: 'task-1', exists: true);
        taskDocRef.setSubcollection('bids', bidsCol);

        final tasksCol = FakeCollectionReference();
        tasksCol.docs['task-1'] = taskDocRef;
        db.setCollection('tasks', tasksCol);

        final repo = BidRepository(db: db);

        expect(await repo.hasExistingBid('task-1', 'provider-1'), true);
        expect(await repo.hasExistingBid('task-1', 'provider-999'), false);
      });
    });
  });
}
