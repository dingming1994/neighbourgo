import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/image_validator.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';

class PostTaskScreen extends ConsumerStatefulWidget {
  final String? directHireProviderId;
  final String? directHireProviderName;
  final String? preSelectedCategory;

  const PostTaskScreen({
    super.key,
    this.directHireProviderId,
    this.directHireProviderName,
    this.preSelectedCategory,
  });

  @override
  ConsumerState<PostTaskScreen> createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends ConsumerState<PostTaskScreen> {
  int _step = 0;
  static const _totalSteps = 5;

  // Form data
  String?       _categoryId;
  String        _title          = '';
  String        _description    = '';
  List<File>    _photos         = [];
  String        _locationLabel  = '';
  String?       _neighbourhood;
  double        _budgetMin      = 20;
  double?       _budgetMax;
  TaskUrgency   _urgency        = TaskUrgency.flexible;
  DateTime?     _scheduledDate;
  bool          _loading        = false;

  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());

  bool get _isDirectHire => widget.directHireProviderId != null;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedCategory != null) {
      _categoryId = widget.preSelectedCategory;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Submit
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final user  = ref.read(currentUserProvider).valueOrNull;
      final repo  = ref.read(taskRepositoryProvider);

      final task = TaskModel(
        id:             '',
        posterId:       user!.uid,
        posterName:     user.displayName,
        posterAvatarUrl: user.avatarUrl,
        title:          _title,
        description:    _description,
        categoryId:     _categoryId!,
        locationLabel:  _locationLabel,
        neighbourhood:  _neighbourhood,
        budgetMin:      _budgetMin,
        budgetMax:      _budgetMax,
        urgency:        _urgency,
        scheduledDate:  _scheduledDate,
        status:         _isDirectHire ? TaskStatus.assigned : TaskStatus.open,
        assignedProviderId:   _isDirectHire ? widget.directHireProviderId : null,
        assignedProviderName: _isDirectHire ? widget.directHireProviderName : null,
        isDirectHire:         _isDirectHire,
      );

      final id = await repo.createTask(task, photos: _photos);

      // Send notification to provider about direct hire offer
      if (_isDirectHire) {
        await _sendDirectHireNotification(
          providerId: widget.directHireProviderId!,
          taskId: id,
          taskTitle: _title,
          posterName: user.displayName ?? 'Someone',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isDirectHire
                ? 'Hire request sent to ${widget.directHireProviderName}!'
                : 'Task posted! Providers will bid shortly.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/tasks/$id');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendDirectHireNotification({
    required String providerId,
    required String taskId,
    required String taskTitle,
    required String posterName,
  }) async {
    final db = FirebaseFirestore.instance;
    await db
        .collection(AppConstants.notificationsCol)
        .doc(providerId)
        .collection('items')
        .add({
      'type': 'direct_hire',
      'title': 'New Job Offer',
      'body': '$posterName wants to hire you for "$taskTitle"',
      'isRead': false,
      'createdAt': Timestamp.now(),
      'data': {'taskId': taskId},
    });
  }

  void _next() {
    // Last step is the review screen — no form fields, go straight to submit
    if (_step == _totalSteps - 1) {
      _submit();
      return;
    }
    if (_formKeys[_step].currentState?.validate() ?? false) {
      setState(() => _step++);
    }
  }

  void _back() { if (_step > 0) setState(() => _step--); }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isDirectHire ? 'Hire Provider  (${_step + 1}/$_totalSteps)' : 'Post a Task  (${_step + 1}/$_totalSteps)'),
        leading: _step == 0
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop())
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / _totalSteps,
            backgroundColor: AppColors.divider, color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isDirectHire)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.primary.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Hiring: ${widget.directHireProviderName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: [
                  _StepCategory(formKey: _formKeys[0], selected: _categoryId, onSelect: (id) => setState(() => _categoryId = id)),
                  _StepDescription(formKey: _formKeys[1], onTitleChanged: (v) => _title = v, onDescChanged: (v) => _description = v, onPhotosChanged: (p) => setState(() => _photos = p), photos: _photos),
                  _StepLocation(formKey: _formKeys[2], onLocationChanged: (l) => _locationLabel = l, onHoodChanged: (h) => _neighbourhood = h),
                  _StepBudget(formKey: _formKeys[3], budgetMin: _budgetMin, onBudgetChanged: (min, max) { _budgetMin = min; _budgetMax = max; }),
                  _StepReview(
                    categoryId: _categoryId, title: _title, description: _description,
                    location: _locationLabel, budgetMin: _budgetMin, budgetMax: _budgetMax,
                    urgency: _urgency, photos: _photos,
                    onUrgencyChanged: (u) => setState(() => _urgency = u),
                    onDateChanged:    (d) => setState(() => _scheduledDate = d),
                  ),
                ][_step],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: AppButton(
                label: _step < _totalSteps - 1 ? 'Next' : (_isDirectHire ? 'Send Hire Request' : 'Post Task'),
                isLoading: _loading,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Category
// ─────────────────────────────────────────────────────────────────────────────
class _StepCategory extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final String? selected;
  final void Function(String) onSelect;
  const _StepCategory({required this.formKey, required this.selected, required this.onSelect});

  @override
  State<_StepCategory> createState() => _StepCategoryState();
}
class _StepCategoryState extends State<_StepCategory> {
  String? _selected;
  @override
  void initState() { super.initState(); _selected = widget.selected; }

  @override
  Widget build(BuildContext context) => Form(
    key: widget.formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What do you need help with?', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.2,
          children: AppCategories.all.map((cat) {
            final selected = _selected == cat.id;
            return GestureDetector(
              onTap: () { setState(() => _selected = cat.id); widget.onSelect(cat.id); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? cat.color.withOpacity(0.12) : AppColors.bgCard,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: selected ? cat.color : AppColors.border, width: selected ? 2 : 1),
                ),
                child: Row(children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(cat.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: selected ? cat.color : AppColors.textPrimary))),
                ]),
              ),
            );
          }).toList(),
        ),
        // Hidden validator
        FormField<String>(
          initialValue: _selected,
          validator: (_) => _selected == null ? 'Please select a category' : null,
          builder: (state) => state.hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(state.errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Description & Photos
// ─────────────────────────────────────────────────────────────────────────────
class _StepDescription extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final void Function(String) onTitleChanged, onDescChanged;
  final void Function(List<File>) onPhotosChanged;
  final List<File> photos;
  const _StepDescription({required this.formKey, required this.onTitleChanged, required this.onDescChanged, required this.onPhotosChanged, required this.photos});

  @override
  State<_StepDescription> createState() => _StepDescriptionState();
}
class _StepDescriptionState extends State<_StepDescription> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  late List<File> _photos;
  @override void initState() { super.initState(); _photos = List.from(widget.photos); }

  Future<void> _pick() async {
    final imgs = await ImagePicker().pickMultiImage(maxWidth: 1024, imageQuality: 80, limit: AppConstants.maxTaskPhotos);
    if (imgs.isEmpty) return;

    final files = imgs.map((x) => File(x.path)).take(AppConstants.maxTaskPhotos).toList();
    final errors = ImageValidator.validateAll(files);
    if (errors.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errors.first), backgroundColor: Colors.red),
        );
      }
      // Keep only valid files
      files.removeWhere((f) => ImageValidator.validate(f) != null);
    }

    setState(() => _photos = files);
    widget.onPhotosChanged(_photos);
  }

  @override
  Widget build(BuildContext context) => Form(
    key: widget.formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Describe your task', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      const Text('Task Title', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _titleCtrl, maxLength: 100,
        decoration: const InputDecoration(hintText: 'e.g. Clean my 3-room HDB flat'),
        onChanged: widget.onTitleChanged,
        validator: (v) => (v == null || v.trim().length < 5) ? 'Title must be at least 5 characters' : null,
      ),
      const SizedBox(height: 20),
      const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _descCtrl, maxLines: 5, maxLength: 1000,
        decoration: const InputDecoration(hintText: 'Describe the task in detail — size of flat, special requirements, pets, etc.'),
        onChanged: widget.onDescChanged,
        validator: (v) => (v == null || v.trim().length < 20) ? 'Description must be at least 20 characters' : null,
      ),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Photos (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
        TextButton.icon(onPressed: _pick, icon: const Icon(Icons.add_a_photo_outlined, size: 18), label: const Text('Add')),
      ]),
      if (_photos.isNotEmpty) ...[
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_photos[i], width: 80, height: 80, fit: BoxFit.cover)),
              Positioned(top: 2, right: 2, child: GestureDetector(
                onTap: () { setState(() { _photos.removeAt(i); }); widget.onPhotosChanged(_photos); },
                child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 12)),
              )),
            ]),
          ),
        ),
      ],
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Location
// ─────────────────────────────────────────────────────────────────────────────
class _StepLocation extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final void Function(String) onLocationChanged;
  final void Function(String?) onHoodChanged;
  const _StepLocation({required this.formKey, required this.onLocationChanged, required this.onHoodChanged});

  @override
  State<_StepLocation> createState() => _StepLocationState();
}
class _StepLocationState extends State<_StepLocation> {
  final _locCtrl = TextEditingController();
  String? _hood;
  static const _hoods = ['Ang Mo Kio', 'Bedok', 'Bishan', 'Bukit Merah', 'Bukit Timah', 'Clementi', 'Geylang', 'Jurong East', 'Jurong West', 'Kallang', 'Marine Parade', 'Pasir Ris', 'Punggol', 'Queenstown', 'Sembawang', 'Sengkang', 'Serangoon', 'Tampines', 'Toa Payoh', 'Woodlands', 'Yishun'];

  @override
  Widget build(BuildContext context) => Form(
    key: widget.formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Where is the task?', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      const Text('Address / Location', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _locCtrl,
        decoration: const InputDecoration(hintText: 'Blk 123 Ang Mo Kio Ave 6 #05-45', prefixIcon: Icon(Icons.location_on_outlined)),
        onChanged: widget.onLocationChanged,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the task location' : null,
      ),
      const SizedBox(height: 20),
      const Text('Neighbourhood', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _hood,
        decoration: const InputDecoration(hintText: 'Select neighbourhood'),
        items: _hoods.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
        onChanged: (v) { setState(() => _hood = v); widget.onHoodChanged(v); },
        validator: (v) => v == null ? 'Select your neighbourhood' : null,
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Budget
// ─────────────────────────────────────────────────────────────────────────────
class _StepBudget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final double budgetMin;
  final void Function(double, double?) onBudgetChanged;
  const _StepBudget({required this.formKey, required this.budgetMin, required this.onBudgetChanged});

  @override
  State<_StepBudget> createState() => _StepBudgetState();
}
class _StepBudgetState extends State<_StepBudget> {
  late double _min;
  double? _max;
  bool    _range = false;
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _min = widget.budgetMin;
    _minCtrl.text = _min.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) => Form(
    key: widget.formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('What\'s your budget?', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text('Set a fair budget. Providers will see this and submit their quotes.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 32),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Minimum (S\$)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _minCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            decoration: const InputDecoration(prefixText: 'S\$ '),
            onChanged: (v) { _min = double.tryParse(v) ?? 0; widget.onBudgetChanged(_min, _max); },
            validator: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null || n < 5) return 'Minimum budget is S\$5';
              if (n > 10000) return 'Maximum budget is S\$10,000';
              return null;
            },
          ),
        ])),
        const SizedBox(width: 12),
        if (_range)
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Maximum (S\$)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _maxCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              decoration: const InputDecoration(prefixText: 'S\$ '),
              onChanged: (v) { _max = double.tryParse(v); widget.onBudgetChanged(_min, _max); },
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final n = double.tryParse(v);
                if (n == null || n < 5) return 'Minimum budget is S\$5';
                if (n > 10000) return 'Maximum budget is S\$10,000';
                if (n < _min) return 'Max must be ≥ min';
                return null;
              },
            ),
          ])),
      ]),
      const SizedBox(height: 12),
      CheckboxListTile(
        value: _range, contentPadding: EdgeInsets.zero,
        title: const Text('Set a budget range', style: TextStyle(fontSize: 14)),
        onChanged: (v) => setState(() { _range = v!; if (!_range) { _max = null; widget.onBudgetChanged(_min, null); } }),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 — Review & confirm
// ─────────────────────────────────────────────────────────────────────────────
class _StepReview extends StatelessWidget {
  final String? categoryId, title, description, location;
  final double budgetMin;
  final double? budgetMax;
  final TaskUrgency urgency;
  final List<File> photos;
  final void Function(TaskUrgency) onUrgencyChanged;
  final void Function(DateTime?) onDateChanged;

  const _StepReview({
    required this.categoryId, required this.title, required this.description,
    required this.location, required this.budgetMin, required this.budgetMax,
    required this.urgency, required this.photos,
    required this.onUrgencyChanged, required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cat = AppCategories.getById(categoryId ?? '');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Review & Post', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      _ReviewRow('Category',    '${cat?.emoji ?? ''} ${cat?.label ?? "Unknown"}'),
      _ReviewRow('Title',       title ?? ''),
      _ReviewRow('Location',    location ?? ''),
      _ReviewRow('Budget',      budgetMax != null ? 'S\$$budgetMin–S\$$budgetMax' : 'S\$$budgetMin'),
      _ReviewRow('Photos',      '${photos.length} attached'),
      const SizedBox(height: 20),
      const Text('Urgency', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Row(children: TaskUrgency.values.map((u) {
        final labels = {TaskUrgency.flexible: '🟢 Flexible', TaskUrgency.today: '🟡 Today', TaskUrgency.asap: '🔴 ASAP'};
        final selected = urgency == u;
        return Expanded(
          child: GestureDetector(
            onTap: () => onUrgencyChanged(u),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? AppColors.bgMint : AppColors.bgCard,
                border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
                borderRadius: AppRadius.button,
              ),
              child: Text(labels[u]!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
            ),
          ),
        );
      }).toList()),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.bgMint, borderRadius: AppRadius.card),
        child: Row(children: [
          const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          const Expanded(child: Text('Payment is held in escrow and released only after you confirm the task is complete.', style: TextStyle(fontSize: 13, height: 1.5))),
        ]),
      ),
    ]);
  }
}

class _ReviewRow extends StatelessWidget {
  final String label, value;
  const _ReviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
    ]),
  );
}
