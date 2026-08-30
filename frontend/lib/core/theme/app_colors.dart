import 'package:flutter/material.dart';

/// Couleurs officielles & Design System AS ONE Facility Management
class AppColors {
  // Couleurs de Marque Primaires
  static const Color primary = Color(0xFF005C9C);        // Bleu saphir AS ONE
  static const Color primaryDark = Color(0xFF07213A);    // Bleu nuit profond
  static const Color primaryLight = Color(0xFF0077C8);   // Bleu éclatant
  static const Color secondary = Color(0xFF00A3FF);      // Cyan électrique
  static const Color secondaryLight = Color(0xFFE0F2FE); // Bleu givré très doux
  static const Color accent = Color(0xFF10B981);         // Vert émeraude vibrant
  static const Color accentDark = Color(0xFF047857);

  // Statuts & Indicateurs
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Surfaces & Fonds (Design aéré & lumineux)
  static const Color background = Color(0xFFF8FAFC);     // Arrière-plan moderne Slate
  static const Color surface = Color(0xFFFFFFFF);        // Blanc pur
  static const Color surfaceElevated = Color(0xFFF1F5F9);// Surface surélevée douce
  static const Color surfaceGlass = Color(0xCCFFFFFF);   // Verre dépoli

  // Textes & Typographie
  static const Color textPrimary = Color(0xFF0F172A);    // Noir d'encre doux
  static const Color textSecondary = Color(0xFF64748B);  // Gris ardoise médian
  static const Color textTertiary = Color(0xFF94A3B8);   // Gris discret
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Bordures & Séparateurs
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderGlow = Color(0x3300A3FF);

  // Dégradés Signature
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF005C9C), Color(0xFF0085B0), Color(0xFF00A3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF0B2545), Color(0xFF134074)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0xEEFFFFFF), Color(0xCCF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Ombres Ambiantes
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -2,
    ),
  ];
}
