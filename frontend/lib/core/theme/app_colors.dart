import 'package:flutter/material.dart';

/// Couleurs officielles AS ONE Facility Management
class AppColors {
  static const Color primary = Color(0xFF005C9C);      // Bleu foncé
  static const Color primaryDark = Color(0xFF00447A);  // Bleu plus sombre
  static const Color secondary = Color(0xFF0085B0);    // Bleu clair
  static const Color secondaryLight = Color(0xFF4DB0D6); // Bleu très clair
  static const Color accent = Color(0xFF00845F);       // Vert émeraude
  static const Color success = Color(0xFF00845F);
  
  // Couleurs de fond et de surface
  static const Color background = Color(0xFFF0F4F8);   // Gris bleuté très clair
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFAFCFF); // Surface légèrement bleutée
  
  // Textes
  static const Color textPrimary = Color(0xFF1A2634);
  static const Color textSecondary = Color(0xFF64748B);
  
  // Feedback
  static const Color danger = Color(0xFFE11D48);
  static const Color warning = Color(0xFFF59E0B);
  static const Color border = Color(0xFFE2E8F0);

  // Dégradés premium
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF00A87A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
