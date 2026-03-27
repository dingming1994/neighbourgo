import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/chat/domain/models/message_model.dart';

void main() {
  group('MessageModel', () {
    final fullJson = {
      'messageId': 'msg1',
      'chatId': 'chat1',
      'senderId': 'userA',
      'text': 'Hello there',
      'imageUrl': 'https://example.com/img.jpg',
      'timestamp': '2026-03-28T12:00:00.000',
      'isRead': true,
    };

    test('fromJson/toJson roundtrip', () {
      final msg = MessageModel.fromJson(fullJson);
      final json = msg.toJson();
      final restored = MessageModel.fromJson(json);
      expect(restored, msg);
    });

    test('isRead defaults to false', () {
      final msg = MessageModel.fromJson({
        'messageId': 'm1',
        'chatId': 'c1',
        'senderId': 's1',
        'timestamp': '2026-03-28T00:00:00.000',
      });
      expect(msg.isRead, false);
    });

    test('text and imageUrl are nullable', () {
      final msg = MessageModel(
        messageId: 'm1',
        chatId: 'c1',
        senderId: 's1',
        timestamp: DateTime(2026, 3, 28),
      );
      expect(msg.text, isNull);
      expect(msg.imageUrl, isNull);
    });

    test('all fields populated correctly', () {
      final msg = MessageModel.fromJson(fullJson);
      expect(msg.messageId, 'msg1');
      expect(msg.chatId, 'chat1');
      expect(msg.senderId, 'userA');
      expect(msg.text, 'Hello there');
      expect(msg.imageUrl, 'https://example.com/img.jpg');
      expect(msg.isRead, true);
    });
  });
}
