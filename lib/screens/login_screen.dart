import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/skillora_app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'demo@skillora.app');
  final _passwordController = TextEditingController(text: 'password');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<SkilloraAppState>();
    try {
      await appState.login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) context.go('/dashboard');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appState.error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<SkilloraAppState>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                color: colors.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.currency_exchange,
                            size: 54, color: colors.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Skillora',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Where Skills Become Currency',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: appState.loading ? null : _submit,
                          child: appState.loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Login'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Create a new account'),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                         onPressed: appState.loading
                             ? null
                             : () async {
                                 try {
                                   await appState.signInWithGoogle();
                                   if (mounted && appState.isAuthenticated) {
                                     context.go('/dashboard');
                                   }
                                 } catch (_) {
                                   if (!mounted) return;
                                   ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(
                                           content: Text(appState.error ?? 'Google sign-in failed')));
                                 }
                               },
                         icon: CircleAvatar(
                           backgroundColor: Colors.white,
                           radius: 12,
                           child: Text(
                             'G',
                             style: TextStyle(
                               fontWeight: FontWeight.bold,
                               color: Colors.redAccent,
                               fontSize: 14,
                             ),
                           ),
                         ),
                         label: const Text('Sign in with Google'),
                        ),
                        if (!appState.useFirebase) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Demo mode: Firebase is not connected yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.secondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
