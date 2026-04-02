import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Country model for phone auth country code selection.
class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

/// Supported countries for phone auth.
const supportedCountries = [
  Country(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
  Country(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
  Country(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
  Country(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
  Country(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
  Country(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
  Country(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '🇵🇭'),
  Country(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩'),
  Country(name: 'Hong Kong', code: 'HK', dialCode: '+852', flag: '🇭🇰'),
  Country(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '🇹🇭'),
];

/// Default country (Singapore).
const defaultCountry = Country(
  name: 'Singapore',
  code: 'SG',
  dialCode: '+65',
  flag: '🇸🇬',
);

/// Shows a bottom sheet to pick a country code.
Future<Country?> showCountryCodePicker(BuildContext context) {
  return showModalBottomSheet<Country>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _CountryPickerSheet(),
  );
}

class _CountryPickerSheet extends StatelessWidget {
  const _CountryPickerSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Country',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: supportedCountries.length,
              itemBuilder: (ctx, i) {
                final country = supportedCountries[i];
                return ListTile(
                  leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(country.name),
                  trailing: Text(
                    country.dialCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
