import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/image_validator.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _db;
  final FirebaseStorage   _storage;
  final _uuid = const Uuid();

  TaskRepository({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db      = db      ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference get _col => _db.collection(AppConstants.tasksCol);

  // ── Create ────────────────────────────────────────────────────────────────
  Future<String> createTask(TaskModel task, {List<File> photos = const []}) async {
    // Validate all photos before uploading
    for (final f in photos) {
      final error = ImageValidator.validate(f);
      if (error != null) throw Exception(error);
    }

    final id = _uuid.v4();

    // Upload photos
    final urls = <String>[];
    for (final f in photos) {
      final ext = f.path.split('.').last;
      final ref = _storage.ref('${AppConstants.taskPhotosPath}/$id/${_uuid.v4()}.$ext');
      final t   = await ref.putFile(f);
      urls.add(await t.ref.getDownloadURL());
    }

    final now = DateTime.now();
    await _col.doc(id).set({
      ...task.copyWith(id: id, photoUrls: urls, createdAt: now, updatedAt: now).toJson(),
      'createdAt':  Timestamp.fromDate(now),
      'updatedAt':  Timestamp.fromDate(now),
      'expiresAt':  Timestamp.fromDate(now.add(const Duration(days: 30))),
    });
    return id;
  }

  // ── Read ──────────────────────────────────────────────────────────────────
  Stream<List<TaskModel>> watchOpenTasks({
    String?  categoryId,
    int      limit = AppConstants.pageSize,
    DocumentSnapshot? startAfter,
  }) {
    Query q = _col
        .where('status', isEqualTo: TaskStatus.open.name)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (categoryId != null) q = q.where('categoryId', isEqualTo: categoryId);
    if (startAfter != null) q = q.startAfterDocument(startAfter);

    return q.snapshots().map(
      (snap) => snap.docs.map((d) => TaskModelExt.fromFirestore(d)).toList(),
    );
  }

  Stream<List<TaskModel>> watchMyPostedTasks(String uid) =>
      _col.where('posterId', isEqualTo: uid)
          .where('status', whereIn: [TaskStatus.open.name, TaskStatus.assigned.name, TaskStatus.inProgress.name])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => TaskModelExt.fromFirestore(d)).toList());

  Stream<List<TaskModel>> watchMyAssignedTasks(String uid) =>
      _col.where('assignedProviderId', isEqualTo: uid)
          .where('status', whereIn: [TaskStatus.assigned.name, TaskStatus.inProgress.name])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => TaskModelExt.fromFirestore(d)).toList());

  Stream<List<TaskModel>> watchMyCompletedPostTasks(String uid) =>
      _col.where('posterId', isEqualTo: uid)
          .where('status', isEqualTo: TaskStatus.completed.name)
          .orderBy('completedAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => TaskModelExt.fromFirestore(d)).toList());

  Stream<List<TaskModel>> watchMyCancelledPostTasks(String uid) =>
      _col.where('posterId', isEqualTo: uid)
          .where('status', isEqualTo: TaskStatus.cancelled.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => TaskModelExt.fromFirestore(d)).toList());

  Stream<List<TaskModel>> watchMyCompletedProviderTasks(String uid) =>
      _col.where('assignedProviderId', isEqualTo: uid)
          .where('status', isEqualTo: TaskStatus.completed.name)
          .orderBy('completedAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => TaskModelExt.fromFirestore(d)).toList());

  Stream<List<TaskModel>> watchDirectHireOffers(String providerId) =>
      _col.where('assignedProviderId', isEqualTo: providerId)
          .where('isDirectHire', isEqualTo: true)
          .where('status', isEqualTo: TaskStatus.assigned.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => TaskModelExt.fromFirestore(d)).toList());

  Stream<TaskModel?> watchTask(String taskId) =>
      _col.doc(taskId).snapshots().map(
        (s) => s.exists ? TaskModelExt.fromFirestore(s) : null,
      );

  // ── Update ────────────────────────────────────────────────────────────────
  Future<void> updateStatus(String taskId, TaskStatus status) async {
    await _col.doc(taskId).update({
      'status':    status.name,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> assignProvider(String taskId, String providerId, String providerName) async {
    await _col.doc(taskId).update({
      'status':               TaskStatus.assigned.name,
      'assignedProviderId':   providerId,
      'assignedProviderName': providerName,
      'updatedAt':            Timestamp.now(),
    });
  }

  Future<void> completeTask(String taskId) async {
    await _col.doc(taskId).update({
      'status':      TaskStatus.completed.name,
      'completedAt': Timestamp.now(),
      'updatedAt':   Timestamp.now(),
    });
  }

  Future<void> declineDirectHire(String taskId) async {
    await _col.doc(taskId).update({
      'status':               TaskStatus.cancelled.name,
      'assignedProviderId':   FieldValue.delete(),
      'assignedProviderName': FieldValue.delete(),
      'updatedAt':            Timestamp.now(),
    });
  }

  Future<void> incrementViewCount(String taskId) async {
    await _col.doc(taskId).update({
      'viewCount': FieldValue.increment(1),
    });
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) => TaskRepository());
