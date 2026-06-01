import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/skillora_app_state.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/skill_card.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<SkilloraAppState>();
    final categories = [
      'All',
      'Design',
      'Development',
      'Marketing',
      'Languages',
      'Academics',
      'Business',
      'Music',
      'Content Creation'
    ];
    final skills = appState.skills.where((skill) {
      return _selectedCategory == 'All' || skill.category == _selectedCategory;
    }).toList();

    return AppScaffold(
      title: 'Marketplace',
      selectedIndex: 1,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add-skill'),
        icon: const Icon(Icons.add),
        label: const Text('Add Skill'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse Skills',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in categories) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (skills.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No skills found in this category yet.'),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: skills.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: isWide ? 1.45 : 1.25,
                  ),
                  itemBuilder: (context, index) =>
                      SkillCard(skill: skills[index]),
                );
              },
            ),
        ],
      ),
    );
  }
}
