import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/chat/domain/models/chat_model.dart';

void main() {
  group('ChatModel', () {
    final fullJson = {
      'chatId': 'chat1',
      'taskId': 'task1',
      'taskTitle': 'Clean my house',
      'participants': ['userA', 'userB'],
      'lastMessage': 'Hello!',
      'lastMessageTime': '2026-03-28T12:00:00.000',
      'unreadCount': 2,
    };

    test('fromJson/toJson roundtrip', () {
      final chat = ChatModel.fromJson(fullJson);
      final json = chat.toJson();
      final restored = ChatModel.fromJson(json);
      expect(restored, chat);
    });

    test('participants list is correctly populated', () {
      final chat = ChatModel.fromJson(fullJson);
      expect(chat.participants, ['userA', 'userB']);
      expect(chat.participants.length, 2);
    });

    test('defaults: participants empty, unreadCount 0', () {
      final chat = ChatModel.fromJson({
        'chatId': 'c1',
        'taskId': 't1',
        'taskTitle': 'Task',
      });
      expect(chat.participants, isEmpty);
      expect(chat.unreadCount, 0);
      expect(chat.lastMessage, isNull);
      expect(chat.lastMessageTime, isNull);
    });

    test('all fields populated correctly', () {
      final chat = ChatModel.fromJson(fullJson);
      expect(chat.chatId, 'chat1');
      expect(chat.taskId, 'task1');
      expect(chat.taskTitle, 'Clean my house');
      expect(chat.lastMessage, 'Hello!');
      expect(chat.unreadCount, 2);
    });
  });
}
