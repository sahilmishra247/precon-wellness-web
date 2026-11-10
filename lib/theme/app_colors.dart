import 'package:flutter/material.dart';

/// One colour family: the strong colour, a darker ink for text and icons on
/// light backgrounds, and a soft tint for fills.
class AreaColor {
  final Color color;
  final Color ink;
  final Color tint;
  const AreaColor(this.color, this.ink, this.tint);
}

/// Centralised design tokens for Precon Wellness.
/// Navy and leaf green come from the logo and match preconwellness.com.
/// Each part of the app has its own area colour, so diet, workouts, progress,
/// notes and sessions are recognisable at a glance.
///
/// The app is light only. The `isDark` parameters on the helpers are kept so
/// existing call sites compile, and are ignored.
abstract class AppColors {
  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------
  static const Color navy = Color(0xFF07294D);
  static const Color navyDeep = Color(0xFF041B34);
  static const Color leaf = Color(0xFF58A725);
  static const Color leafInk = Color(0xFF3D7A17); // buttons and green text (5:1 on white)
  static const Color leafTint = Color(0xFFEAF5E1);

  /// Primary action colour (buttons, links, focus).
  static const Color primary = leafInk;
  static const Color primaryLight = leaf;
  static const Color primaryMuted = leafTint;

  // Coral marks what needs attention (next session, join call).
  static const Color accent = Color(0xFFE76F51);
  static const Color accentLight = accent;
  static const Color accentTint = Color(0xFFFCECE7);
  static const Color accentInkLight = Color(0xFFB4472E);

  // ---------------------------------------------------------------------------
  // Areas
  // ---------------------------------------------------------------------------
  static const AreaColor diet = AreaColor(Color(0xFFF4A261), Color(0xFFB5651D), Color(0xFFFDF0E4));
  static const AreaColor workout = AreaColor(Color(0xFF4FA3D9), Color(0xFF1F6FA6), Color(0xFFE5F1FA));
  static const AreaColor progress = AreaColor(leaf, leafInk, leafTint);
  static const AreaColor notes = AreaColor(Color(0xFF8E7CC3), Color(0xFF5E4B9A), Color(0xFFEFEBF8));
  static const AreaColor sessions = AreaColor(accent, accentInkLight, accentTint);
  static const AreaColor library = AreaColor(Color(0xFFE9B949), Color(0xFF8A6512), Color(0xFFFBF3DE));
  static const AreaColor people = AreaColor(navy, navy, Color(0xFFE6EDF5));
  static const AreaColor neutral = AreaColor(Color(0xFF7A8899), Color(0xFF4A5B70), Color(0xFFEEF1EC));

  /// Rotating colours for avatars, picked from the person's name.
  static const List<AreaColor> avatarPalette = [progress, workout, diet, notes, sessions, library, people];

  static AreaColor avatarFor(String name) {
    var h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return avatarPalette[h % avatarPalette.length];
  }

  /// The area an icon belongs to, so navigation rows colour themselves.
  static AreaColor areaForIcon(IconData icon) {
    final c = icon.codePoint;
    bool any(List<IconData> l) => l.any((i) => i.codePoint == c);
    if (any([Icons.restaurant_outlined, Icons.restaurant, Icons.restaurant_menu_rounded, Icons.restaurant_rounded])) return diet;
    if (any([Icons.fitness_center_outlined, Icons.fitness_center, Icons.fitness_center_rounded])) return workout;
    if (any([Icons.show_chart_rounded, Icons.monitor_weight_outlined, Icons.trending_up_rounded, Icons.show_chart])) return progress;
    if (any([Icons.note_outlined, Icons.note_alt_outlined, Icons.notes_rounded, Icons.sticky_note_2_outlined])) return notes;
    if (any([Icons.calendar_month_outlined, Icons.calendar_today_outlined, Icons.event_outlined, Icons.video_call_rounded])) return sessions;
    if (any([Icons.menu_book_outlined, Icons.menu_book_rounded, Icons.auto_stories_outlined])) return library;
    if (any([Icons.people_outline_rounded, Icons.person_outline_rounded, Icons.manage_accounts_outlined, Icons.badge_outlined, Icons.person_add_outlined, Icons.home_outlined])) return people;
    return neutral;
  }

  // ---------------------------------------------------------------------------
  // Surfaces and text
  // ---------------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF4F7F1); // soft sage
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightRaised = Color(0xFFF8FAF6);
  static const Color lightBorder = Color(0xFFE1E8DC);
  static const Color lightBorderSubtle = Color(0xFFEEF2EA);
  static const Color lightTextPrimary = Color(0xFF0B2340);
  static const Color lightTextSecondary = Color(0xFF4A5B70);
  static const Color lightTextMuted = Color(0xFF7A8899);
  static const Color lightInputFill = Color(0xFFF8FAF6);

  // ---------------------------------------------------------------------------
  // Navigation rail (desktop)
  // ---------------------------------------------------------------------------
  static const Color railLight = navy;
  static const Color railInk = Color(0xFFC6D3E1);
  static const Color railActive = leaf;

  // ---------------------------------------------------------------------------
  // Semantic
  // ---------------------------------------------------------------------------
  static const Color error = Color(0xFFD64545);
  static const Color errorMuted = Color(0x14D64545);
  static const Color warning = Color(0xFFD9822B);
  static const Color warningMuted = Color(0x14D9822B);
  static const Color success = leafInk;
  static const Color successMuted = leafTint;
  static const Color info = Color(0xFF1F6FA6);
  static const Color infoMuted = Color(0x141F6FA6);

  // ---------------------------------------------------------------------------
  // Depth
  // ---------------------------------------------------------------------------
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0F07294D), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A07294D), blurRadius: 3, offset: Offset(0, 1)),
  ];

  // Health tags: "Take care" level (amber). "Must avoid" reuses coral.
  static const Color cautionInkLight = Color(0xFFB45309);
  static const Color cautionInkDark = Color(0xFFF0A54A);
  static const Color cautionTintLight = Color(0xFFFEF3E2);
  static const Color cautionTintDark = Color(0x21F0A54A);

  // ---------------------------------------------------------------------------
  // Spacing scale
  // ---------------------------------------------------------------------------
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  // ---------------------------------------------------------------------------
  // Border radii
  // ---------------------------------------------------------------------------
  static const double radiusSmall = 10;
  static const double radiusMedium = 12;
  static const double radiusLarge = 18;
  static const double radiusXL = 24;

  // ---------------------------------------------------------------------------
  // Helpers (light only; `isDark` is ignored)
  // ---------------------------------------------------------------------------
  static Color bg([bool _ = false]) => lightBackground;
  static Color surface([bool _ = false]) => lightSurface;
  static Color raised([bool _ = false]) => lightRaised;
  static Color border([bool _ = false]) => lightBorder;
  static Color textPrimary([bool _ = false]) => lightTextPrimary;
  static Color textSecondary([bool _ = false]) => lightTextSecondary;
  static Color textMuted([bool _ = false]) => lightTextMuted;
  static Color inputFill([bool _ = false]) => lightInputFill;
  static Color brand([bool _ = false]) => primary;
  static Color rail([bool _ = false]) => railLight;
  static Color accentColor([bool _ = false]) => accent;
  static Color accentMuted([bool _ = false]) => accentTint;
  static Color accentInk([bool _ = false]) => accentInkLight;
  static Color brandMuted([bool _ = false]) => primaryMuted;
  static Color cautionInk([bool _ = false]) => cautionInkLight;
  static Color cautionMuted([bool _ = false]) => cautionTintLight;
  static Color neutralMuted([bool _ = false]) => lightBorderSubtle;
}
