import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/riwayat')) return 1;
    if (location.startsWith('/statistik')) return 2;
    if (location.startsWith('/dompet')) return 3;
    return 0; // Beranda
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/beranda');
        break;
      case 1:
        context.go('/riwayat');
        break;
      case 2:
        context.go('/statistik');
        break;
      case 3:
        context.go('/dompet');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _calculateSelectedIndex(context);
    final navBgColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tambah-transaksi'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.darkAccent,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: navBgColor,
        elevation: 10,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              index: 0,
              selectedIndex: selectedIndex,
              icon: Icons.home_rounded,
              label: 'Beranda',
            ),
            _buildNavItem(
              context: context,
              index: 1,
              selectedIndex: selectedIndex,
              icon: Icons.receipt_long_rounded,
              label: 'Riwayat',
            ),
            const SizedBox(width: 48), // Spasi untuk tombol '+' di tengah
            _buildNavItem(
              context: context,
              index: 2,
              selectedIndex: selectedIndex,
              icon: Icons.bar_chart_rounded,
              label: 'Statistik',
            ),
            _buildNavItem(
              context: context,
              index: 3,
              selectedIndex: selectedIndex,
              icon: Icons.account_balance_wallet_rounded,
              label: 'Dompet',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required int selectedIndex,
    required IconData icon,
    required String label,
  }) {
    final isSelected = index == selectedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedColor = isDark ? AppColors.primary : AppColors.darkAccent;
    final unselectedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final color = isSelected ? selectedColor : unselectedColor;

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
