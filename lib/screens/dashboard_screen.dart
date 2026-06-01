import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/skillora_app_state.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/skill_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<SkilloraAppState>();
    final user = appState.currentUser;
    final featuredSkills = appState.skills.take(2).toList();

    return AppScaffold(
      title: 'Dashboard',
      selectedIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${user?.name ?? 'Skillora User'} 👋',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            appState.useFirebase
                ? 'Firebase connected. Your data syncs across web and Android.'
                : 'Demo mode is active. Connect Firebase to sync real users and skills.',
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final cards = [
                StatCard(
                  title: 'Current Balance',
                  value: '${user?.credits ?? 0} credits',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                StatCard(
                  title: 'Marketplace Skills',
                  value: '${appState.skills.length}',
                  icon: Icons.storefront_outlined,
                ),
                StatCard(
                  title: 'My Skills',
                  value: '${appState.mySkills.length}',
                  icon: Icons.workspace_premium_outlined,
                ),
              ];

              return GridView.count(
                crossAxisCount: isWide ? 3 : 1,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isWide ? 2.4 : 3.3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: cards,
              );
            },
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/marketplace'),
                icon: const Icon(Icons.search),
                label: const Text('Find Skills'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/add-skill'),
                icon: const Icon(Icons.add),
                label: const Text('Add Skill'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/wallet'),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Wallet'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Featured Skills',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          for (final skill in featuredSkills) ...[
            SkillCard(skill: skill),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
