import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tabungan')),
      body: const ComingSoonState(
        icon: Icons.savings_outlined,
        title: 'Belum tersedia',
        subtitle: 'Fitur ini sedang disiapkan',
      ),
    );
  }
}
