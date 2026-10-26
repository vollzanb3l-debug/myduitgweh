import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/widgets.dart';

class OnboardingGuideScreen extends StatefulWidget {
  const OnboardingGuideScreen({super.key});

  @override
  State<OnboardingGuideScreen> createState() => _OnboardingGuideScreenState();
}

class _OnboardingGuideScreenState extends State<OnboardingGuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Duit Harian',
      'desc':
          'Kelola uang masuk dan keluar sehari-hari dengan cepat tanpa ribet. Pengeluaran jajan, makan, hingga transport tercatat rapi.',
      'icon': Icons.today_rounded,
      'color': AppColors.duitHarian,
    },
    {
      'title': 'Duit Saldo',
      'desc':
          'Pantau saldo di berbagai tempat penyimpanan seperti uang tunai, rekening bank, maupun e-wallet favorit Anda.',
      'icon': Icons.account_balance_rounded,
      'color': AppColors.duitSaldo,
    },
    {
      'title': 'Duit Tabungan',
      'desc':
          'Pisahkan dana masa depan dengan duit tabungan terencana. Catat setoran dan penarikan secara transparan.',
      'icon': Icons.savings_rounded,
      'color': AppColors.duitTabungan,
    },
    {
      'title': 'Duit Pencapaian',
      'desc':
          'Wujudkan barang atau impian yang ingin dibeli! Pantau target nominal, tenggat waktu, dan progres tabungan sampai tercapai.',
      'icon': Icons.emoji_events_rounded,
      'color': AppColors.duitPencapaian,
    },
    {
      'title': 'Statistik & Analisis',
      'desc':
          'Pahami ke mana perginya uang Anda lewat grafik perbandingan dan rincian kategori mingguan, bulanan, atau tahunan.',
      'icon': Icons.bar_chart_rounded,
      'color': const Color(0xFF9B51E0),
    },
  ];

  void _onSkip() {
    context.go('/nama');
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/nama');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar: Tombol Lewati
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isLastPage)
                    TextButton(
                      onPressed: _onSkip,
                      child: Text(
                        'Lewati',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  final color = page['color'] as Color;
                  final icon = page['icon'] as IconData;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ilustrasi Ikon Besar
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(icon, size: 72, color: color),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Judul Slide
                        Text(
                          page['title'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Deskripsi
                        Text(
                          page['desc'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indikator Titik
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final isSelected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Tombol Bawah (Mulai di halaman terakhir, atau Lanjut)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: PrimaryButton(
                text: isLastPage ? 'Mulai' : 'Lanjut',
                onPressed: _onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
