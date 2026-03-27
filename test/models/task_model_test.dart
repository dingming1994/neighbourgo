import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/tasks/data/models/task_model.dart';

void main() {
  group('TaskStatus', () {
    test('has exactly 6 values', () {
      expect(TaskStatus.values.length, 6);
    });

    test('contains all expected values', () {
      expect(TaskStatus.values, containsAll([
        TaskStatus.open,
        TaskStatus.assigned,
        TaskStatus.inProgress,
        TaskStatus.completed,
        TaskStatus.cancelled,
        TaskStatus.disputed,
      ]));
    });
  });

  group('TaskUrgency', () {
    test('has exactly 3 values', () {
      expect(TaskUrgency.values.length, 3);
    });

    test('contains flexible, today, asap', () {
      expect(TaskUrgency.values, containsAll([
        TaskUrgency.flexible,
        TaskUrgency.today,
        TaskUrgency.asap,
      ]));
    });
  });

  group('GeoPoint2', () {
    test('fromJson/toJson roundtrip', () {
      const geo = GeoPoint2(lat: 1.3521, lng: 103.8198);
      final json = geo.toJson();
      final restored = GeoPoint2.fromJson(json);
      expect(restored, geo);
    });

    test('stores lat and lng correctly', () {
      const geo = GeoPoint2(lat: 1.35, lng: 103.82);
      expect(geo.lat, 1.35);
      expect(geo.lng, 103.82);
    });
  });

  group('TaskModel', () {
    final fullJson = {
      'id': 'task1',
      'posterId': 'poster1',
      'posterName': 'Alice',
      'posterAvatarUrl': 'https://example.com/avatar.jpg',
      'title': 'Clean my house',
      'description': 'Deep clean needed',
      'categoryId': 'cleaning',
      'photoUrls': ['https://example.com/p1.jpg'],
      'tags': ['cleaning', 'deep'],
      'locationLabel': 'Blk 123 AMK Ave 6',
      'neighbourhood': 'Ang Mo Kio',
      'location': {'lat': 1.3521, 'lng': 103.8198},
      'budgetMin': 50.0,
      'budgetMax': 100.0,
      'currency': 'SGD',
      'urgency': 'asap',
      'scheduledDate': '2026-04-01T00:00:00.000',
      'estimatedDurationMins': 120,
      'status': 'open',
      'assignedProviderId': null,
      'assignedProviderName': null,
      'bidCount': 3,
      'viewCount': 15,
      'createdAt': '2026-03-28T00:00:00.000',
      'updatedAt': '2026-03-28T12:00:00.000',
      'completedAt': null,
      'expiresAt': '2026-04-28T00:00:00.000',
      'paymentIntentId': null,
      'isPaid': false,
      'isEscrowReleased': false,
    };

    test('fromJson/toJson roundtrip with all fields', () {
      final task = TaskModel.fromJson(fullJson);
      final json = jsonDecode(jsonEncode(task.toJson())) as Map<String, dynamic>;
      final restored = TaskModel.fromJson(json);
      expect(restored, task);
    });

    test('fromJson with minimal required fields', () {
      final task = TaskModel.fromJson({
        'id': 'task1',
        'posterId': 'poster1',
        'title': 'Clean',
        'description': 'Clean my house',
        'categoryId': 'cleaning',
        'locationLabel': 'Blk 123',
        'budgetMin': 50.0,
        'urgency': 'flexible',
      });
      expect(task.id, 'task1');
      expect(task.posterId, 'poster1');
      expect(task.title, 'Clean');
      expect(task.status, TaskStatus.open);
      expect(task.photoUrls, isEmpty);
      expect(task.tags, isEmpty);
      expect(task.bidCount, 0);
      expect(task.viewCount, 0);
      expect(task.isPaid, false);
      expect(task.isEscrowReleased, false);
      expect(task.budgetMax, isNull);
      expect(task.currency, 'SGD');
    });

    test('status defaults to open', () {
      final task = TaskModel.fromJson({
        'id': 't1',
        'posterId': 'p1',
        'title': 'T',
        'description': 'D',
        'categoryId': 'c',
        'locationLabel': 'L',
        'budgetMin': 10.0,
        'urgency': 'flexible',
      });
      expect(task.status, TaskStatus.open);
    });
  });

  group('TaskModelExt', () {
    TaskModel makeTask({TaskStatus status = TaskStatus.open, double budgetMin = 50, double? budgetMax, TaskUrgency urgency = TaskUrgency.flexible}) {
      return TaskModel(
        id: 't1',
        posterId: 'p1',
        title: 'Test',
        description: 'Desc',
        categoryId: 'cleaning',
        locationLabel: 'Blk 1',
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        urgency: urgency,
        status: status,
      );
    }

    test('isOpen returns true for open status', () {
      expect(makeTask(status: TaskStatus.open).isOpen, true);
      expect(makeTask(status: TaskStatus.assigned).isOpen, false);
    });

    test('isAssigned returns true for assigned and inProgress', () {
      expect(makeTask(status: TaskStatus.assigned).isAssigned, true);
      expect(makeTask(status: TaskStatus.inProgress).isAssigned, true);
      expect(makeTask(status: TaskStatus.open).isAssigned, false);
      expect(makeTask(status: TaskStatus.completed).isAssigned, false);
    });

    test('isCompleted returns true for completed status', () {
      expect(makeTask(status: TaskStatus.completed).isCompleted, true);
      expect(makeTask(status: TaskStatus.open).isCompleted, false);
    });

    test('budgetDisplay formats single budget as S\$X', () {
      final task = makeTask(budgetMin: 50);
      expect(task.budgetDisplay, 'S\$50.0');
    });

    test('budgetDisplay formats range as S\$X–S\$Y', () {
      final task = makeTask(budgetMin: 50, budgetMax: 100);
      expect(task.budgetDisplay, 'S\$50.0–S\$100.0');
    });

    test('urgencyDisplay returns correct emoji and text', () {
      expect(makeTask(urgency: TaskUrgency.asap).urgencyDisplay, '🔴 ASAP');
      expect(makeTask(urgency: TaskUrgency.today).urgencyDisplay, '🟡 Today');
      expect(makeTask(urgency: TaskUrgency.flexible).urgencyDisplay, '🟢 Flexible');
    });
  });
}
