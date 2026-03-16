import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6D4C41); // Brown 600
  static const Color primaryContainer = Color(0xFF8D6E63); // Brown 400
  static const Color secondary = Color(0xFFA1887F); // Brown 300
  static const Color secondaryContainer = Color(0xFFBCAAA4); // Brown 200
  static const Color background = Color(0xFFEFEBE9); // Brown 50
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Color(0xFF3E2723); // Brown 900
  static const Color onSurface = Color(0xFF3E2723); // Brown 900
  static const Color onError = Colors.white;

  // Category Colors
  static const Color food = Color(0xFFD84315); // Deep Orange
  static const Color transport = Color(0xFF00695C); // Teal
  static const Color shopping = Color(0xFF5D4037); // Brown 700
  static const Color entertainment = Color(0xFFAD1457); // Pink
  static const Color health = Color(0xFF2E7D32); // Green
  static const Color utilities = Color(0xFF0277BD); // Light Blue
  static const Color other = Color(0xFF757575); // Grey

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food': return food;
      case 'transport': return transport;
      case 'shopping': return shopping;
      case 'entertainment': return entertainment;
      case 'health': return health;
      case 'utilities': return utilities;
      default: return other;
    }
  }
}
