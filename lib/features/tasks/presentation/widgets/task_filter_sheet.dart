import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/task_list_provider.dart';

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

void showTaskFilterSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(taskFilterProvider);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _TaskFilterSheet(initial: current, ref: ref),
  );
}

class _TaskFilterSheet extends StatefulWidget {
  final TaskFilterState initial;
  final WidgetRef ref;

  const _TaskFilterSheet({required this.initial, required this.ref});

  @override
  State<_TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<_TaskFilterSheet> {
  late RangeValues _budgetRange;
  String? _neighbourhood;
  late TaskSortOption _sort;

  static const _minBudget = 0.0;
  static const _maxBudget = 500.0;

  @override
  void initState() {
    super.initState();
    _budgetRange = RangeValues(
      widget.initial.budgetMin ?? _minBudget,
      widget.initial.budgetMax ?? _maxBudget,
    );
    _neighbourhood = widget.initial.neighbourhood;
    _sort = widget.initial.sort;
  }

  bool get _hasFilters =>
      _budgetRange.start > _minBudget ||
      _budgetRange.end < _maxBudget ||
      _neighbourhood != null ||
      _sort != TaskSortOption.newest;

  void _clearAll() {
    setState(() {
      _budgetRange = const RangeValues(_minBudget, _maxBudget);
      _neighbourhood = null;
      _sort = TaskSortOption.newest;
    });
  }

  void _apply() {
    widget.ref.read(taskFilterProvider.notifier).state = TaskFilterState(
      budgetMin:
          _budgetRange.start > _minBudget ? _budgetRange.start : null,
      budgetMax:
          _budgetRange.end < _maxBudget ? _budgetRange.end : null,
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

              // Budget range
              Text(
                'Budget Range',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    'S\$${_budgetRange.start.round()}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    _budgetRange.end >= _maxBudget
                        ? 'S\$${_maxBudget.round()}+'
                        : 'S\$${_budgetRange.end.round()}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              RangeSlider(
                values: _budgetRange,
                min: _minBudget,
                max: _maxBudget,
                divisions: 50,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.divider,
                labels: RangeLabels(
                  'S\$${_budgetRange.start.round()}',
                  'S\$${_budgetRange.end.round()}',
                ),
                onChanged: (v) => setState(() => _budgetRange = v),
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
              _SortChips<TaskSortOption>(
                options: TaskSortOption.values,
                labels: const {
                  TaskSortOption.newest: 'Newest',
                  TaskSortOption.priceLowHigh: 'Price: Low-High',
                  TaskSortOption.priceHighLow: 'Price: High-Low',
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
