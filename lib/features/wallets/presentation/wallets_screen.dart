import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_labels.dart';
import '../../../core/models/duit_type.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/providers.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeDuit = ref.watch(activeDuitProvider);

    final dailyBalAsync = ref.watch(ledgerBalanceStreamProvider('daily'));
    final balanceBalAsync = ref.watch(ledgerBalanceStreamProvider('balance'));
    final savingBalAsync = ref.watch(ledgerBalanceStreamProvider('saving'));
    final goalsAsync = ref.watch(savingGoalsStreamProvider);

    final dailyTxAsync = ref.watch(transactionsByLedgerStreamProvider('daily'));
    final balanceTxAsync = ref.watch(transactionsByLedgerStreamProvider('balance'));
    final savingTxAsync = ref.watch(transactionsByLedgerStreamProvider('saving'));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLabels.tabDuit,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ledgerBalanceStreamProvider('daily'));
          ref.invalidate(ledgerBalanceStreamProvider('balance'));
          ref.invalidate(ledgerBalanceStreamProvider('saving'));
          ref.invalidate(savingGoalsStreamProvider);
          ref.invalidate(transactionsByLedgerStreamProvider('daily'));
          ref.invalidate(transactionsByLedgerStreamProvider('balance'));
          ref.invalidate(transactionsByLedgerStreamProvider('saving'));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            Text(
              'Pilih jenis duit untuk melihat rincian transaksi dan mengatur saldo.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // 1. Kartu Duit Utama
            _buildLedgerCard(
              context: context,
              ref: ref,
              thisDuit: DuitSelection.harian,
              isActive: activeDuit.isHarian,
              title: AppLabels.duitHarian,
              subtitle: AppLabels.descDuitHarian,
              icon: Icons.shopping_basket_rounded,
              accentColor: AppColors.duitHarian,
              onTap: () {
                ref.read(activeDuitProvider.notifier).select(DuitType.harian);
                context.push('/duit/harian');
              },
              summaryContent: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saldo Duit Utama',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      dailyBalAsync.when(
                        data: (bal) => MoneyText(
                          amount: bal,
                          duit: 'utama',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.darkAccent,
                          ),
                        ),
                        loading: () => const Text('Memuat saldo...'),
                        error: (e, _) => const Text('Rp 0'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  dailyTxAsync.when(
                    data: (txs) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${txs.length} transaksi tercatat',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Kartu Duit Saldo
            _buildLedgerCard(
              context: context,
              ref: ref,
              thisDuit: DuitSelection.saldo,
              isActive: activeDuit.isSaldo,
              title: AppLabels.duitSaldo,
              subtitle: AppLabels.descDuitSaldo,
              icon: Icons.account_balance_wallet_rounded,
              accentColor: AppColors.duitSaldo,
              onTap: () {
                ref.read(activeDuitProvider.notifier).select(DuitType.saldo);
                context.push('/duit/saldo');
              },
              summaryContent: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Duit Saldo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      balanceBalAsync.when(
                        data: (bal) => MoneyText(
                          amount: bal,
                          duit: 'saldo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.darkAccent,
                          ),
                        ),
                        loading: () => const Text('Memuat...'),
                        error: (e, _) => const Text('Rp 0'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  balanceTxAsync.when(
                    data: (txs) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${txs.length} transaksi tercatat',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Kartu Duit Tabungan
            _buildLedgerCard(
              context: context,
              ref: ref,
              thisDuit: DuitSelection.tabungan,
              isActive: activeDuit.isTabungan,
              title: AppLabels.duitTabungan,
              subtitle: AppLabels.descDuitTabungan,
              icon: Icons.savings_rounded,
              accentColor: AppColors.duitTabungan,
              onTap: () {
                ref.read(activeDuitProvider.notifier).select(DuitType.tabungan);
                context.push('/duit/tabungan');
              },
              summaryContent: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Tabungan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      savingBalAsync.when(
                        data: (bal) => MoneyText(
                          amount: bal,
                          duit: 'tabungan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.duitTabungan,
                          ),
                        ),
                        loading: () => const Text('Memuat saldo...'),
                        error: (e, _) => const Text('Rp 0'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  savingTxAsync.when(
                    data: (txs) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${txs.length} transaksi tercatat',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Kartu Duit Pencapaian
            _buildLedgerCard(
              context: context,
              ref: ref,
              thisDuit: DuitSelection.pencapaian,
              isActive: activeDuit.isPencapaian,
              title: AppLabels.duitPencapaian,
              subtitle: AppLabels.descDuitPencapaian,
              icon: Icons.stars_rounded,
              accentColor: AppColors.duitPencapaian,
              onTap: () {
                ref.read(activeDuitProvider.notifier).select(DuitType.pencapaian);
                context.push('/duit/pencapaian');
              },
              summaryContent: goalsAsync.when(
                data: (goals) {
                  final totalCurrent =
                      goals.fold<int>(0, (sum, g) => sum + g.currentAmount);
                  final totalTarget =
                      goals.fold<int>(0, (sum, g) => sum + g.targetAmount);
                  final progress = totalTarget > 0
                      ? (totalCurrent / totalTarget).clamp(0.0, 1.0)
                      : 0.0;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${goals.length} Target Impian',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MoneyText(
                                amount: totalCurrent,
                                duit: 'pencapaian',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.duitPencapaian,
                                ),
                              ),
                              Text(
                                ' (${(progress * 100).toInt()}%)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.duitPencapaian,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                    ],
                  );
                },
                loading: () => const Text('Memuat target...'),
                error: (e, _) => const Text('Belum ada target'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerCard({
    required BuildContext context,
    required WidgetRef ref,
    required DuitSelection thisDuit,
    required bool isActive,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    required Widget summaryContent,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: isActive
            ? Border.all(color: accentColor, width: 2.2)
            : Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accentColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 13,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Aktif',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          IconButton(
                            icon: Icon(
                              ref.watch(isDuitHiddenProvider(normalizeDuitKey(thisDuit)))
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 19,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            tooltip: ref.watch(isDuitHiddenProvider(normalizeDuitKey(thisDuit)))
                                ? 'Tampilkan Saldo'
                                : 'Sembunyikan Saldo',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              ref
                                  .read(duitHideBalanceProvider.notifier)
                                  .toggle(normalizeDuitKey(thisDuit));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.lightTextSecondary,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: summaryContent,
            ),
          ],
        ),
      ),
    );
  }
}
