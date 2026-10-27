import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_labels.dart';
import '../../../core/models/duit_type.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../core/widgets/atur_saldo_sheet.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/providers.dart';
import '../providers/home_overview_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(homeOverviewProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final userName = ref.watch(userNameProvider);
    final activeDuit = ref.watch(activeDuitProvider);

    // Siapkan map categoryId -> CategoryItem
    final categoryMap = <int, CategoryItem>{};
    categoriesAsync.whenData((categories) {
      for (final cat in categories) {
        if (cat.id != null) {
          categoryMap[cat.id!] = cat;
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: overviewAsync.when(
          data: (data) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(homeOverviewProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Ramah
                    _buildHeader(context, userName, activeDuit),

                    const SizedBox(height: 16),

                    // Filter Jenis Duit (Semua / Harian / Saldo / Tabungan / Pencapaian)
                    _buildLedgerFilterChips(context, ref, activeDuit),

                    const SizedBox(height: 16),

                    // 2. Kartu Besar Berwarna Aksen Duit Aktif
                    _buildTotalBalanceCard(
                      context,
                      ref,
                      data,
                      activeDuit,
                      userName,
                    ),

                    const SizedBox(height: 24),

                    // 3. Baris Tombol Aksi Cepat
                    _buildQuickActionButtons(context, ref, activeDuit),

                    const SizedBox(height: 28),

                    // 4. Konten Beranda Menyesuaikan Duit Aktif
                    ..._buildDuitSpecificContent(
                      context,
                      ref,
                      data,
                      activeDuit,
                      userName,
                      categoryMap,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ErrorState(
            title: 'Gagal Memuat Beranda',
            message:
                'Tidak dapat menampilkan ringkasan data keuangan. Silakan coba lagi.',
            onRetry: () => ref.invalidate(homeOverviewProvider),
          ),
        ),
      ),
    );
  }

  // 1. Header Ramah
  Widget _buildHeader(
    BuildContext context,
    String userName,
    DuitSelection activeDuit,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = userName.isNotEmpty ? 'Halo, $userName!' : 'Halo!';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),

            // Label kecil berbentuk chip dengan format "MyDuitGweh (NamaDuit)"
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: activeDuit.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeDuit.color.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: Row(
                  key: ValueKey<String>(activeDuit.ledgerKey ?? 'semua'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(activeDuit.icon, size: 14, color: activeDuit.color),
                    const SizedBox(width: 6),
                    Text(
                      brandLabel(activeDuit),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: activeDuit.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Ikon dompet di pojok kanan atas dibuka menjadi menu bottom sheet
        InkWell(
          onTap: () => _showHomeMenu(context),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: activeDuit.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: activeDuit.color,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  // Menu Bottom Sheet di Pojok Kanan Atas
  void _showHomeMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    'Panduan Penggunaan',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Langkah memakai aplikasi per fitur',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/panduan-penggunaan');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  title: Text(
                    'Tentang',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Informasi pembuat dan versi aplikasi',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/tentang');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  title: Text(
                    'Pengaturan',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Keamanan PIN, ubah nama, & data',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/pengaturan');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Filter Jenis Duit (Horizontal Chips)
  Widget _buildLedgerFilterChips(
    BuildContext context,
    WidgetRef ref,
    DuitSelection activeDuit,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = [
      {'choice': DuitSelection.semua, 'label': 'Semua', 'icon': Icons.all_inclusive_rounded},
      {'choice': DuitSelection.harian, 'label': 'Harian', 'icon': Icons.shopping_basket_rounded},
      {'choice': DuitSelection.saldo, 'label': 'Saldo', 'icon': Icons.account_balance_wallet_rounded},
      {'choice': DuitSelection.tabungan, 'label': 'Tabungan', 'icon': Icons.savings_rounded},
      {'choice': DuitSelection.pencapaian, 'label': 'Pencapaian', 'icon': Icons.stars_rounded},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = options[index];
          final choice = opt['choice'] as DuitSelection;
          final isSelected = activeDuit == choice;

          return FilterChip(
            selected: isSelected,
            avatar: Icon(
              opt['icon'] as IconData,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            label: Text(
              opt['label'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.darkAccent),
              ),
            ),
            selectedColor: choice.color,
            checkmarkColor: Colors.white,
            onSelected: (val) {
              if (val) {
                ref.read(activeDuitProvider.notifier).select(choice);
                ref.read(activeLedgerFilterProvider.notifier).state =
                    choice.ledgerKey ?? 'all';
              }
            },
          );
        },
      ),
    );
  }

  // 2. Kartu Besar Berwarna Aksen Duit Aktif
  Widget _buildTotalBalanceCard(
    BuildContext context,
    WidgetRef ref,
    HomeOverviewData data,
    DuitSelection activeDuit,
    String userName,
  ) {
    String balanceTitle;
    if (activeDuit.isHarian) {
      balanceTitle = 'Saldo Duit Harian';
    } else if (activeDuit.isSaldo) {
      balanceTitle = 'Total Saldo Simpanan';
    } else if (activeDuit.isTabungan) {
      balanceTitle = userName.isNotEmpty
          ? 'Total Tabungan $userName'
          : 'Total Duit Tabungan';
    } else if (activeDuit.isPencapaian) {
      balanceTitle = 'Total Terkumpul Pencapaian';
    } else {
      balanceTitle = 'Total Saldo Keseluruhan';
    }

    final accentColor = activeDuit.color;
    final darkerAccent = Color.lerp(accentColor, Colors.black, 0.18) ?? accentColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, darkerAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                balanceTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              // Tombol Atur Saldo (Disembunyikan jika "Semua")
              if (!activeDuit.isSemua)
                InkWell(
                  onTap: () {
                    if (activeDuit.isPencapaian && data.savingGoals.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Buat pencapaian dulu sebelum menyetor'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    showAturSaldoBottomSheet(
                      context: context,
                      ref: ref,
                      duit: activeDuit,
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Opacity(
                    opacity: (activeDuit.isPencapaian && data.savingGoals.isEmpty)
                        ? 0.5
                        : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            activeDuit.isPencapaian
                                ? Icons.refresh_rounded
                                : Icons.tune_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            activeDuit.isPencapaian
                                ? 'Reset Progres'
                                : 'Atur Saldo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedRupiahCounter(
                    amount: data.totalBalance,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  ref.watch(hideBalanceProvider)
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 22,
                ),
                tooltip: ref.watch(hideBalanceProvider)
                    ? 'Tampilkan Saldo'
                    : 'Sembunyikan Saldo',
                onPressed: () => ref.read(hideBalanceProvider.notifier).toggle(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Pemasukan Bulan Ini
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.income.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 16,
                          color: AppColors.income,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pemasukan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                            AnimatedRupiahCounter(
                              amount: data.monthlyIncome,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.income,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.black12,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Pengeluaran Bulan Ini
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          size: 16,
                          color: AppColors.expense,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengeluaran',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                            AnimatedRupiahCounter(
                              amount: data.monthlyExpense,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Baris Tombol Aksi Cepat
  Widget _buildQuickActionButtons(
    BuildContext context,
    WidgetRef ref,
    DuitSelection activeDuit,
  ) {
    if (activeDuit.isPencapaian) {
      final goals = ref.watch(savingGoalsStreamProvider).value ?? [];
      final hasGoals = goals.isNotEmpty;

      // Khusus Duit Pencapaian: Setor dan Tambah Target
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            context: context,
            icon: Icons.savings_rounded,
            label: 'Setor',
            iconColor: hasGoals
                ? AppColors.duitPencapaian
                : AppColors.duitPencapaian.withValues(alpha: 0.35),
            bgColor: hasGoals
                ? AppColors.duitPencapaian.withValues(alpha: 0.12)
                : AppColors.duitPencapaian.withValues(alpha: 0.04),
            onTap: () {
              if (!hasGoals) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Buat pencapaian dulu sebelum menyetor'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              context.push('/duit/pencapaian');
            },
          ),
          _buildActionButton(
            context: context,
            icon: Icons.add_circle_outline_rounded,
            label: 'Tambah Target',
            iconColor: const Color(0xFF00CEC9),
            bgColor: const Color(0xFF00CEC9).withValues(alpha: 0.12),
            onTap: () => context.push('/duit/pencapaian'),
          ),
          _buildActionButton(
            context: context,
            icon: Icons.receipt_long_rounded,
            label: 'Riwayat',
            iconColor: const Color(0xFF2F80ED),
            bgColor: const Color(0xFF2F80ED).withValues(alpha: 0.12),
            onTap: () => context.go('/riwayat'),
          ),
          _buildActionButton(
            context: context,
            icon: Icons.bar_chart_rounded,
            label: 'Statistik',
            iconColor: const Color(0xFF9B51E0),
            bgColor: const Color(0xFF9B51E0).withValues(alpha: 0.12),
            onTap: () => context.go('/statistik'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          context: context,
          icon: Icons.add_rounded,
          label: 'Pemasukan',
          iconColor: AppColors.income,
          bgColor: AppColors.income.withValues(alpha: 0.12),
          onTap: () => context.push('/tambah-transaksi', extra: 'income'),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.remove_rounded,
          label: 'Pengeluaran',
          iconColor: AppColors.expense,
          bgColor: AppColors.expense.withValues(alpha: 0.12),
          onTap: () => context.push('/tambah-transaksi', extra: 'expense'),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.receipt_long_rounded,
          label: 'Riwayat',
          iconColor: const Color(0xFF2F80ED),
          bgColor: const Color(0xFF2F80ED).withValues(alpha: 0.12),
          onTap: () => context.go('/riwayat'),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.bar_chart_rounded,
          label: 'Statistik',
          iconColor: const Color(0xFF9B51E0),
          bgColor: const Color(0xFF9B51E0).withValues(alpha: 0.12),
          onTap: () => context.go('/statistik'),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Konten Beranda Spesifik Sesuai Duit Aktif
  List<Widget> _buildDuitSpecificContent(
    BuildContext context,
    WidgetRef ref,
    HomeOverviewData data,
    DuitSelection activeDuit,
    String userName,
    Map<int, CategoryItem> categoryMap,
  ) {
    if (activeDuit.isSemua) {
      return [
        _buildWalletsSection(context, data, userName, 'Duit Saya'),
        const SizedBox(height: 28),
        _buildExpenseChartSection(context, data, activeDuit),
        const SizedBox(height: 28),
        _buildRecentTransactionsSection(context, data, categoryMap, activeDuit),
      ];
    } else if (activeDuit.isHarian) {
      return [
        _buildExpenseChartSection(context, data, activeDuit),
        const SizedBox(height: 28),
        _buildRecentTransactionsSection(context, data, categoryMap, activeDuit),
      ];
    } else if (activeDuit.isSaldo) {
      return [
        _buildWalletsSection(context, data, userName, 'Akun Duit Saldo'),
        const SizedBox(height: 28),
        _buildRecentTransactionsSection(context, data, categoryMap, activeDuit),
      ];
    } else if (activeDuit.isTabungan) {
      return [
        _buildWalletsSection(context, data, userName, 'Rekening Duit Tabungan'),
        const SizedBox(height: 28),
        _buildRecentTransactionsSection(context, data, categoryMap, activeDuit),
      ];
    } else {
      // Duit Pencapaian
      return [
        _buildGoalsSection(context, data),
        const SizedBox(height: 28),
        _buildRecentTransactionsSection(context, data, categoryMap, activeDuit),
      ];
    }
  }

  // Bagian Daftar Akun / Duit Saya
  Widget _buildWalletsSection(
    BuildContext context,
    HomeOverviewData data,
    String userName,
    String sectionTitle,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (data.walletsWithBalance.isEmpty) {
      return const EmptyState(
        title: 'Belum Ada Akun',
        message: 'Belum ada akun yang terdaftar.',
        icon: Icons.account_balance_wallet_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/dompet'),
              child: Text(
                'Lihat semua',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data.walletsWithBalance.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = data.walletsWithBalance[index];
              final w = item.wallet;
              final balance = item.balance;

              IconData walletIcon = Icons.account_balance_wallet_rounded;
              Color iconColor = AppColors.primary;
              if (w.type == 'daily') {
                walletIcon = Icons.shopping_basket_rounded;
                iconColor = AppColors.duitHarian;
              } else if (w.type == 'saving') {
                walletIcon = Icons.savings_rounded;
                iconColor = AppColors.duitTabungan;
              } else {
                walletIcon = Icons.credit_card_rounded;
                iconColor = AppColors.duitSaldo;
              }

              final displayName = (w.type == 'saving' && userName.isNotEmpty)
                  ? 'Tabungan $userName'
                  : w.name;

              return AppCard(
                width: 170,
                padding: const EdgeInsets.all(14),
                onTap: () => context.go('/dompet'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(walletIcon, size: 16, color: iconColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AnimatedRupiahCounter(
                        amount: balance,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Bagian Daftar Target Pencapaian (Untuk Duit Pencapaian di Beranda)
  Widget _buildGoalsSection(BuildContext context, HomeOverviewData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goals = data.savingGoals;

    if (goals.isEmpty) {
      return EmptyState(
        title: 'Belum Ada Pencapaian',
        message: 'Belum ada pencapaian. Tentukan apa yang ingin kamu capai!',
        icon: Icons.stars_rounded,
        action: PrimaryButton(
          text: 'Buat Pencapaian Pertama',
          width: 240,
          onPressed: () => context.push('/duit/pencapaian'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Target Pencapaian',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/duit/pencapaian'),
              child: Text(
                'Lihat semua',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.duitPencapaian,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: goals.take(3).length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final g = goals[index];
            final progress = g.targetAmount > 0
                ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0)
                : 0.0;
            final percent = (progress * 100).toInt();

            return AppCard(
              padding: const EdgeInsets.all(14),
              onTap: () => context.push('/duit/pencapaian'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.duitPencapaian.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          IconHelper.getIconData(g.icon),
                          color: AppColors.duitPencapaian,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          g.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.duitPencapaian,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.duitPencapaian,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Terkumpul: ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          MoneyText(
                            amount: g.currentAmount,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Target: ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          MoneyText(
                            amount: g.targetAmount,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 5. Mini Grafik Garis Pengeluaran 7 Hari Terakhir
  Widget _buildExpenseChartSection(
    BuildContext context,
    HomeOverviewData data,
    DuitSelection activeDuit,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = data.last7DaysExpenses;

    int maxExpense = 0;
    int totalWeekExpense = 0;
    for (final p in points) {
      totalWeekExpense += p.expenseAmount;
      if (p.expenseAmount > maxExpense) {
        maxExpense = p.expenseAmount;
      }
    }
    final double maxY = maxExpense > 0 ? (maxExpense * 1.25) : 100000;

    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].expenseAmount.toDouble()));
    }

    final lineColor = activeDuit.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pengeluaran 7 Hari Terakhir',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            MoneyText(
              amount: totalWeekExpense,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.expense,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.only(
            top: 20,
            right: 16,
            left: 16,
            bottom: 12,
          ),
          child: SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < points.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              points[idx].dayName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          lineColor.withValues(alpha: 0.25),
                          lineColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 6. Bagian Transaksi Terakhir (5 Terbaru)
  Widget _buildRecentTransactionsSection(
    BuildContext context,
    HomeOverviewData data,
    Map<int, CategoryItem> categoryMap,
    DuitSelection activeDuit,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = data.recentTransactions;

    final title = activeDuit.isSemua
        ? 'Transaksi Terakhir'
        : 'Transaksi Terakhir ${activeDuit.label}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            if (transactions.isNotEmpty)
              TextButton(
                onPressed: () => context.go('/riwayat'),
                child: Text(
                  'Lihat semua',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: activeDuit.color,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          EmptyState(
            title: 'Belum Ada Transaksi',
            message: activeDuit.isSemua
                ? 'Ayo catat pemasukan atau pengeluaran pertamamu!'
                : 'Belum ada transaksi tercatat untuk ${activeDuit.label}.',
            icon: Icons.receipt_long_outlined,
            action: PrimaryButton(
              text: 'Catat Transaksi Pertama',
              width: 240,
              onPressed: () => context.push('/tambah-transaksi'),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = transactions[index];
              final category = categoryMap[item.categoryId];
              final catName = category?.name ?? 'Umum';
              final catIcon = category != null
                  ? IconHelper.getIconData(category.icon)
                  : Icons.receipt_rounded;
              final catColor = category != null
                  ? IconHelper.parseColor(category.colorHex)
                  : AppColors.primary;
              final isIncome = item.type == 'income';

              return AnimatedListItem(
                index: index,
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  onTap: () {
                    context.push('/tambah-transaksi', extra: item);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(catIcon, color: catColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              catName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.note != null && item.note!.isNotEmpty
                                  ? '${formatTanggalSingkat(item.date)} • ${item.note}'
                                  : formatTanggalSingkat(item.date),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      MoneyText(
                        amount: item.amount,
                        prefix: isIncome ? '+ ' : '- ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isIncome ? AppColors.income : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
