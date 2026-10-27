import 'package:flutter/material.dart';

class IconHelper {
  IconHelper._();

  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant_rounded':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'fastfood_rounded':
      case 'fastfood':
        return Icons.fastfood_rounded;
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
      case 'school_rounded':
      case 'school':
        return Icons.school_rounded;
      case 'phone_android_rounded':
      case 'phone':
        return Icons.phone_android_rounded;
      case 'payments_rounded':
      case 'payments':
        return Icons.payments_rounded;
      case 'savings_rounded':
      case 'savings':
        return Icons.savings_rounded;
      case 'card_giftcard_rounded':
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'redeem_rounded':
      case 'redeem':
        return Icons.redeem_rounded;
      case 'arrow_downward_rounded':
        return Icons.arrow_downward_rounded;
      case 'arrow_upward_rounded':
        return Icons.arrow_upward_rounded;
      case 'credit_card_rounded':
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'add_circle_outline_rounded':
        return Icons.add_circle_outline_rounded;
      case 'remove_circle_outline_rounded':
        return Icons.remove_circle_outline_rounded;
      case 'trending_up_rounded':
        return Icons.trending_up_rounded;
      case 'more_horiz_rounded':
      case 'more_horiz':
        return Icons.more_horiz_rounded;
      case 'wallet':
      case 'account_balance_wallet':
      case 'account_balance_wallet_rounded':
        return Icons.account_balance_wallet_rounded;
      case 'flag_rounded':
      case 'flag':
        return Icons.flag_rounded;
      case 'emoji_events_rounded':
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'laptop_rounded':
      case 'laptop':
        return Icons.laptop_rounded;
      case 'flight_rounded':
      case 'flight':
        return Icons.flight_rounded;
      case 'home_rounded':
      case 'home':
        return Icons.home_rounded;
      case 'two_wheeler_rounded':
      case 'two_wheeler':
      case 'motorcycle':
        return Icons.two_wheeler_rounded;
      case 'celebration_rounded':
      case 'celebration':
        return Icons.celebration_rounded;
      case 'beach_access_rounded':
      case 'beach_access':
        return Icons.beach_access_rounded;
      case 'favorite_rounded':
      case 'favorite':
        return Icons.favorite_rounded;
      case 'star_rounded':
      case 'star':
        return Icons.star_rounded;
      case 'today_rounded':
        return Icons.today_rounded;
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
