// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ReviewModel _$ReviewModelFromJson(Map<String, dynamic> json) {
  return _ReviewModel.fromJson(json);
}

/// @nodoc
mixin _$ReviewModel {
  String get id => throw _privateConstructorUsedError;
  String get reviewerId => throw _privateConstructorUsedError;
  String get reviewerName => throw _privateConstructorUsedError;
  String? get reviewerAvatarUrl => throw _privateConstructorUsedError;
  String get reviewedUserId => throw _privateConstructorUsedError;
  String get taskId => throw _privateConstructorUsedError;
  String get taskCategory => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError; // 1.0–5.0
  String? get comment => throw _privateConstructorUsedError;
  List<String> get skillEndorsements => throw _privateConstructorUsedError;
  String? get providerReply => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ReviewModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReviewModelCopyWith<ReviewModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReviewModelCopyWith<$Res> {
  factory $ReviewModelCopyWith(
          ReviewModel value, $Res Function(ReviewModel) then) =
      _$ReviewModelCopyWithImpl<$Res, ReviewModel>;
  @useResult
  $Res call(
      {String id,
      String reviewerId,
      String reviewerName,
      String? reviewerAvatarUrl,
      String reviewedUserId,
      String taskId,
      String taskCategory,
      double rating,
      String? comment,
      List<String> skillEndorsements,
      String? providerReply,
      DateTime createdAt});
}

/// @nodoc
class _$ReviewModelCopyWithImpl<$Res, $Val extends ReviewModel>
    implements $ReviewModelCopyWith<$Res> {
  _$ReviewModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reviewerId = null,
    Object? reviewerName = null,
    Object? reviewerAvatarUrl = freezed,
    Object? reviewedUserId = null,
    Object? taskId = null,
    Object? taskCategory = null,
    Object? rating = null,
    Object? comment = freezed,
    Object? skillEndorsements = null,
    Object? providerReply = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      reviewerId: null == reviewerId
          ? _value.reviewerId
          : reviewerId // ignore: cast_nullable_to_non_nullable
              as String,
      reviewerName: null == reviewerName
          ? _value.reviewerName
          : reviewerName // ignore: cast_nullable_to_non_nullable
              as String,
      reviewerAvatarUrl: freezed == reviewerAvatarUrl
          ? _value.reviewerAvatarUrl
          : reviewerAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewedUserId: null == reviewedUserId
          ? _value.reviewedUserId
          : reviewedUserId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      taskCategory: null == taskCategory
          ? _value.taskCategory
          : taskCategory // ignore: cast_nullable_to_non_nullable
              as String,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      skillEndorsements: null == skillEndorsements
          ? _value.skillEndorsements
          : skillEndorsements // ignore: cast_nullable_to_non_nullable
              as List<String>,
      providerReply: freezed == providerReply
          ? _value.providerReply
          : providerReply // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReviewModelImplCopyWith<$Res>
    implements $ReviewModelCopyWith<$Res> {
  factory _$$ReviewModelImplCopyWith(
          _$ReviewModelImpl value, $Res Function(_$ReviewModelImpl) then) =
      __$$ReviewModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String reviewerId,
      String reviewerName,
      String? reviewerAvatarUrl,
      String reviewedUserId,
      String taskId,
      String taskCategory,
      double rating,
      String? comment,
      List<String> skillEndorsements,
      String? providerReply,
      DateTime createdAt});
}

/// @nodoc
class __$$ReviewModelImplCopyWithImpl<$Res>
    extends _$ReviewModelCopyWithImpl<$Res, _$ReviewModelImpl>
    implements _$$ReviewModelImplCopyWith<$Res> {
  __$$ReviewModelImplCopyWithImpl(
      _$ReviewModelImpl _value, $Res Function(_$ReviewModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reviewerId = null,
    Object? reviewerName = null,
    Object? reviewerAvatarUrl = freezed,
    Object? reviewedUserId = null,
    Object? taskId = null,
    Object? taskCategory = null,
    Object? rating = null,
    Object? comment = freezed,
    Object? skillEndorsements = null,
    Object? providerReply = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$ReviewModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      reviewerId: null == reviewerId
          ? _value.reviewerId
          : reviewerId // ignore: cast_nullable_to_non_nullable
              as String,
      reviewerName: null == reviewerName
          ? _value.reviewerName
          : reviewerName // ignore: cast_nullable_to_non_nullable
              as String,
      reviewerAvatarUrl: freezed == reviewerAvatarUrl
          ? _value.reviewerAvatarUrl
          : reviewerAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewedUserId: null == reviewedUserId
          ? _value.reviewedUserId
          : reviewedUserId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      taskCategory: null == taskCategory
          ? _value.taskCategory
          : taskCategory // ignore: cast_nullable_to_non_nullable
              as String,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      skillEndorsements: null == skillEndorsements
          ? _value._skillEndorsements
          : skillEndorsements // ignore: cast_nullable_to_non_nullable
              as List<String>,
      providerReply: freezed == providerReply
          ? _value.providerReply
          : providerReply // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReviewModelImpl implements _ReviewModel {
  const _$ReviewModelImpl(
      {required this.id,
      required this.reviewerId,
      required this.reviewerName,
      this.reviewerAvatarUrl,
      required this.reviewedUserId,
      required this.taskId,
      required this.taskCategory,
      required this.rating,
      this.comment,
      final List<String> skillEndorsements = const [],
      this.providerReply,
      required this.createdAt})
      : _skillEndorsements = skillEndorsements;

  factory _$ReviewModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReviewModelImplFromJson(json);

  @override
  final String id;
  @override
  final String reviewerId;
  @override
  final String reviewerName;
  @override
  final String? reviewerAvatarUrl;
  @override
  final String reviewedUserId;
  @override
  final String taskId;
  @override
  final String taskCategory;
  @override
  final double rating;
// 1.0–5.0
  @override
  final String? comment;
  final List<String> _skillEndorsements;
  @override
  @JsonKey()
  List<String> get skillEndorsements {
    if (_skillEndorsements is EqualUnmodifiableListView)
      return _skillEndorsements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_skillEndorsements);
  }

  @override
  final String? providerReply;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'ReviewModel(id: $id, reviewerId: $reviewerId, reviewerName: $reviewerName, reviewerAvatarUrl: $reviewerAvatarUrl, reviewedUserId: $reviewedUserId, taskId: $taskId, taskCategory: $taskCategory, rating: $rating, comment: $comment, skillEndorsements: $skillEndorsements, providerReply: $providerReply, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReviewModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reviewerId, reviewerId) ||
                other.reviewerId == reviewerId) &&
            (identical(other.reviewerName, reviewerName) ||
                other.reviewerName == reviewerName) &&
            (identical(other.reviewerAvatarUrl, reviewerAvatarUrl) ||
                other.reviewerAvatarUrl == reviewerAvatarUrl) &&
            (identical(other.reviewedUserId, reviewedUserId) ||
                other.reviewedUserId == reviewedUserId) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.taskCategory, taskCategory) ||
                other.taskCategory == taskCategory) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            const DeepCollectionEquality()
                .equals(other._skillEndorsements, _skillEndorsements) &&
            (identical(other.providerReply, providerReply) ||
                other.providerReply == providerReply) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      reviewerId,
      reviewerName,
      reviewerAvatarUrl,
      reviewedUserId,
      taskId,
      taskCategory,
      rating,
      comment,
      const DeepCollectionEquality().hash(_skillEndorsements),
      providerReply,
      createdAt);

  /// Create a copy of ReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReviewModelImplCopyWith<_$ReviewModelImpl> get copyWith =>
      __$$ReviewModelImplCopyWithImpl<_$ReviewModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReviewModelImplToJson(
      this,
    );
  }
}

abstract class _ReviewModel implements ReviewModel {
  const factory _ReviewModel(
      {required final String id,
      required final String reviewerId,
      required final String reviewerName,
      final String? reviewerAvatarUrl,
      required final String reviewedUserId,
      required final String taskId,
      required final String taskCategory,
      required final double rating,
      final String? comment,
      final List<String> skillEndorsements,
      final String? providerReply,
      required final DateTime createdAt}) = _$ReviewModelImpl;

  factory _ReviewModel.fromJson(Map<String, dynamic> json) =
      _$ReviewModelImpl.fromJson;

  @override
  String get id;
  @override
  String get reviewerId;
  @override
  String get reviewerName;
  @override
  String? get reviewerAvatarUrl;
  @override
  String get reviewedUserId;
  @override
  String get taskId;
  @override
  String get taskCategory;
  @override
  double get rating; // 1.0–5.0
  @override
  String? get comment;
  @override
  List<String> get skillEndorsements;
  @override
  String? get providerReply;
  @override
  DateTime get createdAt;

  /// Create a copy of ReviewModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReviewModelImplCopyWith<_$ReviewModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
