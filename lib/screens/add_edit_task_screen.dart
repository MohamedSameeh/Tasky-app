import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_scope.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';
import '../widgets/custom_button.dart';

class AddEditTaskScreen extends StatefulWidget {
  final String userId;
  final Task? task;
  final DateTime? initialDate;

  const AddEditTaskScreen({
    super.key,
    required this.userId,
    this.task,
    this.initialDate,
  });

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDate;
  int _selectedPriority = 0;
  late String _category;
  bool _isLoading = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedDate =
        widget.task?.taskTime ??
        widget.initialDate ??
        (_isEdit ? null : dayOnly(DateTime.now()));
    _selectedPriority = widget.task?.priorityLevel.value ?? 0;
    _category = widget.task?.category ?? TaskCategories.orders;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final existing = widget.task;
    final task = Task(
      id: existing?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      taskTime: _selectedDate,
      priority: _selectedPriority,
      category: _category,
      isCompleted: existing?.isCompleted ?? false,
      completedAt: existing?.completedAt,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    try {
      await AppScope.taskRepository.setTask(widget.userId, task);
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnack(context, _isEdit ? 'Changes saved' : 'Task added');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAppSnack(context, 'Could not save the task', error: true);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Due date',
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.md),
    child: Text(text, style: context.text.titleSmall),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final today = dayOnly(DateTime.now());
    final quick = <String, DateTime>{
      'Today': today,
      'Tomorrow': today.add(const Duration(days: 1)),
      'Next week': today.add(const Duration(days: 7)),
    };
    final isQuick =
        _selectedDate != null &&
        quick.values.any((d) => d == dayOnly(_selectedDate!));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit task' : 'New task'),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl,
            AppSpace.sm,
            AppSpace.xl,
            AppSpace.xl,
          ),
          children: [
            Text('Title', style: context.text.titleSmall),
            const SizedBox(height: AppSpace.sm),
            TextFormField(
              controller: _titleController,
              autofocus: !_isEdit,
              textCapitalization: TextCapitalization.sentences,
              style: context.text.titleMedium,
              decoration: const InputDecoration(
                hintText: 'e.g. Send invoice to a customer',
              ),
              validator:
                  (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Please enter a title'
                          : null,
            ),
            const SizedBox(height: AppSpace.lg),
            Text('Notes', style: context.text.titleSmall),
            const SizedBox(height: AppSpace.sm),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Details, amounts, who to contact…',
              ),
              minLines: 3,
              maxLines: 6,
            ),
            _label('Category'),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final c in TaskCategories.all)
                  ChoiceChip(
                    avatar: Icon(
                      categoryIcon(c),
                      size: 16,
                      color: p.category(c),
                    ),
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            _label('Priority'),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final pr in TaskPriority.values)
                  ChoiceChip(
                    avatar: Icon(
                      pr == TaskPriority.none ? Icons.outlined_flag : Icons.flag,
                      size: 16,
                      color: p.priority(pr),
                    ),
                    label: Text(pr == TaskPriority.none ? 'None' : pr.label),
                    selected: _selectedPriority == pr.value,
                    onSelected:
                        (_) => setState(() => _selectedPriority = pr.value),
                  ),
              ],
            ),
            _label('Due date'),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final e in quick.entries)
                  ChoiceChip(
                    label: Text(e.key),
                    selected:
                        _selectedDate != null &&
                        dayOnly(_selectedDate!) == e.value,
                    onSelected:
                        (_) => setState(() => _selectedDate = e.value),
                  ),
                ChoiceChip(
                  avatar: const Icon(Icons.calendar_today_outlined, size: 15),
                  label: Text(
                    _selectedDate != null && !isQuick
                        ? DateFormat('EEE, MMM d').format(_selectedDate!)
                        : 'Pick a date',
                  ),
                  selected: _selectedDate != null && !isQuick,
                  onSelected: (_) => _pickDate(),
                ),
                ChoiceChip(
                  label: const Text('No date'),
                  selected: _selectedDate == null,
                  onSelected: (_) => setState(() => _selectedDate = null),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpace.xl,
            AppSpace.sm,
            AppSpace.xl,
            AppSpace.lg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CustomButton(
            text: _isEdit ? 'Save changes' : 'Add task',
            loading: _isLoading,
            onPressed: _saveTask,
          ),
        ),
      ),
    );
  }
}
