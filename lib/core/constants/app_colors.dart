import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Warna Utama (Brand Identity)
  static const Color primary = Color(0xFFF9A826); // Kuning-oranye hangat
  static const Color primaryLight = Color(0xFFFDCB6E);
  static const Color primaryDark = Color(0xFFE59410);

  // Aksen Gelap
  static const Color darkAccent = Color(0xFF2B2B2B);

  // Tema Terang
  static const Color lightBackground = Color(0xFFFFF8EC); // Krem terang
  static const Color lightCard = Color(0xFFFFFFFF); // Kartu putih bersih
  static const Color lightTextPrimary = Color(0xFF2B2B2B);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightBorder = Color(0xFFEFE6D8);

  // Tema Gelap
  static const Color darkBackground = Color(0xFF191816);
  static const Color darkCard = Color(0xFF252422);
  static const Color darkTextPrimary = Color(0xFFF7F5F0);
  static const Color darkTextSecondary = Color(0xFFA09C96);
  static const Color darkBorder = Color(0xFF383530);

  // Status Keuangan
  static const Color income = Color(0xFF27AE60); // Pemasukan hijau
  static const Color incomeLight = Color(0xFFE8F8F0);
  static const Color expense = Color(0xFFEB5757); // Pengeluaran merah lembut
  static const Color expenseLight = Color(0xFFFEEFEF);

  // Status Dompet & Netral
  static const Color info = Color(0xFF2F80ED);
  static const Color warning = Color(0xFFF2994A);
}
