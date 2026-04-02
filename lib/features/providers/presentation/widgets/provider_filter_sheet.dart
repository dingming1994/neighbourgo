import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/provider_list_provider.dart';

/// Common Singapore neighbourhoods for the filter dropdown.
const _neighbourhoods = [
  'Ang Mo Kio',
  'Bedok',
  'Bishan',
  'Bukit Batok',
  'Bukit Merah',
  'Bukit Panjang',
  'Bukit Timah',
  'Clementi',
  'Geylang',
  'Hougang',
  'Jurong East',
  'Jurong West',
  'Kallang',
  'Marine Parade',
  'Pasir Ris',
  'Punggol',
  'Queenstown',
  'Sembawang',
  'Sengkang',
  'Serangoon',
  'Tampines',
  'Toa Payoh',
  'Woodlands',
  'Yishun',
];

void showProviderFilterSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(providerFilterProvider);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ProviderFilterSheet(initial: current, ref: ref),
  );
}

class _ProviderFilterSheet extends StatefulWidget {
  final ProviderFilterState initial;
  final WidgetRef ref;

  const _ProviderFilterSheet({required this.initial, required this.ref});

  @override
  State<_ProviderFilterSheet> createState() => _ProviderFilterSheetState();
}

class _ProviderFilterSheetState extends State<_ProviderFilterSheet> {
  late double _minRating;
  String? _neighbourhood;
  late ProviderSortOption _sort;

  @override
  void initState() {
    super.initState();
    _minRating = widget.initial.minRating ?? 0;
    _neighbourhood = widget.initial.neighbourhood;
    _sort = widget.initial.sort;
  }

  bool get _hasFilters =>
      _minRating > 0 ||
      _neighbourhood != null ||
      _sort != ProviderSortOption.highestRated;

  void _clearAll() {
    setState(() {
      _minRating = 0;
      _neighbourhood = null;
      _sort = ProviderSortOption.highestRated;
    });
  }

  void _apply() {
    widget.ref.read(providerFilterProvider.notifier).state =
        ProviderFilterState(
      minRating: _minRating > 0 ? _minRating : null,
      neighbourhood: _neighbourhood,
      sort: _sort,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Header
              Row(
                children: [
                  Text(
                    'Filter & Sort',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  if (_hasFilters)
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('Clear all'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Min Rating
              Text(
                'Minimum Rating',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.star_rounded,
                      color: _minRating > 0
                          ? AppColors.accent
                          : AppColors.textHint,
                      size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _minRating > 0
                        ? '${_minRating.toStringAsFixed(1)}+'
                        : 'Any',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Slider(
                value: _minRating,
                min: 0,
                max: 5,
                divisions: 10,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.divider,
                label: _minRating > 0
                    ? _minRating.toStringAsFixed(1)
                    : 'Any',
                onChanged: (v) => setState(() => _minRating = v),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Neighbourhood
              Text(
                'Neighbourhood',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _neighbourhood,
                decoration: const InputDecoration(
                  hintText: 'Any neighbourhood',
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Any'),
                  ),
                  ..._neighbourhoods.map(
                    (n) => DropdownMenuItem(value: n, child: Text(n)),
                  ),
                ],
                onChanged: (v) => setState(() => _neighbourhood = v),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sort
              Text(
                'Sort by',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              _SortChips<ProviderSortOption>(
                options: ProviderSortOption.values,
                labels: const {
                  ProviderSortOption.highestRated: 'Highest Rated',
                  ProviderSortOption.mostReviews: 'Most Reviews',
                  ProviderSortOption.newest: 'Newest',
                },
                selected: _sort,
                onSelected: (v) => setState(() => _sort = v),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _apply,
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortChips<T> extends StatelessWidget {
  final List<T> options;
  final Map<T, String> labels;
  final T selected;
  final ValueChanged<T> onSelected;

  const _SortChips({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return ChoiceChip(
          label: Text(labels[opt] ?? opt.toString()),
          selected: isSelected,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundColor: AppColors.bgMint,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          onSelected: (_) => onSelected(opt),
        );
      }).toList(),
    );
  }
}
