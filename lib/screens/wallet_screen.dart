import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/skillora_app_state.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/stat_card.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SkilloraAppState>().currentUser;

    return AppScaffold(
      title: 'Wallet',
      selectedIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Credit Wallet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          StatCard(
            title: 'Current Balance',
            value: '${user?.credits ?? 0} credits',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaction History',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text(
                      'Transactions will appear here after request completion and credit transfer are added.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
