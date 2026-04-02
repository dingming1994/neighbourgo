import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/services/data/models/service_listing_model.dart';

void main() {
  group('ServiceListingModel', () {
    test('fromJson/toJson roundtrip with all fields', () {
      final listing = ServiceListingModel(
        id: 'sl-001',
        providerId: 'prov-001',
        providerName: 'Alice Tan',
        categoryId: 'cleaning',
        title: 'Professional Deep Cleaning',
        description: 'Thorough cleaning of HDB and condos',
        photoUrls: ['https://example.com/photo1.jpg'],
        hourlyRate: 35.0,
        fixedRate: 120.0,
        availability: 'Weekdays 9am-6pm',
        neighbourhood: 'Ang Mo Kio',
        createdAt: DateTime(2026, 4, 1),
        isActive: true,
      );

      final json = listing.toJson();
      final restored = ServiceListingModel.fromJson(json);
      expect(restored, listing);
    });

    test('fromJson with minimal required fields', () {
      final json = {
        'id': 'sl-002',
        'providerId': 'prov-002',
        'providerName': 'Bob Lee',
        'categoryId': 'tutoring',
        'title': 'Math Tutor',
        'description': 'Primary to JC level',
      };

      final listing = ServiceListingModel.fromJson(json);
      expect(listing.id, 'sl-002');
      expect(listing.photoUrls, isEmpty);
      expect(listing.hourlyRate, isNull);
      expect(listing.fixedRate, isNull);
      expect(listing.isActive, true);
    });

    test('copyWith creates new instance with updated fields', () {
      const listing = ServiceListingModel(
        id: 'sl-001',
        providerId: 'prov-001',
        providerName: 'Alice',
        categoryId: 'cleaning',
        title: 'Cleaning Service',
        description: 'Great cleaning',
      );

      final updated = listing.copyWith(title: 'Updated Title', isActive: false);
      expect(updated.title, 'Updated Title');
      expect(updated.isActive, false);
      expect(updated.id, 'sl-001');
    });
  });

  group('ServiceListingModelExt', () {
    test('rateDisplay shows hourly rate', () {
      const listing = ServiceListingModel(
        id: 'sl-001',
        providerId: 'p',
        providerName: 'A',
        categoryId: 'cleaning',
        title: 'T',
        description: 'D',
        hourlyRate: 35.0,
      );
      expect(listing.rateDisplay, 'S\$35/hr');
    });

    test('rateDisplay shows fixed rate', () {
      const listing = ServiceListingModel(
        id: 'sl-001',
        providerId: 'p',
        providerName: 'A',
        categoryId: 'cleaning',
        title: 'T',
        description: 'D',
        fixedRate: 120.0,
      );
      expect(listing.rateDisplay, 'S\$120 fixed');
    });

    test('rateDisplay shows both rates', () {
      const listing = ServiceListingModel(
        id: 'sl-001',
        providerId: 'p',
        providerName: 'A',
        categoryId: 'cleaning',
        title: 'T',
        description: 'D',
        hourlyRate: 35.0,
        fixedRate: 120.0,
      );
      expect(listing.rateDisplay, contains('S\$35/hr'));
      expect(listing.rateDisplay, contains('S\$120 fixed'));
    });

    test('rateDisplay shows contact for pricing when no rates', () {
      const listing = ServiceListingModel(
        id: 'sl-001',
        providerId: 'p',
        providerName: 'A',
        categoryId: 'cleaning',
        title: 'T',
        description: 'D',
      );
      expect(listing.rateDisplay, 'Contact for pricing');
    });
  });
}
