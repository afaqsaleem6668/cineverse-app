import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Color Palette
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color cardBg = Color(0xFF1A1A26);
  static const Color accent = Color(0xFFF5C518); // IMDB gold
  static const Color accentDark = Color(0xFFD4A017);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF6B6B80);
  static const Color divider = Color(0xFF2A2A3A);
  static const Color error = Color(0xFFFF4757);
  static const Color success = Color(0xFF2ED573);
  static const Color navBg = Color(0xFF0D0D15);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF5C518), Color(0xFFD4A017)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E2E), Color(0xFF12121A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient posterOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static TextStyle get headingLarge => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get headingMedium => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get sectionTitle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.3,
      );

  static TextStyle get bodyText => GoogleFonts.poppins(
        fontSize: 14,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 11,
        color: textMuted,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get accentText => GoogleFonts.poppins(
        fontSize: 13,
        color: accent,
        fontWeight: FontWeight.w600,
      );

  // Decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static InputDecoration searchDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: textMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: textMuted, size: 20),
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: divider, width: 0.5),
        ),
      );
}
