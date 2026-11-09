import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_labels.dart';
import '../constants/category_constants.dart';
import '../utils/formatters.dart';
import '../utils/icon_helper.dart';
import 'app_card.dart';
import '../../data/models/category_model.dart';
import '../../data/models/saving_goal_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/providers.dart';

/// Komponen terpadu item riwayat transaksi untuk seluruh layar:
/// Riwayat Utama, Duit Utama, Duit Saldo, Duit Tabungan, dan Duit Pencapaian.
class TransactionListItem extends ConsumerWidget {
  final TransactionItem transaction;
  final CategoryItem? category;
  final SavingGoalItem? goal;
  final VoidCallback? onTap;
  final bool showDelete;
  final bool enableSwipe;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.category,
    this.goal,
    this.onTap,
    this.showDelete = true,
    this.enableSwipe = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == 'income';

    // 1. Tentukan warna dan ikon kategori / pencapaian
    Color catColor;
    IconData catIcon;
    String titleText;

    if (transaction.ledger == 'goal' || transaction.goalId != null) {
      catColor = AppColors.duitPencapaian;
      catIcon = goal?.icon != null
          ? IconHelper.getIconData(goal!.icon)
          : Icons.emoji_events_rounded;
      titleText = goal?.name != null
          ? 'Setor: ${goal!.name}'
          : (category?.name ?? 'Setoran Pencapaian');
    } else if (category != null) {
      catIcon = IconHelper.getIconData(category!.icon);
      if (category!.colorHex.isNotEmpty &&
          category!.colorHex != '#6B7280' &&
          category!.colorHex != '#B2BEC3') {
        catColor = IconHelper.parseColor(category!.colorHex);
      } else if (category!.name.toLowerCase() == 'lainnya') {
        catColor = const Color(0xFFB2BEC3);
      } else {
        catColor = CategoryConstants.getFallbackColor(
          category!.name,
          id: category!.id,
        );
      }
      titleText = category!.name;
    } else {
      catIcon = isIncome
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded;
      catColor = CategoryConstants.getFallbackColor(
        transaction.note ?? 'Umum',
        id: transaction.categoryId,
      );
      titleText = transaction.note?.isNotEmpty == true
          ? transaction.note!
          : (isIncome ? 'Pemasukan' : 'Pengeluaran');
    }

    final cardChild = AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          // Ikon Kategori dengan Warna Bawaan Cerah
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: catColor.withOpacity(isDark ? 0.22 : 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(catIcon, color: catColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Judul Kategori & Catatan/Tanggal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (transaction.note != null &&
                    transaction.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.note!,
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
                const SizedBox(height: 2),
                Text(
                  formatTanggal(transaction.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Nominal Transaksi (+ Hijau / - Merah)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'} ${formatRupiah(transaction.amount)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isIncome ? AppColors.income : AppColors.expense,
                ),
              ),
            ],
          ),

          // Tombol Hapus Tempat Sampah
          if (showDelete) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Hapus Transaksi',
              onPressed: () => showDeleteTransactionDialog(
                context,
                ref,
                transaction,
                category: category,
                goal: goal,
              ),
            ),
          ],
        ],
      ),
    );

    if (!enableSwipe) {
      return cardChild;
    }

    return Dismissible(
      key: ValueKey('tx_item_${transaction.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => showDeleteTransactionDialog(
        context,
        ref,
        transaction,
        category: category,
        goal: goal,
      ),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
            SizedBox(width: 6),
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: cardChild,
    );
  }
}

/// Menampilkan dialog konfirmasi penghapusan transaksi dengan rincian dan penjelasan dampak saldo.
Future<bool?> showDeleteTransactionDialog(
  BuildContext context,
  WidgetRef ref,
  TransactionItem item, {
  CategoryItem? category,
  SavingGoalItem? goal,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isTransfer = item.transferPartnerId != null ||
      (item.note != null &&
          (item.note!.startsWith('Transfer ke ') ||
              item.note!.startsWith('Transfer dari ') ||
              item.note!.startsWith('Setor impian: ') ||
              item.note!.startsWith('Menabung target: ')));

  final isGoalTx = item.ledger == 'goal' || item.goalId != null;

  String impactMessage;
  if (isGoalTx) {
    final goalName = goal?.name != null ? ' "${goal!.name}"' : '';
    impactMessage =
        'Nominal terkumpul pada target$goalName akan berkurang sebesar ${formatRupiah(item.amount)}.';
    if (isTransfer) {
      impactMessage += '\nSaldo catatan sumber yang terpotong juga akan dikembalikan.';
    }
  } else if (isTransfer) {
    impactMessage =
        'Transaksi ini terhubung antar-duit. Catatan di kedua duit akan dihapus dan saldo keduanya akan dikembalikan.';
  } else {
    String duitName;
    switch (item.ledger) {
      case 'daily':
        duitName = AppLabels.duitUtama;
        break;
      case 'balance':
        duitName = AppLabels.duitSaldo;
        break;
      case 'saving':
        duitName = AppLabels.duitTabungan;
        break;
      case 'goal':
        duitName = AppLabels.duitPencapaian;
        break;
      default:
        duitName = 'Duit';
    }
    impactMessage = 'Saldo $duitName akan disesuaikan kembali.';
  }

  final categoryName = goal?.name != null
      ? 'Setor: ${goal!.name}'
      : (category?.name ?? (item.note?.isNotEmpty == true ? item.note! : 'Transaksi'));

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Hapus Transaksi?',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rincian Singkat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : const Color(0xFFF6F2EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.type == "income" ? "Masuk" : "Keluar"}: ${formatRupiah(item.amount)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: item.type == 'income'
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatTanggal(item.date),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            impactMessage,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Batal',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextSecondary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.expense,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            'Hapus',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    final repo = ref.read(transactionRepositoryProvider);
    await repo.deleteTransaction(item.id!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaksi berhasil dihapus',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.darkAccent,
        ),
      );
    }
    return true;
  }
  return false;
}

