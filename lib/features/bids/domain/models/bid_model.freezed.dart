// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bid_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BidModel _$BidModelFromJson(Map<String, dynamic> json) {
  return _BidModel.fromJson(json);
}

/// @nodoc
mixin _$BidModel {
  String get bidId => throw _privateConstructorUsedError;
  String get taskId => throw _privateConstructorUsedError;
  String get providerId => throw _privateConstructorUsedError;
  String get providerName => throw _privateConstructorUsedError;
  String? get providerAvatar => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  BidStatus get status => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this BidModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BidModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BidModelCopyWith<BidModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BidModelCopyWith<$Res> {
  factory $BidModelCopyWith(BidModel value, $Res Function(BidModel) then) =
      _$BidModelCopyWithImpl<$Res, BidModel>;
  @useResult
  $Res call(
      {String bidId,
      String taskId,
      String providerId,
      String providerName,
      String? providerAvatar,
      double amount,
      String? message,
      BidStatus status,
      DateTime? createdAt});
}

/// @nodoc
class _$BidModelCopyWithImpl<$Res, $Val extends BidModel>
    implements $BidModelCopyWith<$Res> {
  _$BidModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BidModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bidId = null,
    Object? taskId = null,
    Object? providerId = null,
    Object? providerName = null,
    Object? providerAvatar = freezed,
    Object? amount = null,
    Object? message = freezed,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      bidId: null == bidId
          ? _value.bidId
          : bidId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      providerId: null == providerId
          ? _value.providerId
          : providerId // ignore: cast_nullable_to_non_nullable
              as String,
      providerName: null == providerName
          ? _value.providerName
          : providerName // ignore: cast_nullable_to_non_nullable
              as String,
      providerAvatar: freezed == providerAvatar
          ? _value.providerAvatar
          : providerAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as BidStatus,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BidModelImplCopyWith<$Res>
    implements $BidModelCopyWith<$Res> {
  factory _$$BidModelImplCopyWith(
          _$BidModelImpl value, $Res Function(_$BidModelImpl) then) =
      __$$BidModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String bidId,
      String taskId,
      String providerId,
      String providerName,
      String? providerAvatar,
      double amount,
      String? message,
      BidStatus status,
      DateTime? createdAt});
}

/// @nodoc
class __$$BidModelImplCopyWithImpl<$Res>
    extends _$BidModelCopyWithImpl<$Res, _$BidModelImpl>
    implements _$$BidModelImplCopyWith<$Res> {
  __$$BidModelImplCopyWithImpl(
      _$BidModelImpl _value, $Res Function(_$BidModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of BidModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bidId = null,
    Object? taskId = null,
    Object? providerId = null,
    Object? providerName = null,
    Object? providerAvatar = freezed,
    Object? amount = null,
    Object? message = freezed,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$BidModelImpl(
      bidId: null == bidId
          ? _value.bidId
          : bidId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      providerId: null == providerId
          ? _value.providerId
          : providerId // ignore: cast_nullable_to_non_nullable
              as String,
      providerName: null == providerName
          ? _value.providerName
          : providerName // ignore: cast_nullable_to_non_nullable
              as String,
      providerAvatar: freezed == providerAvatar
          ? _value.providerAvatar
          : providerAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as BidStatus,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BidModelImpl implements _BidModel {
  const _$BidModelImpl(
      {required this.bidId,
      required this.taskId,
      required this.providerId,
      required this.providerName,
      this.providerAvatar,
      required this.amount,
      this.message,
      this.status = BidStatus.pending,
      this.createdAt});

  factory _$BidModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BidModelImplFromJson(json);

  @override
  final String bidId;
  @override
  final String taskId;
  @override
  final String providerId;
  @override
  final String providerName;
  @override
  final String? providerAvatar;
  @override
  final double amount;
  @override
  final String? message;
  @override
  @JsonKey()
  final BidStatus status;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'BidModel(bidId: $bidId, taskId: $taskId, providerId: $providerId, providerName: $providerName, providerAvatar: $providerAvatar, amount: $amount, message: $message, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BidModelImpl &&
            (identical(other.bidId, bidId) || other.bidId == bidId) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.providerId, providerId) ||
                other.providerId == providerId) &&
            (identical(other.providerName, providerName) ||
                other.providerName == providerName) &&
            (identical(other.providerAvatar, providerAvatar) ||
                other.providerAvatar == providerAvatar) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, bidId, taskId, providerId,
      providerName, providerAvatar, amount, message, status, createdAt);

  /// Create a copy of BidModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BidModelImplCopyWith<_$BidModelImpl> get copyWith =>
      __$$BidModelImplCopyWithImpl<_$BidModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BidModelImplToJson(
      this,
    );
  }
}

abstract class _BidModel implements BidModel {
  const factory _BidModel(
      {required final String bidId,
      required final String taskId,
      required final String providerId,
      required final String providerName,
      final String? providerAvatar,
      required final double amount,
      final String? message,
      final BidStatus status,
      final DateTime? createdAt}) = _$BidModelImpl;

  factory _BidModel.fromJson(Map<String, dynamic> json) =
      _$BidModelImpl.fromJson;

  @override
  String get bidId;
  @override
  String get taskId;
  @override
  String get providerId;
  @override
  String get providerName;
  @override
  String? get providerAvatar;
  @override
  double get amount;
  @override
  String? get message;
  @override
  BidStatus get status;
  @override
  DateTime? get createdAt;

  /// Create a copy of BidModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BidModelImplCopyWith<_$BidModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
