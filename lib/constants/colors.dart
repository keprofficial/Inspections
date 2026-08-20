import 'package:flutter/material.dart';

class AppColors {
  // ── Brand / Accent ────────────────────────────────────────────────────
  /// KEPR coral — matches Kepr-Homecare accent token (#E06655)
  static const Color coral = Color(0xFFE06655);
  static const Color coralLight = Color(0xFFF5A99D);
  static const Color coralDark = Color(0xFFB84D3D);
  static const Color crimson = Color(0xFFB84D3D); // alias for coralDark

  /// Near-black primary — matches Kepr-Homecare primary token (#18181B)
  static const Color navy = Color(0xFF18181B);

  // ── Zinc neutral scale (Kepr-Homecare) ───────────────────────────────
  static const Color neutral50  = Color(0xFFF7F7F8);
  static const Color neutral100 = Color(0xFFEFEFF1);
  static const Color neutral200 = Color(0xFFE4E4E7);
  static const Color neutral300 = Color(0xFFD4D4D8);
  static const Color neutral400 = Color(0xFFA1A1AA);
  static const Color neutral500 = Color(0xFF71717A);
  static const Color neutral600 = Color(0xFF52525B);
  static const Color neutral700 = Color(0xFF3F3F46);
  static const Color neutral800 = Color(0xFF27272A);
  static const Color neutral900 = Color(0xFF18181B);

  // ── Semantic foreground ───────────────────────────────────────────────
  static const Color foreground          = Color(0xFF0A0A0A);
  static const Color foregroundSecondary = Color(0xFF52525B);
  static const Color foregroundMuted     = Color(0xFF71717A);

  // ── Surfaces ─────────────────────────────────────────────────────────
  static const Color surface          = Color(0xFFF7F7F8);
  static const Color surfaceSecondary = Color(0xFFEFEFF1);
  static const Color surfaceOverlay   = Color(0xFFFFFFFF);

  // ── Status ────────────────────────────────────────────────────────────
  /// Apple-green success (#34C759)
  static const Color success      = Color(0xFF34C759);
  static const Color successLight = Color(0xFFE8F5E9);

  static const Color warning      = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color error        = Color(0xFFEF4444);
  static const Color errorLight   = Color(0xFFFEE4E6);

  static const Color info         = Color(0xFF3B82F6);
  static const Color infoLight    = Color(0xFFDEE7F6);

  // ── Borders ───────────────────────────────────────────────────────────
  static const Color border       = Color(0x4D000000);  // black @ 30%

  // ── Gradient color stops (Kepr-Homecare KEPRGradients) ───────────────

  /// Brand accent gradient: light peachy coral → main coral
  static const List<Color> accentGradient = [
    Color(0xFFF0A080),
    Color(0xFFE06655),
  ];

  /// Light hero: coral (bottom) → warm orange (top) — AppBar / headers
  static const List<Color> lightHero = [
    Color(0xFFE06655),
    Color(0xFFFF9645),
  ];

  /// Sunrise page background: coral → peachy mid → cream top
  static const List<Color> orbitSunrise = [
    Color(0xFFE06655),
    Color(0xFFF5B5A1),
    Color(0xFFF8F8F8),
  ];

  /// Dark hero: deep-space purple — used for society/high-rise backgrounds
  static const List<Color> darkHero = [
    Color(0xFF24243E),
    Color(0xFF302B63),
    Color(0xFF0F0C29),
  ];

  /// Brand icon: sunrise orange → coral
  static const List<Color> brandIcon = [
    Color(0xFFF6962E),
    Color(0xFFEE6F48),
  ];

  // ── Shadows ───────────────────────────────────────────────────────────
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x08000000),
      offset: Offset(0, 4),
      blurRadius: 6,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 10),
      blurRadius: 15,
    ),
  ];
}
