import 'package:flutter/material.dart';

import '../../services/identity_service.dart';
import '../home/dashboard_screen.dart';

class IdentitySetupScreen extends StatefulWidget {
  const IdentitySetupScreen({super.key});

  @override
  State<IdentitySetupScreen> createState() => _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends State<IdentitySetupScreen> {
  final _secretController = TextEditingController();
  final _identity = IdentityService.instance;

  int _selectedHours = 24;
  bool _creating = false;

  Future<void> _createIdentity() async {
    final code = _secretController.text.trim();

    if (!_identity.isValidSecretCode(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Secret code must use only 0-9 + - * / . and end with =',
          ),
        ),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      await _identity.createIdentity(hours: _selectedHours, secretCode: code);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create identity: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Widget _hourChip(int hours) {
    final selected = _selectedHours == hours;
    return ChoiceChip(
      label: Text('$hours h'),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedHours = hours);
      },
    );
  }

  @override
  void dispose() {
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.shield_moon_outlined,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Identity Setup',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your temporary identity and stealth calculator code.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Timer',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _hourChip(1),
                              _hourChip(6),
                              _hourChip(12),
                              _hourChip(24),
                              _hourChip(48),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Secret Code',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _secretController,
                            decoration: const InputDecoration(
                              hintText: 'Example: 789+=',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Rules:\n'
                            '• Use only calculator characters: 0-9 + - * / .\n'
                            '• Must end with =\n'
                            '• = cannot appear anywhere except the very end',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _creating ? null : _createIdentity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(_creating ? 'Creating...' : 'Create Identity'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}