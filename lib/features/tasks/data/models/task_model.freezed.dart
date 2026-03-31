// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GeoPoint2 _$GeoPoint2FromJson(Map<String, dynamic> json) {
  return _GeoPoint2.fromJson(json);
}

/// @nodoc
mixin _$GeoPoint2 {
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;

  /// Serializes this GeoPoint2 to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GeoPoint2
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GeoPoint2CopyWith<GeoPoint2> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GeoPoint2CopyWith<$Res> {
  factory $GeoPoint2CopyWith(GeoPoint2 value, $Res Function(GeoPoint2) then) =
      _$GeoPoint2CopyWithImpl<$Res, GeoPoint2>;
  @useResult
  $Res call({double lat, double lng});
}

/// @nodoc
class _$GeoPoint2CopyWithImpl<$Res, $Val extends GeoPoint2>
    implements $GeoPoint2CopyWith<$Res> {
  _$GeoPoint2CopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GeoPoint2
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lng = null,
  }) {
    return _then(_value.copyWith(
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GeoPoint2ImplCopyWith<$Res>
    implements $GeoPoint2CopyWith<$Res> {
  factory _$$GeoPoint2ImplCopyWith(
          _$GeoPoint2Impl value, $Res Function(_$GeoPoint2Impl) then) =
      __$$GeoPoint2ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double lat, double lng});
}

/// @nodoc
class __$$GeoPoint2ImplCopyWithImpl<$Res>
    extends _$GeoPoint2CopyWithImpl<$Res, _$GeoPoint2Impl>
    implements _$$GeoPoint2ImplCopyWith<$Res> {
  __$$GeoPoint2ImplCopyWithImpl(
      _$GeoPoint2Impl _value, $Res Function(_$GeoPoint2Impl) _then)
      : super(_value, _then);

  /// Create a copy of GeoPoint2
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lng = null,
  }) {
    return _then(_$GeoPoint2Impl(
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GeoPoint2Impl implements _GeoPoint2 {
  const _$GeoPoint2Impl({required this.lat, required this.lng});

  factory _$GeoPoint2Impl.fromJson(Map<String, dynamic> json) =>
      _$$GeoPoint2ImplFromJson(json);

  @override
  final double lat;
  @override
  final double lng;

  @override
  String toString() {
    return 'GeoPoint2(lat: $lat, lng: $lng)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GeoPoint2Impl &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, lat, lng);

  /// Create a copy of GeoPoint2
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GeoPoint2ImplCopyWith<_$GeoPoint2Impl> get copyWith =>
      __$$GeoPoint2ImplCopyWithImpl<_$GeoPoint2Impl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GeoPoint2ImplToJson(
      this,
    );
  }
}

abstract class _GeoPoint2 implements GeoPoint2 {
  const factory _GeoPoint2(
      {required final double lat, required final double lng}) = _$GeoPoint2Impl;

  factory _GeoPoint2.fromJson(Map<String, dynamic> json) =
      _$GeoPoint2Impl.fromJson;

  @override
  double get lat;
  @override
  double get lng;

  /// Create a copy of GeoPoint2
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GeoPoint2ImplCopyWith<_$GeoPoint2Impl> get copyWith =>
      throw _privateConstructorUsedError;
}

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) {
  return _TaskModel.fromJson(json);
}

/// @nodoc
mixin _$TaskModel {
  String get id => throw _privateConstructorUsedError;
  String get posterId => throw _privateConstructorUsedError;
  String? get posterName => throw _privateConstructorUsedError;
  String? get posterAvatarUrl => throw _privateConstructorUsedError; // Content
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  List<String> get photoUrls => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError; // Location
  String get locationLabel =>
      throw _privateConstructorUsedError; // Human-readable: "Blk 123 AMK Ave 6"
  String? get neighbourhood => throw _privateConstructorUsedError;
  GeoPoint2? get location => throw _privateConstructorUsedError; // Pricing
  double get budgetMin => throw _privateConstructorUsedError;
  double? get budgetMax => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError; // Timing
  TaskUrgency get urgency => throw _privateConstructorUsedError;
  DateTime? get scheduledDate => throw _privateConstructorUsedError;
  int? get estimatedDurationMins =>
      throw _privateConstructorUsedError; // Status
  TaskStatus get status => throw _privateConstructorUsedError;
  String? get assignedProviderId => throw _privateConstructorUsedError;
  String? get assignedProviderName =>
      throw _privateConstructorUsedError; // Counts
  int get bidCount => throw _privateConstructorUsedError;
  int get viewCount => throw _privateConstructorUsedError; // Timestamps
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError; // Direct Hire
  bool get isDirectHire => throw _privateConstructorUsedError; // Payment
  String? get paymentIntentId => throw _privateConstructorUsedError;
  bool get isPaid => throw _privateConstructorUsedError;
  bool get isEscrowReleased => throw _privateConstructorUsedError;

  /// Serializes this TaskModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskModelCopyWith<TaskModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskModelCopyWith<$Res> {
  factory $TaskModelCopyWith(TaskModel value, $Res Function(TaskModel) then) =
      _$TaskModelCopyWithImpl<$Res, TaskModel>;
  @useResult
  $Res call(
      {String id,
      String posterId,
      String? posterName,
      String? posterAvatarUrl,
      String title,
      String description,
      String categoryId,
      List<String> photoUrls,
      List<String> tags,
      String locationLabel,
      String? neighbourhood,
      GeoPoint2? location,
      double budgetMin,
      double? budgetMax,
      String currency,
      TaskUrgency urgency,
      DateTime? scheduledDate,
      int? estimatedDurationMins,
      TaskStatus status,
      String? assignedProviderId,
      String? assignedProviderName,
      int bidCount,
      int viewCount,
      DateTime? createdAt,
      DateTime? updatedAt,
      DateTime? completedAt,
      DateTime? expiresAt,
      bool isDirectHire,
      String? paymentIntentId,
      bool isPaid,
      bool isEscrowReleased});

  $GeoPoint2CopyWith<$Res>? get location;
}

/// @nodoc
class _$TaskModelCopyWithImpl<$Res, $Val extends TaskModel>
    implements $TaskModelCopyWith<$Res> {
  _$TaskModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? posterId = null,
    Object? posterName = freezed,
    Object? posterAvatarUrl = freezed,
    Object? title = null,
    Object? description = null,
    Object? categoryId = null,
    Object? photoUrls = null,
    Object? tags = null,
    Object? locationLabel = null,
    Object? neighbourhood = freezed,
    Object? location = freezed,
    Object? budgetMin = null,
    Object? budgetMax = freezed,
    Object? currency = null,
    Object? urgency = null,
    Object? scheduledDate = freezed,
    Object? estimatedDurationMins = freezed,
    Object? status = null,
    Object? assignedProviderId = freezed,
    Object? assignedProviderName = freezed,
    Object? bidCount = null,
    Object? viewCount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? completedAt = freezed,
    Object? expiresAt = freezed,
    Object? isDirectHire = null,
    Object? paymentIntentId = freezed,
    Object? isPaid = null,
    Object? isEscrowReleased = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      posterId: null == posterId
          ? _value.posterId
          : posterId // ignore: cast_nullable_to_non_nullable
              as String,
      posterName: freezed == posterName
          ? _value.posterName
          : posterName // ignore: cast_nullable_to_non_nullable
              as String?,
      posterAvatarUrl: freezed == posterAvatarUrl
          ? _value.posterAvatarUrl
          : posterAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrls: null == photoUrls
          ? _value.photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      locationLabel: null == locationLabel
          ? _value.locationLabel
          : locationLabel // ignore: cast_nullable_to_non_nullable
              as String,
      neighbourhood: freezed == neighbourhood
          ? _value.neighbourhood
          : neighbourhood // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint2?,
      budgetMin: null == budgetMin
          ? _value.budgetMin
          : budgetMin // ignore: cast_nullable_to_non_nullable
              as double,
      budgetMax: freezed == budgetMax
          ? _value.budgetMax
          : budgetMax // ignore: cast_nullable_to_non_nullable
              as double?,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      urgency: null == urgency
          ? _value.urgency
          : urgency // ignore: cast_nullable_to_non_nullable
              as TaskUrgency,
      scheduledDate: freezed == scheduledDate
          ? _value.scheduledDate
          : scheduledDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      estimatedDurationMins: freezed == estimatedDurationMins
          ? _value.estimatedDurationMins
          : estimatedDurationMins // ignore: cast_nullable_to_non_nullable
              as int?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TaskStatus,
      assignedProviderId: freezed == assignedProviderId
          ? _value.assignedProviderId
          : assignedProviderId // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedProviderName: freezed == assignedProviderName
          ? _value.assignedProviderName
          : assignedProviderName // ignore: cast_nullable_to_non_nullable
              as String?,
      bidCount: null == bidCount
          ? _value.bidCount
          : bidCount // ignore: cast_nullable_to_non_nullable
              as int,
      viewCount: null == viewCount
          ? _value.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isDirectHire: null == isDirectHire
          ? _value.isDirectHire
          : isDirectHire // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentIntentId: freezed == paymentIntentId
          ? _value.paymentIntentId
          : paymentIntentId // ignore: cast_nullable_to_non_nullable
              as String?,
      isPaid: null == isPaid
          ? _value.isPaid
          : isPaid // ignore: cast_nullable_to_non_nullable
              as bool,
      isEscrowReleased: null == isEscrowReleased
          ? _value.isEscrowReleased
          : isEscrowReleased // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GeoPoint2CopyWith<$Res>? get location {
    if (_value.location == null) {
      return null;
    }

    return $GeoPoint2CopyWith<$Res>(_value.location!, (value) {
      return _then(_value.copyWith(location: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TaskModelImplCopyWith<$Res>
    implements $TaskModelCopyWith<$Res> {
  factory _$$TaskModelImplCopyWith(
          _$TaskModelImpl value, $Res Function(_$TaskModelImpl) then) =
      __$$TaskModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String posterId,
      String? posterName,
      String? posterAvatarUrl,
      String title,
      String description,
      String categoryId,
      List<String> photoUrls,
      List<String> tags,
      String locationLabel,
      String? neighbourhood,
      GeoPoint2? location,
      double budgetMin,
      double? budgetMax,
      String currency,
      TaskUrgency urgency,
      DateTime? scheduledDate,
      int? estimatedDurationMins,
      TaskStatus status,
      String? assignedProviderId,
      String? assignedProviderName,
      int bidCount,
      int viewCount,
      DateTime? createdAt,
      DateTime? updatedAt,
      DateTime? completedAt,
      DateTime? expiresAt,
      bool isDirectHire,
      String? paymentIntentId,
      bool isPaid,
      bool isEscrowReleased});

  @override
  $GeoPoint2CopyWith<$Res>? get location;
}

/// @nodoc
class __$$TaskModelImplCopyWithImpl<$Res>
    extends _$TaskModelCopyWithImpl<$Res, _$TaskModelImpl>
    implements _$$TaskModelImplCopyWith<$Res> {
  __$$TaskModelImplCopyWithImpl(
      _$TaskModelImpl _value, $Res Function(_$TaskModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? posterId = null,
    Object? posterName = freezed,
    Object? posterAvatarUrl = freezed,
    Object? title = null,
    Object? description = null,
    Object? categoryId = null,
    Object? photoUrls = null,
    Object? tags = null,
    Object? locationLabel = null,
    Object? neighbourhood = freezed,
    Object? location = freezed,
    Object? budgetMin = null,
    Object? budgetMax = freezed,
    Object? currency = null,
    Object? urgency = null,
    Object? scheduledDate = freezed,
    Object? estimatedDurationMins = freezed,
    Object? status = null,
    Object? assignedProviderId = freezed,
    Object? assignedProviderName = freezed,
    Object? bidCount = null,
    Object? viewCount = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? completedAt = freezed,
    Object? expiresAt = freezed,
    Object? isDirectHire = null,
    Object? paymentIntentId = freezed,
    Object? isPaid = null,
    Object? isEscrowReleased = null,
  }) {
    return _then(_$TaskModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      posterId: null == posterId
          ? _value.posterId
          : posterId // ignore: cast_nullable_to_non_nullable
              as String,
      posterName: freezed == posterName
          ? _value.posterName
          : posterName // ignore: cast_nullable_to_non_nullable
              as String?,
      posterAvatarUrl: freezed == posterAvatarUrl
          ? _value.posterAvatarUrl
          : posterAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrls: null == photoUrls
          ? _value._photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      locationLabel: null == locationLabel
          ? _value.locationLabel
          : locationLabel // ignore: cast_nullable_to_non_nullable
              as String,
      neighbourhood: freezed == neighbourhood
          ? _value.neighbourhood
          : neighbourhood // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint2?,
      budgetMin: null == budgetMin
          ? _value.budgetMin
          : budgetMin // ignore: cast_nullable_to_non_nullable
              as double,
      budgetMax: freezed == budgetMax
          ? _value.budgetMax
          : budgetMax // ignore: cast_nullable_to_non_nullable
              as double?,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      urgency: null == urgency
          ? _value.urgency
          : urgency // ignore: cast_nullable_to_non_nullable
              as TaskUrgency,
      scheduledDate: freezed == scheduledDate
          ? _value.scheduledDate
          : scheduledDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      estimatedDurationMins: freezed == estimatedDurationMins
          ? _value.estimatedDurationMins
          : estimatedDurationMins // ignore: cast_nullable_to_non_nullable
              as int?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TaskStatus,
      assignedProviderId: freezed == assignedProviderId
          ? _value.assignedProviderId
          : assignedProviderId // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedProviderName: freezed == assignedProviderName
          ? _value.assignedProviderName
          : assignedProviderName // ignore: cast_nullable_to_non_nullable
              as String?,
      bidCount: null == bidCount
          ? _value.bidCount
          : bidCount // ignore: cast_nullable_to_non_nullable
              as int,
      viewCount: null == viewCount
          ? _value.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isDirectHire: null == isDirectHire
          ? _value.isDirectHire
          : isDirectHire // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentIntentId: freezed == paymentIntentId
          ? _value.paymentIntentId
          : paymentIntentId // ignore: cast_nullable_to_non_nullable
              as String?,
      isPaid: null == isPaid
          ? _value.isPaid
          : isPaid // ignore: cast_nullable_to_non_nullable
              as bool,
      isEscrowReleased: null == isEscrowReleased
          ? _value.isEscrowReleased
          : isEscrowReleased // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskModelImpl implements _TaskModel {
  const _$TaskModelImpl(
      {required this.id,
      required this.posterId,
      this.posterName,
      this.posterAvatarUrl,
      required this.title,
      required this.description,
      required this.categoryId,
      final List<String> photoUrls = const [],
      final List<String> tags = const [],
      required this.locationLabel,
      this.neighbourhood,
      this.location,
      required this.budgetMin,
      this.budgetMax,
      this.currency = 'SGD',
      required this.urgency,
      this.scheduledDate,
      this.estimatedDurationMins,
      this.status = TaskStatus.open,
      this.assignedProviderId,
      this.assignedProviderName,
      this.bidCount = 0,
      this.viewCount = 0,
      this.createdAt,
      this.updatedAt,
      this.completedAt,
      this.expiresAt,
      this.isDirectHire = false,
      this.paymentIntentId,
      this.isPaid = false,
      this.isEscrowReleased = false})
      : _photoUrls = photoUrls,
        _tags = tags;

  factory _$TaskModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskModelImplFromJson(json);

  @override
  final String id;
  @override
  final String posterId;
  @override
  final String? posterName;
  @override
  final String? posterAvatarUrl;
// Content
  @override
  final String title;
  @override
  final String description;
  @override
  final String categoryId;
  final List<String> _photoUrls;
  @override
  @JsonKey()
  List<String> get photoUrls {
    if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoUrls);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

// Location
  @override
  final String locationLabel;
// Human-readable: "Blk 123 AMK Ave 6"
  @override
  final String? neighbourhood;
  @override
  final GeoPoint2? location;
// Pricing
  @override
  final double budgetMin;
  @override
  final double? budgetMax;
  @override
  @JsonKey()
  final String currency;
// Timing
  @override
  final TaskUrgency urgency;
  @override
  final DateTime? scheduledDate;
  @override
  final int? estimatedDurationMins;
// Status
  @override
  @JsonKey()
  final TaskStatus status;
  @override
  final String? assignedProviderId;
  @override
  final String? assignedProviderName;
// Counts
  @override
  @JsonKey()
  final int bidCount;
  @override
  @JsonKey()
  final int viewCount;
// Timestamps
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? completedAt;
  @override
  final DateTime? expiresAt;
// Direct Hire
  @override
  @JsonKey()
  final bool isDirectHire;
// Payment
  @override
  final String? paymentIntentId;
  @override
  @JsonKey()
  final bool isPaid;
  @override
  @JsonKey()
  final bool isEscrowReleased;

  @override
  String toString() {
    return 'TaskModel(id: $id, posterId: $posterId, posterName: $posterName, posterAvatarUrl: $posterAvatarUrl, title: $title, description: $description, categoryId: $categoryId, photoUrls: $photoUrls, tags: $tags, locationLabel: $locationLabel, neighbourhood: $neighbourhood, location: $location, budgetMin: $budgetMin, budgetMax: $budgetMax, currency: $currency, urgency: $urgency, scheduledDate: $scheduledDate, estimatedDurationMins: $estimatedDurationMins, status: $status, assignedProviderId: $assignedProviderId, assignedProviderName: $assignedProviderName, bidCount: $bidCount, viewCount: $viewCount, createdAt: $createdAt, updatedAt: $updatedAt, completedAt: $completedAt, expiresAt: $expiresAt, isDirectHire: $isDirectHire, paymentIntentId: $paymentIntentId, isPaid: $isPaid, isEscrowReleased: $isEscrowReleased)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.posterId, posterId) ||
                other.posterId == posterId) &&
            (identical(other.posterName, posterName) ||
                other.posterName == posterName) &&
            (identical(other.posterAvatarUrl, posterAvatarUrl) ||
                other.posterAvatarUrl == posterAvatarUrl) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            const DeepCollectionEquality()
                .equals(other._photoUrls, _photoUrls) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.locationLabel, locationLabel) ||
                other.locationLabel == locationLabel) &&
            (identical(other.neighbourhood, neighbourhood) ||
                other.neighbourhood == neighbourhood) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.budgetMin, budgetMin) ||
                other.budgetMin == budgetMin) &&
            (identical(other.budgetMax, budgetMax) ||
                other.budgetMax == budgetMax) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.urgency, urgency) || other.urgency == urgency) &&
            (identical(other.scheduledDate, scheduledDate) ||
                other.scheduledDate == scheduledDate) &&
            (identical(other.estimatedDurationMins, estimatedDurationMins) ||
                other.estimatedDurationMins == estimatedDurationMins) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.assignedProviderId, assignedProviderId) ||
                other.assignedProviderId == assignedProviderId) &&
            (identical(other.assignedProviderName, assignedProviderName) ||
                other.assignedProviderName == assignedProviderName) &&
            (identical(other.bidCount, bidCount) ||
                other.bidCount == bidCount) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.isDirectHire, isDirectHire) ||
                other.isDirectHire == isDirectHire) &&
            (identical(other.paymentIntentId, paymentIntentId) ||
                other.paymentIntentId == paymentIntentId) &&
            (identical(other.isPaid, isPaid) || other.isPaid == isPaid) &&
            (identical(other.isEscrowReleased, isEscrowReleased) ||
                other.isEscrowReleased == isEscrowReleased));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        posterId,
        posterName,
        posterAvatarUrl,
        title,
        description,
        categoryId,
        const DeepCollectionEquality().hash(_photoUrls),
        const DeepCollectionEquality().hash(_tags),
        locationLabel,
        neighbourhood,
        location,
        budgetMin,
        budgetMax,
        currency,
        urgency,
        scheduledDate,
        estimatedDurationMins,
        status,
        assignedProviderId,
        assignedProviderName,
        bidCount,
        viewCount,
        createdAt,
        updatedAt,
        completedAt,
        expiresAt,
        isDirectHire,
        paymentIntentId,
        isPaid,
        isEscrowReleased
      ]);

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskModelImplCopyWith<_$TaskModelImpl> get copyWith =>
      __$$TaskModelImplCopyWithImpl<_$TaskModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskModelImplToJson(
      this,
    );
  }
}

abstract class _TaskModel implements TaskModel {
  const factory _TaskModel(
      {required final String id,
      required final String posterId,
      final String? posterName,
      final String? posterAvatarUrl,
      required final String title,
      required final String description,
      required final String categoryId,
      final List<String> photoUrls,
      final List<String> tags,
      required final String locationLabel,
      final String? neighbourhood,
      final GeoPoint2? location,
      required final double budgetMin,
      final double? budgetMax,
      final String currency,
      required final TaskUrgency urgency,
      final DateTime? scheduledDate,
      final int? estimatedDurationMins,
      final TaskStatus status,
      final String? assignedProviderId,
      final String? assignedProviderName,
      final int bidCount,
      final int viewCount,
      final DateTime? createdAt,
      final DateTime? updatedAt,
      final DateTime? completedAt,
      final DateTime? expiresAt,
      final bool isDirectHire,
      final String? paymentIntentId,
      final bool isPaid,
      final bool isEscrowReleased}) = _$TaskModelImpl;

  factory _TaskModel.fromJson(Map<String, dynamic> json) =
      _$TaskModelImpl.fromJson;

  @override
  String get id;
  @override
  String get posterId;
  @override
  String? get posterName;
  @override
  String? get posterAvatarUrl; // Content
  @override
  String get title;
  @override
  String get description;
  @override
  String get categoryId;
  @override
  List<String> get photoUrls;
  @override
  List<String> get tags; // Location
  @override
  String get locationLabel; // Human-readable: "Blk 123 AMK Ave 6"
  @override
  String? get neighbourhood;
  @override
  GeoPoint2? get location; // Pricing
  @override
  double get budgetMin;
  @override
  double? get budgetMax;
  @override
  String get currency; // Timing
  @override
  TaskUrgency get urgency;
  @override
  DateTime? get scheduledDate;
  @override
  int? get estimatedDurationMins; // Status
  @override
  TaskStatus get status;
  @override
  String? get assignedProviderId;
  @override
  String? get assignedProviderName; // Counts
  @override
  int get bidCount;
  @override
  int get viewCount; // Timestamps
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  DateTime? get completedAt;
  @override
  DateTime? get expiresAt; // Direct Hire
  @override
  bool get isDirectHire; // Payment
  @override
  String? get paymentIntentId;
  @override
  bool get isPaid;
  @override
  bool get isEscrowReleased;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskModelImplCopyWith<_$TaskModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
