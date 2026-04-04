import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

enum TaskStatus { open, assigned, inProgress, completed, cancelled, disputed }

enum TaskUrgency { flexible, today, asap }

@freezed
class GeoPoint2 with _$GeoPoint2 {
  const factory GeoPoint2({required double lat, required double lng}) =
      _GeoPoint2;
  factory GeoPoint2.fromJson(Map<String, dynamic> json) =>
      _$GeoPoint2FromJson(json);
}

extension GeoPoint2Ext on GeoPoint2 {
  static GeoPoint2 fromFirestore(GeoPoint gp) =>
      GeoPoint2(lat: gp.latitude, lng: gp.longitude);
}

@freezed
class TaskModel with _$TaskModel {
  const factory TaskModel({
    required String id,
    required String posterId,
    String? posterName,
    String? posterAvatarUrl,

    // Content
    required String title,
    required String description,
    required String categoryId,
    @Default([]) List<String> photoUrls,
    @Default([]) List<String> tags,

    // Location
    required String locationLabel, // Human-readable: "Blk 123 AMK Ave 6"
    String? neighbourhood,
    GeoPoint2? location,

    // Pricing
    required double budgetMin,
    double? budgetMax,
    @Default('SGD') String currency,

    // Timing
    required TaskUrgency urgency,
    DateTime? scheduledDate,
    int? estimatedDurationMins,

    // Status
    @Default(TaskStatus.open) TaskStatus status,
    String? assignedProviderId,
    String? assignedProviderName,

    // Counts
    @Default(0) int bidCount,
    @Default(0) int viewCount,

    // Timestamps
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? expiresAt,

    // Direct Hire
    @Default(false) bool isDirectHire,

    // Payment
    String? paymentIntentId,
    @Default(false) bool isPaid,
    @Default(false) bool isEscrowReleased,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);
}

extension TaskModelExt on TaskModel {
  bool get isOpen => status == TaskStatus.open;

  static String _formatCurrencyAmount(double amount) {
    if (amount.truncateToDouble() == amount) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static TaskModel fromFirestore(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    // Convert Firestore Timestamps → ISO-8601 strings for json_serializable
    for (final key in [
      'createdAt',
      'updatedAt',
      'completedAt',
      'expiresAt',
      'scheduledDate'
    ]) {
      if (data[key] is Timestamp) {
        data[key] = (data[key] as Timestamp).toDate().toIso8601String();
      }
    }
    // Convert Firestore GeoPoint → Map for json_serializable
    if (data['location'] is GeoPoint) {
      final gp = data['location'] as GeoPoint;
      data['location'] = {'lat': gp.latitude, 'lng': gp.longitude};
    }
    return TaskModel.fromJson({...data, 'id': doc.id});
  }

  bool get isAssigned =>
      status == TaskStatus.assigned || status == TaskStatus.inProgress;
  bool get isCompleted => status == TaskStatus.completed;

  String get budgetDisplay {
    final minDisplay = _formatCurrencyAmount(budgetMin);
    if (budgetMax != null) {
      final maxDisplay = _formatCurrencyAmount(budgetMax!);
      return 'S\$$minDisplay–S\$$maxDisplay';
    }
    return 'S\$$minDisplay';
  }

  String get urgencyDisplay {
    switch (urgency) {
      case TaskUrgency.asap:
        return '🔴 ASAP';
      case TaskUrgency.today:
        return '🟡 Today';
      case TaskUrgency.flexible:
        return '🟢 Flexible';
    }
  }
}
