import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (Earthly/Chocolate based for local/premium feel)
  static const Color primary = Color(0xFF38240D); // Dark Chocolate
  static const Color primaryDark = Color(0xFF1E1B18); // Coffee Bean
  static const Color primaryLight = Color(0xFFF5EBE0); // Cream

  // Secondary/Accent (Beige/Gold for luxury)
  static const Color accent = Color(0xFFD4A373); // Sand
  static const Color secondary = Color(0xFF4A3728); // Roasted Coffee

  // Backgrounds
  static const Color background = Color(0xFFFAF9F6); // Bone White
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF1E1B18);
  static const Color textSecondary = Color(0xFF7D6E63);
  static const Color textMuted = Color(0xFFAFA59D);

  // Status
  static const Color success = Color(0xFF52796F);
  static const Color error = Color(0xFFBC4749);
  static const Color warning = Color(0xFFE29578);

  // Grocery Fresh Palette
  static const Color freshGreen = Color(0xFF2D6A4F); // Leaf Green
  static const Color organicAmber = Color(0xFFE9C46A); // Wheat
  static const Color citrusOrange = Color(0xFFF4A261); // Carrot
  static const Color skyBlue = Color(0xFF457B9D); // Water
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF38240D).withOpacity(0.04),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> premium = [
    BoxShadow(
      color: const Color(0xFF38240D).withOpacity(0.08),
      blurRadius: 25,
      offset: const Offset(0, 12),
    ),
  ];
}
