import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Service category definitions
// ─────────────────────────────────────────────────────────────────────────────

class ServiceCategory {
  final String id;
  final String label;
  final String emoji;
  final String showcaseName;   // Profile showcase block label
  final String pricingAnchor;
  final Color  color;
  final List<String> taskExamples;
  final List<String> showcasePrompts; // Guide text for profile media uploads

  const ServiceCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.showcaseName,
    required this.pricingAnchor,
    required this.color,
    required this.taskExamples,
    required this.showcasePrompts,
  });
}

class AppCategories {
  AppCategories._();

  static const cleaning = ServiceCategory(
    id: 'cleaning',
    label: 'Home Cleaning',
    emoji: '🧹',
    showcaseName: 'My Cleaning Work',
    pricingAnchor: 'S\$25–80 / session',
    color: Color(0xFF29B6F6),
    taskExamples: ['Regular cleaning', 'Spring cleaning', 'Move-in/out', 'Carpet washing', 'Window cleaning'],
    showcasePrompts: [
      'Before/after cleaning photos',
      'Your cleaning equipment',
      'HDB vs condo experience',
      'Eco-friendly products you use',
    ],
  );

  static const tutoring = ServiceCategory(
    id: 'tutoring',
    label: 'Tutoring',
    emoji: '📚',
    showcaseName: 'Teaching Portfolio',
    pricingAnchor: 'S\$30–120 / hour',
    color: Color(0xFF7E57C2),
    taskExamples: ['Primary tuition', 'Secondary tuition', 'JC tuition', 'Language lessons', 'Coding classes'],
    showcasePrompts: [
      'Subjects & education levels you teach',
      'Sample lesson notes or worksheets',
      'Your academic background',
      'Teaching certifications',
    ],
  );

  static const petCare = ServiceCategory(
    id: 'pet_care',
    label: 'Pet Care',
    emoji: '🐾',
    showcaseName: 'My Pet Corner',
    pricingAnchor: 'S\$15–80 / session',
    color: Color(0xFFEF5350),
    taskExamples: ['Dog walking', 'Pet sitting', 'Home feeding visits', 'Grooming', 'Vet transport'],
    showcasePrompts: [
      'Photos with your own pets',
      'Breeds you are experienced with',
      'Your pet-handling style',
      'Types of animals you accept',
    ],
  );

  static const errands = ServiceCategory(
    id: 'errands',
    label: 'Errands',
    emoji: '🛍️',
    showcaseName: 'Errand History',
    pricingAnchor: 'S\$10–40 / errand',
    color: Color(0xFF66BB6A),
    taskExamples: ['Grocery shopping', 'Pharmacy pickup', 'Document delivery', 'Parcel collection', 'Bill payment'],
    showcasePrompts: [
      'Areas you cover (MRT lines/zones)',
      'Typical errand turnaround time',
      'Transport you use (bicycle, car, MRT)',
    ],
  );

  static const queuing = ServiceCategory(
    id: 'queuing',
    label: 'Queue Standing',
    emoji: '🧍',
    showcaseName: 'Queue Profile',
    pricingAnchor: 'S\$10–30 / queue',
    color: Color(0xFFFF7043),
    taskExamples: ['Hawker centre queuing', 'Government counters', 'Product launches', 'Restaurant reservations'],
    showcasePrompts: [
      'Locations you serve (hawker centres, offices)',
      'Max queue duration you handle',
      'Queue count history',
    ],
  );

  static const handyman = ServiceCategory(
    id: 'handyman',
    label: 'Handyman',
    emoji: '🔧',
    showcaseName: 'Past Jobs Gallery',
    pricingAnchor: 'S\$40–200 / job',
    color: Color(0xFF8D6E63),
    taskExamples: ['Furniture assembly', 'Minor plumbing', 'Electrical work', 'Painting', 'Wall mounting'],
    showcasePrompts: [
      'Photos of completed repairs/assembly',
      'Tools and equipment you own',
      'Certifications (plumbing, electrical)',
      'Job size range you handle',
    ],
  );

  static const moving = ServiceCategory(
    id: 'moving',
    label: 'Moving',
    emoji: '📦',
    showcaseName: 'Moving Experience',
    pricingAnchor: 'S\$50–300 / move',
    color: Color(0xFF26A69A),
    taskExamples: ['Small item moving', 'Furniture shifting', 'Rental van + helper', 'Office relocation'],
    showcasePrompts: [
      'Vehicle you have access to',
      'Maximum item weight',
      'Team size available',
    ],
  );

  static const personalCare = ServiceCategory(
    id: 'personal_care',
    label: 'Personal Care',
    emoji: '🤝',
    showcaseName: 'Care & Companion',
    pricingAnchor: 'S\$20–80 / hour',
    color: Color(0xFFEC407A),
    taskExamples: ['Elderly assistance', 'Wheelchair companion', 'Home nurse visits', 'Babysitting'],
    showcasePrompts: [
      'Training certificates',
      'Experience with special needs',
      'Languages spoken',
      'References from past care work',
    ],
  );

  static const admin = ServiceCategory(
    id: 'admin',
    label: 'Admin & Digital',
    emoji: '💻',
    showcaseName: 'Digital Skills Portfolio',
    pricingAnchor: 'S\$15–60 / hour',
    color: Color(0xFF78909C),
    taskExamples: ['Data entry', 'Form filling', 'Translation', 'Social media management', 'Virtual assistance'],
    showcasePrompts: [
      'Screenshots of past work (with consent)',
      'Software tools you know',
      'Typing speed',
      'Certifications (Microsoft, Google)',
    ],
  );

  static const events = ServiceCategory(
    id: 'events',
    label: 'Event Help',
    emoji: '🎉',
    showcaseName: 'Event Experience',
    pricingAnchor: 'S\$15–40 / hour',
    color: Color(0xFFFFCA28),
    taskExamples: ['Party setup/teardown', 'Ushering', 'Photography', 'Catering assistance'],
    showcasePrompts: [
      'Event photos you have helped at',
      'Types of events you assist',
      'Physical fitness level',
      'Languages for ushering',
    ],
  );

  static const List<ServiceCategory> all = [
    cleaning, tutoring, petCare, errands, queuing,
    handyman, moving, personalCare, admin, events,
  ];

  static ServiceCategory? getById(String id) {
    try { return all.firstWhere((c) => c.id == id); }
    catch (_) { return null; }
  }
}
