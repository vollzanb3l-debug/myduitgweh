import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_labels.dart';
import '../../../core/widgets/app_card.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const guides = [
      _GuideSection(
        title: AppLabels.duitHarian,
        icon: Icons.shopping_basket_rounded,
        color: AppColors.duitHarian,
        summary: 'Uang makan, jajan, transportasi, dan kebutuhan rutin sehari-hari.',
        steps: [
          'Catat setiap pengeluaran dan pemasukan harian lewat tombol "+" atau tombol Aksi Cepat.',
          'Pilih kategori yang sesuai agar pengeluaran terpetakan rapi.',
          'Gunakan menu "Atur Saldo" jika ingin menambah atau mengoreksi saldo kas harian Anda.',
        ],
      ),
      _GuideSection(
        title: AppLabels.duitSaldo,
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.duitSaldo,
        summary: 'Penyimpanan uang di Kas Tunai, Rekening Bank, dan E-Wallet.',
        steps: [
          'Tambah rekening bank atau akun e-wallet baru sesuai rekening yang Anda miliki.',
          'Gunakan fitur transfer antar saldo jika memindahkan dana (misal: tarik tunai dari ATM).',
          'Atur atau sesuaikan saldo akun kapan saja lewat tombol "Atur Saldo".',
        ],
      ),
      _GuideSection(
        title: AppLabels.duitTabungan,
        icon: Icons.savings_rounded,
        color: AppColors.duitTabungan,
        summary: 'Tabungan masa depan, cadangan dana darurat, dan simpanan.',
        steps: [
          'Catat setoran tabungan secara berkala saat menyisihkan penghasilan.',
          'Catat penarikan tabungan saat dana dibutuhkan untuk keperluan penting.',
          'Pantau akumulasi total tabungan Anda di kartu ringkasan Duit Tabungan.',
        ],
      ),
      _GuideSection(
        title: AppLabels.duitPencapaian,
        icon: Icons.stars_rounded,
        color: AppColors.duitPencapaian,
        summary: 'Target barang atau impian yang ingin dibeli/diwujudkan.',
        steps: [
          'Buat target baru dengan nominal impian, tenggat waktu (opsional), dan ikon pilihan.',
          'Setor dana ke target: bisa setor mandiri atau memotong langsung dari Duit Saldo/Tabungan.',
          'Progress bar akan otomatis terisi menuju 100% saat target tercapai.',
          'Gunakan tombol "Reset Progres" jika ingin memulai kembali akumulasi target.',
        ],
      ),
      _GuideSection(
        title: AppLabels.tabStatistik,
        icon: Icons.bar_chart_rounded,
        color: Color(0xFF6C5CE7),
        summary: 'Analisis visual perputaran uang dan diagram kategori.',
        steps: [
          'Lihat perbandingan total pemasukan, pengeluaran, dan selisih bersih.',
          'Gunakan filter periode: Mingguan, Bulanan, atau Tahunan.',
          'Periksa diagram lingkaran kategori untuk mengetahui pos pengeluaran terbesar Anda.',
        ],
      ),
      _GuideSection(
        title: 'Cadangkan Data (Backup)',
        icon: Icons.cloud_sync_rounded,
        color: Color(0xFF00CEC9),
        summary: 'Keamanan dan keutuhan data keuangan Anda secara offline.',
        steps: [
          'Semua data Anda tersimpan aman secara lokal di memori ponsel tanpa memerlukan internet.',
          'Fitur ekspor dan cadangkan data secara berkala dapat diakses melalui menu Pengaturan.',
          'Data Anda sepenuhnya privat dan tidak pernah dikirim ke server luar mana pun.',
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Panduan Penggunaan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: guides.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final g = guides[index];

          return AppCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: g.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(g.icon, color: g.color, size: 24),
                ),
                title: Text(
                  g.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    g.summary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...g.steps.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final step = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: g.color.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$idx',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: g.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              step,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                height: 1.45,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GuideSection {
  final String title;
  final IconData icon;
  final Color color;
  final String summary;
  final List<String> steps;

  const _GuideSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.summary,
    required this.steps,
  });
}
