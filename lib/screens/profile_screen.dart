import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../services/skillora_app_state.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/skill_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<SkilloraAppState>();
    final user = appState.currentUser;
    final mySkills = appState.mySkills;

    return AppScaffold(
      title: 'Profile',
      selectedIndex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    child: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : 'S',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Skillora User',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(user?.email ?? ''),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text('${user?.credits ?? 0} credits')),
                            Chip(
                                label: Text(
                                    'Rating ${(user?.rating ?? 0).toStringAsFixed(1)}')),
                            Chip(
                                label: Text(appState.useFirebase
                                    ? 'Firebase'
                                    : 'Demo')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          (user?.bio.isNotEmpty ?? false)
                              ? user!.bio
                              : 'Add an edit profile screen later to update bio, location, and profile picture.',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Sign out'),
                                    content: const Text('Are you sure you want to sign out?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Sign out'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  try {
                                    await appState.logout();
                                    if (context.mounted) {
                                      // ignore: use_build_context_synchronously
                                      context.go('/login');
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(appState.error ?? 'Sign out failed')));
                                    }
                                  }
                                }
                              },
                              child: const Text('Sign out'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {
                                // placeholder for edit profile
                              },
                              child: const Text('Edit profile'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'My Skills',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (mySkills.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('You have not added any skills yet.'),
              ),
            )
          else
            for (final skill in mySkills) ...[
              SkillCard(skill: skill),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}
