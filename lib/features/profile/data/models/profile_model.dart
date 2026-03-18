// Review model (profile-specific)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
class ReviewModel with _$ReviewModel {
  const factory ReviewModel({
    required String id,
    required String reviewerId,
    required String reviewerName,
    String?         reviewerAvatarUrl,
    required String reviewedUserId,
    required String taskId,
    required String taskCategory,
    required double rating,            // 1.0–5.0
    String?         comment,
    @Default([]) List<String> skillEndorsements,
    String?         providerReply,
    required DateTime createdAt,
  }) = _ReviewModel;

  factory ReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewModelFromJson(json);
}

extension ReviewModelExt on ReviewModel {
  static ReviewModel fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel.fromJson({...data, 'id': doc.id});
  }
}
