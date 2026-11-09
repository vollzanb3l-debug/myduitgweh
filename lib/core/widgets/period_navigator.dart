import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../utils/formatters.dart';

enum HistoryFilter { daily, weekly, monthly, all }

class PeriodNavigator extends StatelessWidget {
  final HistoryFilter filter;
  final DateTime selectedDate;
  final int offset;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onResetToCurrent;
  final VoidCallback? onTapPeriod;

  const PeriodNavigator({
    super.key,
    required this.filter,
    required this.selectedDate,
    required this.offset,
    required this.onPrevious,
    this.onNext,
    this.onResetToCurrent,
    this.onTapPeriod,
  });

  String _formatPeriodText() {
    if (filter == HistoryFilter.all) {
      return 'Semua Riwayat Transaksi';
    }

    final d = selectedDate;
    if (filter == HistoryFilter.daily) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final itemDate = DateTime(d.year, d.month, d.day);
      final yesterday = today.subtract(const Duration(days: 1));

      if (itemDate == today) {
        return 'Hari Ini, ${formatTanggal(d)}';
      } else if (itemDate == yesterday) {
        return 'Kemarin, ${formatTanggal(d)}';
      } else {
        return formatTanggal(d);
      }
    } else if (filter == HistoryFilter.weekly) {
      final monday = d.subtract(Duration(days: d.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      return '${monday.day} ${_namaBulanSingkat(monday.month)} - ${sunday.day} ${_namaBulanSingkat(sunday.month)} ${sunday.year}';
    } else {
      // Monthly
      return '${_namaBulan(d.month)} ${d.year}';
    }
  }

  static String _namaBulan(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  static String _namaBulanSingkat(int month) {
    const months = [
      'Okt',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (filter == HistoryFilter.all) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : const Color(0xFFF2ECE1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.all_inclusive_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Menampilkan Seluruh Riwayat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final canGoNext = onNext != null;
    final isNotCurrent = offset < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF2ECE1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Periode Sebelumnya',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: onPrevious,
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: InkWell(
                    onTap: onTapPeriod,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _formatPeriodText(),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 20,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: canGoNext ? 'Periode Berikutnya' : 'Periode Terkini',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: onNext,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          if (isNotCurrent && onResetToCurrent != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: onResetToCurrent,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.replay_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        filter == HistoryFilter.daily
                            ? 'Kembali ke Hari Ini'
                            : (filter == HistoryFilter.weekly
                                ? 'Kembali ke Minggu Ini'
                                : 'Kembali ke Bulan Ini'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

