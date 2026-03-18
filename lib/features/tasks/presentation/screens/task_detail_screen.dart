import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/models/task_model.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';

final taskDetailProvider = StreamProvider.family<TaskModel?, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).watchTask(id),
);

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));
    return taskAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:   (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data:    (task) {
        if (task == null) return const Scaffold(body: Center(child: Text('Task not found')));
        final cat = AppCategories.getById(task.categoryId);
        return Scaffold(
          appBar: AppBar(title: Text(task.title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(cat?.emoji ?? '📋', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Chip(label: Text(cat?.label ?? task.categoryId), backgroundColor: (cat?.color ?? AppColors.primary).withOpacity(0.1)),
                const Spacer(),
                Text(task.urgencyDisplay),
              ]),
              const SizedBox(height: 16),
              Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(task.description, style: const TextStyle(height: 1.6)),
              const SizedBox(height: 20),
              _InfoRow(Icons.location_on_outlined, task.locationLabel),
              _InfoRow(Icons.attach_money, task.budgetDisplay),
              const SizedBox(height: 28),
              AppButton(label: 'Submit Bid', onPressed: () {}),
            ]),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String text;
  const _InfoRow(this.icon, this.text);
  @override Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [Icon(icon, size: 18, color: AppColors.textHint), const SizedBox(width: 8), Text(text)]),
  );
}
