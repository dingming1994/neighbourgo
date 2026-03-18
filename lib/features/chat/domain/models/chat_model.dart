import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

@freezed
class ChatModel with _$ChatModel {
  const factory ChatModel({
    required String chatId,
    required String taskId,
    required String taskTitle,
    @Default([]) List<String> participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    @Default(0) int unreadCount,
  }) = _ChatModel;

  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);
}
