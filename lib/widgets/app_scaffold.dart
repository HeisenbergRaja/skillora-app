import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/skillora_app_state.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.child,
    this.floatingActionButton,
  });

  final String title;
  final int selectedIndex;
  final Widget child;
  final Widget? floatingActionButton;

  static const _destinations = [
    _Destination('Dashboard', Icons.dashboard_outlined, '/dashboard'),
    _Destination('Marketplace', Icons.storefront_outlined, '/marketplace'),
    _Destination('Add Skill', Icons.add_circle_outline, '/add-skill'),
    _Destination('Wallet', Icons.account_balance_wallet_outlined, '/wallet'),
    _Destination('Profile', Icons.person_outline, '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Consumer<SkilloraAppState>(
            builder: (context, appState, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: appState.loading ? null : appState.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: selectedIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (index) {
                context.go(_destinations[index].path);
              },
              destinations: [
                for (final item in _destinations)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
            ),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                context.go(_destinations[index].path);
              },
              destinations: [
                for (final item in _destinations)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
              ],
            ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}
