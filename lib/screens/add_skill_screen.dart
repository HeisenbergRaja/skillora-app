import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/skillora_app_state.dart';
import '../widgets/app_scaffold.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _creditsController = TextEditingController(text: '20');
  String _category = 'Design';

  static const _categories = [
    'Design',
    'Development',
    'Marketing',
    'Languages',
    'Academics',
    'Business',
    'Music',
    'Content Creation',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<SkilloraAppState>();
    try {
      await appState.addSkill(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        credits: int.parse(_creditsController.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skill added successfully')),
      );
      context.go('/marketplace');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appState.error ?? 'Could not add skill')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<SkilloraAppState>();

    return AppScaffold(
      title: 'Add Skill',
      selectedIndex: 2,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Offer a Skill',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                  'Create a listing that other users can request using credits.'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Skill Title',
                  hintText: 'Graphic Design, Flutter Tutoring, Math Help...',
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'Enter a clear skill title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Explain what you can teach or provide.',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Add a short description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Credits Required',
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
                validator: (value) {
                  final credits = int.tryParse(value ?? '');
                  if (credits == null || credits <= 0) {
                    return 'Enter credits greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: appState.loading ? null : _submit,
                icon: const Icon(Icons.add),
                label: const Text('Publish Skill'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
