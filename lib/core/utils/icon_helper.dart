import 'package:flutter/material.dart';

class IconHelper {
  IconHelper._();

  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant_rounded':
      case 'fastfood':
        return Icons.restaurant_rounded;
      case 'directions_car_rounded':
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'shopping_bag_rounded':
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'receipt_long_rounded':
      case 'receipt':
        return Icons.receipt_long_rounded;
      case 'sports_esports_rounded':
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'medical_services_rounded':
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'payments_rounded':
      case 'payments':
        return Icons.payments_rounded;
      case 'savings_rounded':
      case 'savings':
        return Icons.savings_rounded;
      case 'card_giftcard_rounded':
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'more_horiz_rounded':
      case 'more_horiz':
        return Icons.more_horiz_rounded;
      case 'wallet':
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static Color parseColor(
    String hexString, {
    Color fallback = const Color(0xFFF9A826),
  }) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}
