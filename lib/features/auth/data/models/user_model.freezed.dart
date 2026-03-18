// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProfilePhoto _$ProfilePhotoFromJson(Map<String, dynamic> json) {
  return _ProfilePhoto.fromJson(json);
}

/// @nodoc
mixin _$ProfilePhoto {
  String get id => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String? get caption => throw _privateConstructorUsedError;
  String? get categoryId =>
      throw _privateConstructorUsedError; // which showcase album this belongs to
  bool get isCover => throw _privateConstructorUsedError; // cover photo flag
  DateTime get uploadedAt => throw _privateConstructorUsedError;

  /// Serializes this ProfilePhoto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProfilePhoto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfilePhotoCopyWith<ProfilePhoto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfilePhotoCopyWith<$Res> {
  factory $ProfilePhotoCopyWith(
          ProfilePhoto value, $Res Function(ProfilePhoto) then) =
      _$ProfilePhotoCopyWithImpl<$Res, ProfilePhoto>;
  @useResult
  $Res call(
      {String id,
      String url,
      String? caption,
      String? categoryId,
      bool isCover,
      DateTime uploadedAt});
}

/// @nodoc
class _$ProfilePhotoCopyWithImpl<$Res, $Val extends ProfilePhoto>
    implements $ProfilePhotoCopyWith<$Res> {
  _$ProfilePhotoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfilePhoto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? caption = freezed,
    Object? categoryId = freezed,
    Object? isCover = null,
    Object? uploadedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      isCover: null == isCover
          ? _value.isCover
          : isCover // ignore: cast_nullable_to_non_nullable
              as bool,
      uploadedAt: null == uploadedAt
          ? _value.uploadedAt
          : uploadedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfilePhotoImplCopyWith<$Res>
    implements $ProfilePhotoCopyWith<$Res> {
  factory _$$ProfilePhotoImplCopyWith(
          _$ProfilePhotoImpl value, $Res Function(_$ProfilePhotoImpl) then) =
      __$$ProfilePhotoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String url,
      String? caption,
      String? categoryId,
      bool isCover,
      DateTime uploadedAt});
}

/// @nodoc
class __$$ProfilePhotoImplCopyWithImpl<$Res>
    extends _$ProfilePhotoCopyWithImpl<$Res, _$ProfilePhotoImpl>
    implements _$$ProfilePhotoImplCopyWith<$Res> {
  __$$ProfilePhotoImplCopyWithImpl(
      _$ProfilePhotoImpl _value, $Res Function(_$ProfilePhotoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfilePhoto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? caption = freezed,
    Object? categoryId = freezed,
    Object? isCover = null,
    Object? uploadedAt = null,
  }) {
    return _then(_$ProfilePhotoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      isCover: null == isCover
          ? _value.isCover
          : isCover // ignore: cast_nullable_to_non_nullable
              as bool,
      uploadedAt: null == uploadedAt
          ? _value.uploadedAt
          : uploadedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfilePhotoImpl implements _ProfilePhoto {
  const _$ProfilePhotoImpl(
      {required this.id,
      required this.url,
      this.caption,
      this.categoryId,
      this.isCover = false,
      required this.uploadedAt});

  factory _$ProfilePhotoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfilePhotoImplFromJson(json);

  @override
  final String id;
  @override
  final String url;
  @override
  final String? caption;
  @override
  final String? categoryId;
// which showcase album this belongs to
  @override
  @JsonKey()
  final bool isCover;
// cover photo flag
  @override
  final DateTime uploadedAt;

  @override
  String toString() {
    return 'ProfilePhoto(id: $id, url: $url, caption: $caption, categoryId: $categoryId, isCover: $isCover, uploadedAt: $uploadedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfilePhotoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.isCover, isCover) || other.isCover == isCover) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, url, caption, categoryId, isCover, uploadedAt);

  /// Create a copy of ProfilePhoto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfilePhotoImplCopyWith<_$ProfilePhotoImpl> get copyWith =>
      __$$ProfilePhotoImplCopyWithImpl<_$ProfilePhotoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfilePhotoImplToJson(
      this,
    );
  }
}

abstract class _ProfilePhoto implements ProfilePhoto {
  const factory _ProfilePhoto(
      {required final String id,
      required final String url,
      final String? caption,
      final String? categoryId,
      final bool isCover,
      required final DateTime uploadedAt}) = _$ProfilePhotoImpl;

  factory _ProfilePhoto.fromJson(Map<String, dynamic> json) =
      _$ProfilePhotoImpl.fromJson;

  @override
  String get id;
  @override
  String get url;
  @override
  String? get caption;
  @override
  String? get categoryId; // which showcase album this belongs to
  @override
  bool get isCover; // cover photo flag
  @override
  DateTime get uploadedAt;

  /// Create a copy of ProfilePhoto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfilePhotoImplCopyWith<_$ProfilePhotoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CategoryShowcase _$CategoryShowcaseFromJson(Map<String, dynamic> json) {
  return _CategoryShowcase.fromJson(json);
}

/// @nodoc
mixin _$CategoryShowcase {
  String get categoryId => throw _privateConstructorUsedError;
  String? get description =>
      throw _privateConstructorUsedError; // the "About Me" text for this category
  List<String> get photoIds => throw _privateConstructorUsedError;

  /// Serializes this CategoryShowcase to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CategoryShowcase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryShowcaseCopyWith<CategoryShowcase> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryShowcaseCopyWith<$Res> {
  factory $CategoryShowcaseCopyWith(
          CategoryShowcase value, $Res Function(CategoryShowcase) then) =
      _$CategoryShowcaseCopyWithImpl<$Res, CategoryShowcase>;
  @useResult
  $Res call({String categoryId, String? description, List<String> photoIds});
}

/// @nodoc
class _$CategoryShowcaseCopyWithImpl<$Res, $Val extends CategoryShowcase>
    implements $CategoryShowcaseCopyWith<$Res> {
  _$CategoryShowcaseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CategoryShowcase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryId = null,
    Object? description = freezed,
    Object? photoIds = null,
  }) {
    return _then(_value.copyWith(
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      photoIds: null == photoIds
          ? _value.photoIds
          : photoIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CategoryShowcaseImplCopyWith<$Res>
    implements $CategoryShowcaseCopyWith<$Res> {
  factory _$$CategoryShowcaseImplCopyWith(_$CategoryShowcaseImpl value,
          $Res Function(_$CategoryShowcaseImpl) then) =
      __$$CategoryShowcaseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String categoryId, String? description, List<String> photoIds});
}

/// @nodoc
class __$$CategoryShowcaseImplCopyWithImpl<$Res>
    extends _$CategoryShowcaseCopyWithImpl<$Res, _$CategoryShowcaseImpl>
    implements _$$CategoryShowcaseImplCopyWith<$Res> {
  __$$CategoryShowcaseImplCopyWithImpl(_$CategoryShowcaseImpl _value,
      $Res Function(_$CategoryShowcaseImpl) _then)
      : super(_value, _then);

  /// Create a copy of CategoryShowcase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryId = null,
    Object? description = freezed,
    Object? photoIds = null,
  }) {
    return _then(_$CategoryShowcaseImpl(
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      photoIds: null == photoIds
          ? _value._photoIds
          : photoIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryShowcaseImpl implements _CategoryShowcase {
  const _$CategoryShowcaseImpl(
      {required this.categoryId,
      this.description,
      final List<String> photoIds = const []})
      : _photoIds = photoIds;

  factory _$CategoryShowcaseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryShowcaseImplFromJson(json);

  @override
  final String categoryId;
  @override
  final String? description;
// the "About Me" text for this category
  final List<String> _photoIds;
// the "About Me" text for this category
  @override
  @JsonKey()
  List<String> get photoIds {
    if (_photoIds is EqualUnmodifiableListView) return _photoIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoIds);
  }

  @override
  String toString() {
    return 'CategoryShowcase(categoryId: $categoryId, description: $description, photoIds: $photoIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryShowcaseImpl &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._photoIds, _photoIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, categoryId, description,
      const DeepCollectionEquality().hash(_photoIds));

  /// Create a copy of CategoryShowcase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryShowcaseImplCopyWith<_$CategoryShowcaseImpl> get copyWith =>
      __$$CategoryShowcaseImplCopyWithImpl<_$CategoryShowcaseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryShowcaseImplToJson(
      this,
    );
  }
}

abstract class _CategoryShowcase implements CategoryShowcase {
  const factory _CategoryShowcase(
      {required final String categoryId,
      final String? description,
      final List<String> photoIds}) = _$CategoryShowcaseImpl;

  factory _CategoryShowcase.fromJson(Map<String, dynamic> json) =
      _$CategoryShowcaseImpl.fromJson;

  @override
  String get categoryId;
  @override
  String? get description; // the "About Me" text for this category
  @override
  List<String> get photoIds;

  /// Create a copy of CategoryShowcase
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryShowcaseImplCopyWith<_$CategoryShowcaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProviderStats _$ProviderStatsFromJson(Map<String, dynamic> json) {
  return _ProviderStats.fromJson(json);
}

/// @nodoc
mixin _$ProviderStats {
  int get completedTasks => throw _privateConstructorUsedError;
  double get avgRating => throw _privateConstructorUsedError;
  int get totalReviews => throw _privateConstructorUsedError;
  int get repeatHires =>
      throw _privateConstructorUsedError; // times hired by same poster 2+
  String? get avgResponseTime =>
      throw _privateConstructorUsedError; // e.g. "< 1 hour"
  double get earningsTotal => throw _privateConstructorUsedError;

  /// Serializes this ProviderStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProviderStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProviderStatsCopyWith<ProviderStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProviderStatsCopyWith<$Res> {
  factory $ProviderStatsCopyWith(
          ProviderStats value, $Res Function(ProviderStats) then) =
      _$ProviderStatsCopyWithImpl<$Res, ProviderStats>;
  @useResult
  $Res call(
      {int completedTasks,
      double avgRating,
      int totalReviews,
      int repeatHires,
      String? avgResponseTime,
      double earningsTotal});
}

/// @nodoc
class _$ProviderStatsCopyWithImpl<$Res, $Val extends ProviderStats>
    implements $ProviderStatsCopyWith<$Res> {
  _$ProviderStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProviderStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? completedTasks = null,
    Object? avgRating = null,
    Object? totalReviews = null,
    Object? repeatHires = null,
    Object? avgResponseTime = freezed,
    Object? earningsTotal = null,
  }) {
    return _then(_value.copyWith(
      completedTasks: null == completedTasks
          ? _value.completedTasks
          : completedTasks // ignore: cast_nullable_to_non_nullable
              as int,
      avgRating: null == avgRating
          ? _value.avgRating
          : avgRating // ignore: cast_nullable_to_non_nullable
              as double,
      totalReviews: null == totalReviews
          ? _value.totalReviews
          : totalReviews // ignore: cast_nullable_to_non_nullable
              as int,
      repeatHires: null == repeatHires
          ? _value.repeatHires
          : repeatHires // ignore: cast_nullable_to_non_nullable
              as int,
      avgResponseTime: freezed == avgResponseTime
          ? _value.avgResponseTime
          : avgResponseTime // ignore: cast_nullable_to_non_nullable
              as String?,
      earningsTotal: null == earningsTotal
          ? _value.earningsTotal
          : earningsTotal // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProviderStatsImplCopyWith<$Res>
    implements $ProviderStatsCopyWith<$Res> {
  factory _$$ProviderStatsImplCopyWith(
          _$ProviderStatsImpl value, $Res Function(_$ProviderStatsImpl) then) =
      __$$ProviderStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int completedTasks,
      double avgRating,
      int totalReviews,
      int repeatHires,
      String? avgResponseTime,
      double earningsTotal});
}

/// @nodoc
class __$$ProviderStatsImplCopyWithImpl<$Res>
    extends _$ProviderStatsCopyWithImpl<$Res, _$ProviderStatsImpl>
    implements _$$ProviderStatsImplCopyWith<$Res> {
  __$$ProviderStatsImplCopyWithImpl(
      _$ProviderStatsImpl _value, $Res Function(_$ProviderStatsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProviderStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? completedTasks = null,
    Object? avgRating = null,
    Object? totalReviews = null,
    Object? repeatHires = null,
    Object? avgResponseTime = freezed,
    Object? earningsTotal = null,
  }) {
    return _then(_$ProviderStatsImpl(
      completedTasks: null == completedTasks
          ? _value.completedTasks
          : completedTasks // ignore: cast_nullable_to_non_nullable
              as int,
      avgRating: null == avgRating
          ? _value.avgRating
          : avgRating // ignore: cast_nullable_to_non_nullable
              as double,
      totalReviews: null == totalReviews
          ? _value.totalReviews
          : totalReviews // ignore: cast_nullable_to_non_nullable
              as int,
      repeatHires: null == repeatHires
          ? _value.repeatHires
          : repeatHires // ignore: cast_nullable_to_non_nullable
              as int,
      avgResponseTime: freezed == avgResponseTime
          ? _value.avgResponseTime
          : avgResponseTime // ignore: cast_nullable_to_non_nullable
              as String?,
      earningsTotal: null == earningsTotal
          ? _value.earningsTotal
          : earningsTotal // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProviderStatsImpl implements _ProviderStats {
  const _$ProviderStatsImpl(
      {this.completedTasks = 0,
      this.avgRating = 0.0,
      this.totalReviews = 0,
      this.repeatHires = 0,
      this.avgResponseTime,
      this.earningsTotal = 0.0});

  factory _$ProviderStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProviderStatsImplFromJson(json);

  @override
  @JsonKey()
  final int completedTasks;
  @override
  @JsonKey()
  final double avgRating;
  @override
  @JsonKey()
  final int totalReviews;
  @override
  @JsonKey()
  final int repeatHires;
// times hired by same poster 2+
  @override
  final String? avgResponseTime;
// e.g. "< 1 hour"
  @override
  @JsonKey()
  final double earningsTotal;

  @override
  String toString() {
    return 'ProviderStats(completedTasks: $completedTasks, avgRating: $avgRating, totalReviews: $totalReviews, repeatHires: $repeatHires, avgResponseTime: $avgResponseTime, earningsTotal: $earningsTotal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProviderStatsImpl &&
            (identical(other.completedTasks, completedTasks) ||
                other.completedTasks == completedTasks) &&
            (identical(other.avgRating, avgRating) ||
                other.avgRating == avgRating) &&
            (identical(other.totalReviews, totalReviews) ||
                other.totalReviews == totalReviews) &&
            (identical(other.repeatHires, repeatHires) ||
                other.repeatHires == repeatHires) &&
            (identical(other.avgResponseTime, avgResponseTime) ||
                other.avgResponseTime == avgResponseTime) &&
            (identical(other.earningsTotal, earningsTotal) ||
                other.earningsTotal == earningsTotal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, completedTasks, avgRating,
      totalReviews, repeatHires, avgResponseTime, earningsTotal);

  /// Create a copy of ProviderStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProviderStatsImplCopyWith<_$ProviderStatsImpl> get copyWith =>
      __$$ProviderStatsImplCopyWithImpl<_$ProviderStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProviderStatsImplToJson(
      this,
    );
  }
}

abstract class _ProviderStats implements ProviderStats {
  const factory _ProviderStats(
      {final int completedTasks,
      final double avgRating,
      final int totalReviews,
      final int repeatHires,
      final String? avgResponseTime,
      final double earningsTotal}) = _$ProviderStatsImpl;

  factory _ProviderStats.fromJson(Map<String, dynamic> json) =
      _$ProviderStatsImpl.fromJson;

  @override
  int get completedTasks;
  @override
  double get avgRating;
  @override
  int get totalReviews;
  @override
  int get repeatHires; // times hired by same poster 2+
  @override
  String? get avgResponseTime; // e.g. "< 1 hour"
  @override
  double get earningsTotal;

  /// Create a copy of ProviderStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProviderStatsImplCopyWith<_$ProviderStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  String get uid => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError; // Basic info
  String? get displayName => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get headline => throw _privateConstructorUsedError; // 80-char tagline
  String? get bio => throw _privateConstructorUsedError; // 500-char about me
  String? get neighbourhood =>
      throw _privateConstructorUsedError; // e.g. "Ang Mo Kio"
// Role
  UserRole get role => throw _privateConstructorUsedError; // Provider-specific
  List<String> get serviceCategories =>
      throw _privateConstructorUsedError; // category IDs
  List<String> get skillTags =>
      throw _privateConstructorUsedError; // e.g. #DogWalking
  List<CategoryShowcase> get categoryShowcases =>
      throw _privateConstructorUsedError; // Media
  List<ProfilePhoto> get photos => throw _privateConstructorUsedError;
  String? get introVideoUrl =>
      throw _privateConstructorUsedError; // Trust & Verification
  List<VerificationBadge> get badges => throw _privateConstructorUsedError;
  ProviderStats? get stats =>
      throw _privateConstructorUsedError; // Profile completeness (0–100)
  int get completenessScore => throw _privateConstructorUsedError; // Meta
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get lastActiveAt => throw _privateConstructorUsedError;
  bool get isOnline => throw _privateConstructorUsedError;
  bool get isProfileComplete => throw _privateConstructorUsedError;
  bool get isDeactivated => throw _privateConstructorUsedError;

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call(
      {String uid,
      String phone,
      String? displayName,
      String? email,
      String? avatarUrl,
      String? headline,
      String? bio,
      String? neighbourhood,
      UserRole role,
      List<String> serviceCategories,
      List<String> skillTags,
      List<CategoryShowcase> categoryShowcases,
      List<ProfilePhoto> photos,
      String? introVideoUrl,
      List<VerificationBadge> badges,
      ProviderStats? stats,
      int completenessScore,
      DateTime? createdAt,
      DateTime? lastActiveAt,
      bool isOnline,
      bool isProfileComplete,
      bool isDeactivated});

  $ProviderStatsCopyWith<$Res>? get stats;
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? phone = null,
    Object? displayName = freezed,
    Object? email = freezed,
    Object? avatarUrl = freezed,
    Object? headline = freezed,
    Object? bio = freezed,
    Object? neighbourhood = freezed,
    Object? role = null,
    Object? serviceCategories = null,
    Object? skillTags = null,
    Object? categoryShowcases = null,
    Object? photos = null,
    Object? introVideoUrl = freezed,
    Object? badges = null,
    Object? stats = freezed,
    Object? completenessScore = null,
    Object? createdAt = freezed,
    Object? lastActiveAt = freezed,
    Object? isOnline = null,
    Object? isProfileComplete = null,
    Object? isDeactivated = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      headline: freezed == headline
          ? _value.headline
          : headline // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      neighbourhood: freezed == neighbourhood
          ? _value.neighbourhood
          : neighbourhood // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      serviceCategories: null == serviceCategories
          ? _value.serviceCategories
          : serviceCategories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      skillTags: null == skillTags
          ? _value.skillTags
          : skillTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      categoryShowcases: null == categoryShowcases
          ? _value.categoryShowcases
          : categoryShowcases // ignore: cast_nullable_to_non_nullable
              as List<CategoryShowcase>,
      photos: null == photos
          ? _value.photos
          : photos // ignore: cast_nullable_to_non_nullable
              as List<ProfilePhoto>,
      introVideoUrl: freezed == introVideoUrl
          ? _value.introVideoUrl
          : introVideoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      badges: null == badges
          ? _value.badges
          : badges // ignore: cast_nullable_to_non_nullable
              as List<VerificationBadge>,
      stats: freezed == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as ProviderStats?,
      completenessScore: null == completenessScore
          ? _value.completenessScore
          : completenessScore // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastActiveAt: freezed == lastActiveAt
          ? _value.lastActiveAt
          : lastActiveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isOnline: null == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool,
      isProfileComplete: null == isProfileComplete
          ? _value.isProfileComplete
          : isProfileComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeactivated: null == isDeactivated
          ? _value.isDeactivated
          : isDeactivated // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProviderStatsCopyWith<$Res>? get stats {
    if (_value.stats == null) {
      return null;
    }

    return $ProviderStatsCopyWith<$Res>(_value.stats!, (value) {
      return _then(_value.copyWith(stats: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl value, $Res Function(_$UserModelImpl) then) =
      __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid,
      String phone,
      String? displayName,
      String? email,
      String? avatarUrl,
      String? headline,
      String? bio,
      String? neighbourhood,
      UserRole role,
      List<String> serviceCategories,
      List<String> skillTags,
      List<CategoryShowcase> categoryShowcases,
      List<ProfilePhoto> photos,
      String? introVideoUrl,
      List<VerificationBadge> badges,
      ProviderStats? stats,
      int completenessScore,
      DateTime? createdAt,
      DateTime? lastActiveAt,
      bool isOnline,
      bool isProfileComplete,
      bool isDeactivated});

  @override
  $ProviderStatsCopyWith<$Res>? get stats;
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? phone = null,
    Object? displayName = freezed,
    Object? email = freezed,
    Object? avatarUrl = freezed,
    Object? headline = freezed,
    Object? bio = freezed,
    Object? neighbourhood = freezed,
    Object? role = null,
    Object? serviceCategories = null,
    Object? skillTags = null,
    Object? categoryShowcases = null,
    Object? photos = null,
    Object? introVideoUrl = freezed,
    Object? badges = null,
    Object? stats = freezed,
    Object? completenessScore = null,
    Object? createdAt = freezed,
    Object? lastActiveAt = freezed,
    Object? isOnline = null,
    Object? isProfileComplete = null,
    Object? isDeactivated = null,
  }) {
    return _then(_$UserModelImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      headline: freezed == headline
          ? _value.headline
          : headline // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      neighbourhood: freezed == neighbourhood
          ? _value.neighbourhood
          : neighbourhood // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      serviceCategories: null == serviceCategories
          ? _value._serviceCategories
          : serviceCategories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      skillTags: null == skillTags
          ? _value._skillTags
          : skillTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      categoryShowcases: null == categoryShowcases
          ? _value._categoryShowcases
          : categoryShowcases // ignore: cast_nullable_to_non_nullable
              as List<CategoryShowcase>,
      photos: null == photos
          ? _value._photos
          : photos // ignore: cast_nullable_to_non_nullable
              as List<ProfilePhoto>,
      introVideoUrl: freezed == introVideoUrl
          ? _value.introVideoUrl
          : introVideoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      badges: null == badges
          ? _value._badges
          : badges // ignore: cast_nullable_to_non_nullable
              as List<VerificationBadge>,
      stats: freezed == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as ProviderStats?,
      completenessScore: null == completenessScore
          ? _value.completenessScore
          : completenessScore // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastActiveAt: freezed == lastActiveAt
          ? _value.lastActiveAt
          : lastActiveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isOnline: null == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool,
      isProfileComplete: null == isProfileComplete
          ? _value.isProfileComplete
          : isProfileComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeactivated: null == isDeactivated
          ? _value.isDeactivated
          : isDeactivated // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl(
      {required this.uid,
      required this.phone,
      this.displayName,
      this.email,
      this.avatarUrl,
      this.headline,
      this.bio,
      this.neighbourhood,
      this.role = UserRole.poster,
      final List<String> serviceCategories = const [],
      final List<String> skillTags = const [],
      final List<CategoryShowcase> categoryShowcases = const [],
      final List<ProfilePhoto> photos = const [],
      this.introVideoUrl,
      final List<VerificationBadge> badges = const [],
      this.stats,
      this.completenessScore = 0,
      this.createdAt,
      this.lastActiveAt,
      this.isOnline = false,
      this.isProfileComplete = false,
      this.isDeactivated = false})
      : _serviceCategories = serviceCategories,
        _skillTags = skillTags,
        _categoryShowcases = categoryShowcases,
        _photos = photos,
        _badges = badges;

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  final String uid;
  @override
  final String phone;
// Basic info
  @override
  final String? displayName;
  @override
  final String? email;
  @override
  final String? avatarUrl;
  @override
  final String? headline;
// 80-char tagline
  @override
  final String? bio;
// 500-char about me
  @override
  final String? neighbourhood;
// e.g. "Ang Mo Kio"
// Role
  @override
  @JsonKey()
  final UserRole role;
// Provider-specific
  final List<String> _serviceCategories;
// Provider-specific
  @override
  @JsonKey()
  List<String> get serviceCategories {
    if (_serviceCategories is EqualUnmodifiableListView)
      return _serviceCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_serviceCategories);
  }

// category IDs
  final List<String> _skillTags;
// category IDs
  @override
  @JsonKey()
  List<String> get skillTags {
    if (_skillTags is EqualUnmodifiableListView) return _skillTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_skillTags);
  }

// e.g. #DogWalking
  final List<CategoryShowcase> _categoryShowcases;
// e.g. #DogWalking
  @override
  @JsonKey()
  List<CategoryShowcase> get categoryShowcases {
    if (_categoryShowcases is EqualUnmodifiableListView)
      return _categoryShowcases;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categoryShowcases);
  }

// Media
  final List<ProfilePhoto> _photos;
// Media
  @override
  @JsonKey()
  List<ProfilePhoto> get photos {
    if (_photos is EqualUnmodifiableListView) return _photos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photos);
  }

  @override
  final String? introVideoUrl;
// Trust & Verification
  final List<VerificationBadge> _badges;
// Trust & Verification
  @override
  @JsonKey()
  List<VerificationBadge> get badges {
    if (_badges is EqualUnmodifiableListView) return _badges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_badges);
  }

  @override
  final ProviderStats? stats;
// Profile completeness (0–100)
  @override
  @JsonKey()
  final int completenessScore;
// Meta
  @override
  final DateTime? createdAt;
  @override
  final DateTime? lastActiveAt;
  @override
  @JsonKey()
  final bool isOnline;
  @override
  @JsonKey()
  final bool isProfileComplete;
  @override
  @JsonKey()
  final bool isDeactivated;

  @override
  String toString() {
    return 'UserModel(uid: $uid, phone: $phone, displayName: $displayName, email: $email, avatarUrl: $avatarUrl, headline: $headline, bio: $bio, neighbourhood: $neighbourhood, role: $role, serviceCategories: $serviceCategories, skillTags: $skillTags, categoryShowcases: $categoryShowcases, photos: $photos, introVideoUrl: $introVideoUrl, badges: $badges, stats: $stats, completenessScore: $completenessScore, createdAt: $createdAt, lastActiveAt: $lastActiveAt, isOnline: $isOnline, isProfileComplete: $isProfileComplete, isDeactivated: $isDeactivated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.headline, headline) ||
                other.headline == headline) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.neighbourhood, neighbourhood) ||
                other.neighbourhood == neighbourhood) &&
            (identical(other.role, role) || other.role == role) &&
            const DeepCollectionEquality()
                .equals(other._serviceCategories, _serviceCategories) &&
            const DeepCollectionEquality()
                .equals(other._skillTags, _skillTags) &&
            const DeepCollectionEquality()
                .equals(other._categoryShowcases, _categoryShowcases) &&
            const DeepCollectionEquality().equals(other._photos, _photos) &&
            (identical(other.introVideoUrl, introVideoUrl) ||
                other.introVideoUrl == introVideoUrl) &&
            const DeepCollectionEquality().equals(other._badges, _badges) &&
            (identical(other.stats, stats) || other.stats == stats) &&
            (identical(other.completenessScore, completenessScore) ||
                other.completenessScore == completenessScore) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastActiveAt, lastActiveAt) ||
                other.lastActiveAt == lastActiveAt) &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.isProfileComplete, isProfileComplete) ||
                other.isProfileComplete == isProfileComplete) &&
            (identical(other.isDeactivated, isDeactivated) ||
                other.isDeactivated == isDeactivated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        uid,
        phone,
        displayName,
        email,
        avatarUrl,
        headline,
        bio,
        neighbourhood,
        role,
        const DeepCollectionEquality().hash(_serviceCategories),
        const DeepCollectionEquality().hash(_skillTags),
        const DeepCollectionEquality().hash(_categoryShowcases),
        const DeepCollectionEquality().hash(_photos),
        introVideoUrl,
        const DeepCollectionEquality().hash(_badges),
        stats,
        completenessScore,
        createdAt,
        lastActiveAt,
        isOnline,
        isProfileComplete,
        isDeactivated
      ]);

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(
      this,
    );
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel(
      {required final String uid,
      required final String phone,
      final String? displayName,
      final String? email,
      final String? avatarUrl,
      final String? headline,
      final String? bio,
      final String? neighbourhood,
      final UserRole role,
      final List<String> serviceCategories,
      final List<String> skillTags,
      final List<CategoryShowcase> categoryShowcases,
      final List<ProfilePhoto> photos,
      final String? introVideoUrl,
      final List<VerificationBadge> badges,
      final ProviderStats? stats,
      final int completenessScore,
      final DateTime? createdAt,
      final DateTime? lastActiveAt,
      final bool isOnline,
      final bool isProfileComplete,
      final bool isDeactivated}) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  String get uid;
  @override
  String get phone; // Basic info
  @override
  String? get displayName;
  @override
  String? get email;
  @override
  String? get avatarUrl;
  @override
  String? get headline; // 80-char tagline
  @override
  String? get bio; // 500-char about me
  @override
  String? get neighbourhood; // e.g. "Ang Mo Kio"
// Role
  @override
  UserRole get role; // Provider-specific
  @override
  List<String> get serviceCategories; // category IDs
  @override
  List<String> get skillTags; // e.g. #DogWalking
  @override
  List<CategoryShowcase> get categoryShowcases; // Media
  @override
  List<ProfilePhoto> get photos;
  @override
  String? get introVideoUrl; // Trust & Verification
  @override
  List<VerificationBadge> get badges;
  @override
  ProviderStats? get stats; // Profile completeness (0–100)
  @override
  int get completenessScore; // Meta
  @override
  DateTime? get createdAt;
  @override
  DateTime? get lastActiveAt;
  @override
  bool get isOnline;
  @override
  bool get isProfileComplete;
  @override
  bool get isDeactivated;

  /// Create a copy of UserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
