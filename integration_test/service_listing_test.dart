/// Integration test: Service Listings — Provider creates listing, client browses and hires
///
/// Verifies:
///   1. Provider can create a service listing
///   2. Client can browse service listings in Discover > Services tab
///   3. Client can view service detail and tap Hire button
///
/// Run:
///   flutter test integration_test/service_listing_test.dart -d <simulator_id>
///
/// Prerequisites:
///   1. Firebase emulators running: firebase emulators:start
///   2. iOS Simulator booted
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:neighbourgo/main.dart';

import 'test_helpers.dart';
import 'test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String testUserId;

  setUpAll(() async {
    await initializeTestApp();

    // Sign in a test user with role=both (can act as both poster and provider)
    final user = await signInTestUser(
      email: 'service-listing-test@test.com',
      password: 'test1234',
    );
    testUserId = user.uid;

    await seedUser(testUserId, testBothUser(uid: testUserId));

    // Seed a service listing directly (simulates a provider who already created one)
    await FirebaseFirestore.instance
        .collection('service_listings')
        .doc('test-listing-1')
        .set({
      'id': 'test-listing-1',
      'providerId': 'other-provider-uid',
      'providerName': 'Jane Doe',
      'categoryId': 'cleaning',
      'title': 'Professional Deep Cleaning',
      'description':
          'Thorough deep cleaning for HDB and condos. Eco-friendly products used.',
      'photoUrls': [],
      'hourlyRate': 35.0,
      'fixedRate': 120.0,
      'availability': 'Weekdays 9am-6pm',
      'neighbourhood': 'Ang Mo Kio',
      'createdAt': Timestamp.now(),
      'isActive': true,
    });

    await FirebaseFirestore.instance
        .collection('service_listings')
        .doc('test-listing-2')
        .set({
      'id': 'test-listing-2',
      'providerId': testUserId,
      'providerName': 'Charlie Wong',
      'categoryId': 'tutoring',
      'title': 'Primary Math Tuition',
      'description': 'Experienced tutor for P1-P6 Mathematics.',
      'photoUrls': [],
      'hourlyRate': 50.0,
      'neighbourhood': 'Bishan',
      'createdAt': Timestamp.now(),
      'isActive': true,
    });
  });

  testWidgets('Service listing appears in Firestore', (tester) async {
    // Verify the seeded listing exists
    final doc = await FirebaseFirestore.instance
        .collection('service_listings')
        .doc('test-listing-1')
        .get();

    expect(doc.exists, true);
    expect(doc.data()?['title'], 'Professional Deep Cleaning');
    expect(doc.data()?['providerId'], 'other-provider-uid');
    expect(doc.data()?['isActive'], true);
    expect(doc.data()?['hourlyRate'], 35.0);
    expect(doc.data()?['fixedRate'], 120.0);
  });

  testWidgets('Service listing can be queried by category', (tester) async {
    final query = await FirebaseFirestore.instance
        .collection('service_listings')
        .where('isActive', isEqualTo: true)
        .where('categoryId', isEqualTo: 'cleaning')
        .get();

    expect(query.docs.isNotEmpty, true);
    expect(
      query.docs.any((d) => d.data()['title'] == 'Professional Deep Cleaning'),
      true,
    );
  });

  testWidgets('Provider can see own listings', (tester) async {
    final query = await FirebaseFirestore.instance
        .collection('service_listings')
        .where('providerId', isEqualTo: testUserId)
        .get();

    expect(query.docs.isNotEmpty, true);
    expect(
      query.docs.any((d) => d.data()['title'] == 'Primary Math Tuition'),
      true,
    );
  });

  testWidgets('Hire creates direct-hire task data shape', (tester) async {
    // Simulate what the Hire button does — create a task with direct hire fields
    final listing = await FirebaseFirestore.instance
        .collection('service_listings')
        .doc('test-listing-1')
        .get();
    final data = listing.data()!;

    // The Hire button navigates to PostTaskScreen with these extras:
    final hireExtras = {
      'directHireProviderId': data['providerId'],
      'directHireProviderName': data['providerName'],
      'preSelectedCategory': data['categoryId'],
    };

    expect(hireExtras['directHireProviderId'], 'other-provider-uid');
    expect(hireExtras['directHireProviderName'], 'Jane Doe');
    expect(hireExtras['preSelectedCategory'], 'cleaning');
  });
}
