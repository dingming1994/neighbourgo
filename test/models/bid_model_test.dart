import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/bids/domain/models/bid_model.dart';

void main() {
  group('BidStatus', () {
    test('has exactly 3 values', () {
      expect(BidStatus.values.length, 3);
    });

    test('contains pending, accepted, rejected', () {
      expect(BidStatus.values, containsAll([
        BidStatus.pending,
        BidStatus.accepted,
        BidStatus.rejected,
      ]));
    });
  });

  group('BidModel', () {
    final fullJson = {
      'bidId': 'bid1',
      'taskId': 'task1',
      'providerId': 'prov1',
      'providerName': 'Bob',
      'providerAvatar': 'https://example.com/avatar.jpg',
      'amount': 75.0,
      'message': 'I can do this',
      'status': 'pending',
      'createdAt': '2026-03-28T10:00:00.000',
    };

    test('fromJson/toJson roundtrip', () {
      final bid = BidModel.fromJson(fullJson);
      final json = bid.toJson();
      final restored = BidModel.fromJson(json);
      expect(restored, bid);
    });

    test('default status is BidStatus.pending', () {
      final bid = BidModel.fromJson({
        'bidId': 'bid1',
        'taskId': 'task1',
        'providerId': 'prov1',
        'providerName': 'Bob',
        'amount': 75.0,
      });
      expect(bid.status, BidStatus.pending);
    });

    test('all fields populated correctly', () {
      final bid = BidModel.fromJson(fullJson);
      expect(bid.bidId, 'bid1');
      expect(bid.taskId, 'task1');
      expect(bid.providerId, 'prov1');
      expect(bid.providerName, 'Bob');
      expect(bid.providerAvatar, 'https://example.com/avatar.jpg');
      expect(bid.amount, 75.0);
      expect(bid.message, 'I can do this');
      expect(bid.status, BidStatus.pending);
    });

    test('optional fields default to null', () {
      const bid = BidModel(
        bidId: 'b1',
        taskId: 't1',
        providerId: 'p1',
        providerName: 'Bob',
        amount: 50.0,
      );
      expect(bid.providerAvatar, isNull);
      expect(bid.message, isNull);
      expect(bid.createdAt, isNull);
    });
  });
}
