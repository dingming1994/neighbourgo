// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_listing_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ServiceListingModel _$ServiceListingModelFromJson(Map<String, dynamic> json) {
  return _ServiceListingModel.fromJson(json);
}

/// @nodoc
mixin _$ServiceListingModel {
  String get id => throw _privateConstructorUsedError;
  String get providerId => throw _privateConstructorUsedError;
  String get providerName => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String> get photoUrls => throw _privateConstructorUsedError;
  double? get hourlyRate => throw _privateConstructorUsedError;
  double? get fixedRate => throw _privateConstructorUsedError;
  String? get availability => throw _privateConstructorUsedError;
  String? get neighbourhood => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this ServiceListingModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ServiceListingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServiceListingModelCopyWith<ServiceListingModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceListingModelCopyWith<$Res> {
  factory $ServiceListingModelCopyWith(
          ServiceListingModel value, $Res Function(ServiceListingModel) then) =
      _$ServiceListingModelCopyWithImpl<$Res, ServiceListingModel>;
  @useResult
  $Res call(
      {String id,
      String providerId,
      String providerName,
      String categoryId,
      String title,
      String description,
      List<String> photoUrls,
      double? hourlyRate,
      double? fixedRate,
      String? availability,
      String? neighbourhood,
      DateTime? createdAt,
      bool isActive});
}

/// @nodoc
class _$ServiceListingModelCopyWithImpl<$Res, $Val extends ServiceListingModel>
    implements $ServiceListingModelCopyWith<$Res> {
  _$ServiceListingModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServiceListingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? providerId = null,
    Object? providerName = null,
    Object? categoryId = null,
    Object? title = null,
    Object? description = null,
    Object? photoUrls = null,
    Object? hourlyRate = freezed,
    Object? fixedRate = freezed,
    Object? availability = freezed,
    Object? neighbourhood = freezed,
    Object? createdAt = freezed,
    Object? isActive = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      providerId: null == providerId
          ? _value.providerId
          : providerId // ignore: cast_nullable_to_non_nullable
              as String,
      providerName: null == providerName
          ? _value.providerName
          : providerName // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrls: null == photoUrls
          ? _value.photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      hourlyRate: freezed == hourlyRate
          ? _value.hourlyRate
          : hourlyRate // ignore: cast_nullable_to_non_nullable
              as double?,
      fixedRate: freezed == fixedRate
          ? _value.fixedRate
          : fixedRate // ignore: cast_nullable_to_non_nullable
              as double?,
      availability: freezed == availability
          ? _value.availability
          : availability // ignore: cast_nullable_to_non_nullable
              as String?,
      neighbourhood: freezed == neighbourhood
          ? _value.neighbourhood
          : neighbourhood // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ServiceListingModelImplCopyWith<$Res>
    implements $ServiceListingModelCopyWith<$Res> {
  factory _$$ServiceListingModelImplCopyWith(_$ServiceListingModelImpl value,
          $Res Function(_$ServiceListingModelImpl) then) =
      __$$ServiceListingModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String providerId,
      String providerName,
      String categoryId,
      String title,
      String description,
      List<String> photoUrls,
      double? hourlyRate,
      double? fixedRate,
      String? availability,
      String? neighbourhood,
      DateTime? createdAt,
      bool isActive});
}

/// @nodoc
class __$$ServiceListingModelImplCopyWithImpl<$Res>
    extends _$ServiceListingModelCopyWithImpl<$Res, _$ServiceListingModelImpl>
    implements _$$ServiceListingModelImplCopyWith<$Res> {
  __$$ServiceListingModelImplCopyWithImpl(_$ServiceListingModelImpl _value,
      $Res Function(_$ServiceListingModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServiceListingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? providerId = null,
    Object? providerName = null,
    Object? categoryId = null,
    Object? title = null,
    Object? description = null,
    Object? photoUrls = null,
    Object? hourlyRate = freezed,
    Object? fixedRate = freezed,
    Object? availability = freezed,
    Object? neighbourhood = freezed,
    Object? createdAt = freezed,
    Object? isActive = null,
  }) {
    return _then(_$ServiceListingModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      providerId: null == providerId
          ? _value.providerId
          : providerId // ignore: cast_nullable_to_non_nullable
              as String,
      providerName: null == providerName
          ? _value.providerName
          : providerName // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrls: null == photoUrls
          ? _value._photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      hourlyRate: freezed == hourlyRate
          ? _value.hourlyRate
          : hourlyRate // ignore: cast_nullable_to_non_nullable
              as double?,
      fixedRate: freezed == fixedRate
          ? _value.fixedRate
          : fixedRate // ignore: cast_nullable_to_non_nullable
              as double?,
      availability: freezed == availability
          ? _value.availability
          : availability // ignore: cast_nullable_to_non_nullable
              as String?,
      neighbourhood: freezed == neighbourhood
          ? _value.neighbourhood
          : neighbourhood // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ServiceListingModelImpl implements _ServiceListingModel {
  const _$ServiceListingModelImpl(
      {required this.id,
      required this.providerId,
      required this.providerName,
      required this.categoryId,
      required this.title,
      required this.description,
      final List<String> photoUrls = const [],
      this.hourlyRate,
      this.fixedRate,
      this.availability,
      this.neighbourhood,
      this.createdAt,
      this.isActive = true})
      : _photoUrls = photoUrls;

  factory _$ServiceListingModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServiceListingModelImplFromJson(json);

  @override
  final String id;
  @override
  final String providerId;
  @override
  final String providerName;
  @override
  final String categoryId;
  @override
  final String title;
  @override
  final String description;
  final List<String> _photoUrls;
  @override
  @JsonKey()
  List<String> get photoUrls {
    if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoUrls);
  }

  @override
  final double? hourlyRate;
  @override
  final double? fixedRate;
  @override
  final String? availability;
  @override
  final String? neighbourhood;
  @override
  final DateTime? createdAt;
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'ServiceListingModel(id: $id, providerId: $providerId, providerName: $providerName, categoryId: $categoryId, title: $title, description: $description, photoUrls: $photoUrls, hourlyRate: $hourlyRate, fixedRate: $fixedRate, availability: $availability, neighbourhood: $neighbourhood, createdAt: $createdAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceListingModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.providerId, providerId) ||
                other.providerId == providerId) &&
            (identical(other.providerName, providerName) ||
                other.providerName == providerName) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._photoUrls, _photoUrls) &&
            (identical(other.hourlyRate, hourlyRate) ||
                other.hourlyRate == hourlyRate) &&
            (identical(other.fixedRate, fixedRate) ||
                other.fixedRate == fixedRate) &&
            (identical(other.availability, availability) ||
                other.availability == availability) &&
            (identical(other.neighbourhood, neighbourhood) ||
                other.neighbourhood == neighbourhood) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      providerId,
      providerName,
      categoryId,
      title,
      description,
      const DeepCollectionEquality().hash(_photoUrls),
      hourlyRate,
      fixedRate,
      availability,
      neighbourhood,
      createdAt,
      isActive);

  /// Create a copy of ServiceListingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceListingModelImplCopyWith<_$ServiceListingModelImpl> get copyWith =>
      __$$ServiceListingModelImplCopyWithImpl<_$ServiceListingModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ServiceListingModelImplToJson(
      this,
    );
  }
}

abstract class _ServiceListingModel implements ServiceListingModel {
  const factory _ServiceListingModel(
      {required final String id,
      required final String providerId,
      required final String providerName,
      required final String categoryId,
      required final String title,
      required final String description,
      final List<String> photoUrls,
      final double? hourlyRate,
      final double? fixedRate,
      final String? availability,
      final String? neighbourhood,
      final DateTime? createdAt,
      final bool isActive}) = _$ServiceListingModelImpl;

  factory _ServiceListingModel.fromJson(Map<String, dynamic> json) =
      _$ServiceListingModelImpl.fromJson;

  @override
  String get id;
  @override
  String get providerId;
  @override
  String get providerName;
  @override
  String get categoryId;
  @override
  String get title;
  @override
  String get description;
  @override
  List<String> get photoUrls;
  @override
  double? get hourlyRate;
  @override
  double? get fixedRate;
  @override
  String? get availability;
  @override
  String? get neighbourhood;
  @override
  DateTime? get createdAt;
  @override
  bool get isActive;

  /// Create a copy of ServiceListingModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServiceListingModelImplCopyWith<_$ServiceListingModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
