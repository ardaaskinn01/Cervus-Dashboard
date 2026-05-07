import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgColorStart = Color(0xFF14142B);
  static const Color bgColorEnd = Color(0xFF0F0F22);
  static const Color sidebarColor = Color(0x991E1E2C); 
  static const Color primaryColor = Color(0xFF7E57C2);
  static const Color secondaryColor = Color(0xFF00E5FF);
  static const Color textColor = Colors.white;
  static const Color cardColor = Color(0x80252538); 
  static const Color borderColor = Color(0x33FFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent, 
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        surface: sidebarColor,
        secondary: secondaryColor,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      useMaterial3: true,
    );
  }

  static BoxDecoration get glassDecoration {
    return BoxDecoration(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.borderColor),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}
