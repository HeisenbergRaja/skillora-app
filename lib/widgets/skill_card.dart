import 'package:flutter/material.dart';

import '../models/skill.dart';

class SkillCard extends StatelessWidget {
  const SkillCard({super.key, required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    skill.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(label: Text('${skill.credits} credits')),
              ],
            ),
            const SizedBox(height: 8),
            Text(skill.description),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  label: Text(skill.category),
                ),
                Chip(
                  avatar: const Icon(Icons.star_outline, size: 18),
                  label: Text(skill.rating == 0
                      ? 'New'
                      : skill.rating.toStringAsFixed(1)),
                ),
                Chip(
                  avatar: const Icon(Icons.person_outline, size: 18),
                  label: Text(skill.providerName),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Skill request flow will be added next.'),
                    ),
                  );
                },
                icon: const Icon(Icons.send_outlined),
                label: const Text('Request Skill'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
