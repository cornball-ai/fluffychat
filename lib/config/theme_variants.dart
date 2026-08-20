// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/theme_variant.dart';
import 'package:material_ui/material_ui.dart';

/// The looks the style settings offer, and the lookup that turns a stored id
/// back into one.
abstract class ThemeVariants {
  static const ThemeVariant fluffy = _Fluffy();
  static const ThemeVariant console = _Console();
  static const ThemeVariant slate = _Slate();
  static const ThemeVariant paper = _Paper();
  static const ThemeVariant pillow = _Pillow();
  static const ThemeVariant arcade = _Arcade();

  /// Picker order.
  static const List<ThemeVariant> all = [
    fluffy,
    console,
    slate,
    paper,
    pillow,
    arcade,
  ];

  /// Used for an unset or unrecognised stored id, so dropping a variant
  /// degrades to the stock look instead of crashing on next launch.
  static const ThemeVariant fallback = fluffy;

  static ThemeVariant byId(String id) =>
      all.firstWhere((variant) => variant.id == id, orElse: () => fallback);
}

/// Upstream FluffyChat, unchanged. Everything here has to keep matching the
/// stock look, because it is what someone who never opens the picker sees.
class _Fluffy extends ThemeVariant {
  const _Fluffy();

  @override
  String get id => 'fluffy';
  @override
  String get name => 'Fluffy';
  @override
  String get description => 'The stock look.';

  @override
  Color get seed => const Color(0xFF5625BA);
  @override
  DynamicSchemeVariant get schemeVariant => DynamicSchemeVariant.rainbow;
}

/// Grey, tight and small: made for scanning a long room list rather than for
/// reading one conversation.
class _Console extends ThemeVariant {
  const _Console();

  @override
  String get id => 'console';
  @override
  String get name => 'Console';
  @override
  String get description => 'Dense and desaturated.';

  @override
  Color get seed => const Color(0xFF4A6572);
  @override
  DynamicSchemeVariant get schemeVariant => DynamicSchemeVariant.neutral;

  @override
  String get fontFamily => 'Cantarell';
  @override
  double? get titleLetterSpacing => -0.2;
  @override
  double get messageFontSize => 15.0;

  @override
  double get borderRadius => 6.0;
  @override
  double get inputBorderRadius => 4.0;
  @override
  VisualDensity get visualDensity => VisualDensity.compact;

  @override
  ThemeData decorate(ThemeData base) {
    final colorScheme = base.colorScheme;
    return base.copyWith(
      dividerColor: colorScheme.outlineVariant,
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.transparent,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

/// A plain modern default that is not Material purple. Shares Cantarell with
/// Console, which is the point: a second look costs nothing but a class.
class _Slate extends ThemeVariant {
  const _Slate();

  @override
  String get id => 'slate';
  @override
  String get name => 'Slate';
  @override
  String get description => 'Cool and even, with a little colour.';

  @override
  Color get seed => const Color(0xFF2F6F6B);
  @override
  DynamicSchemeVariant get schemeVariant => DynamicSchemeVariant.fidelity;

  @override
  String get fontFamily => 'Cantarell';

  @override
  double get borderRadius => 12.0;
}

/// Serif and warm, for when the day is mostly spent reading long messages.
class _Paper extends ThemeVariant {
  const _Paper();

  @override
  String get id => 'paper';
  @override
  String get name => 'Paper';
  @override
  String get description => 'Serif and warm, tuned for long reading.';

  @override
  Color get seed => const Color(0xFF8A6D3B);
  @override
  DynamicSchemeVariant get schemeVariant => DynamicSchemeVariant.fidelity;

  @override
  String get fontFamily => 'Caladea';
  @override
  double get messageFontSize => 17.0;

  @override
  double get borderRadius => 4.0;

  @override
  ThemeData decorate(ThemeData base) => base.copyWith(
    dividerColor: base.colorScheme.outlineVariant.withAlpha(128),
    appBarTheme: base.appBarTheme.copyWith(
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

/// Neon on near-black, after the ARCADE skin in the mente app. The only
/// variant that hand-authors its palette instead of seeding one: Material's
/// dark surfaces are grey, and grey is the one thing this look cannot have.
/// It also pins itself to dark, so the light/dark switch does not take the
/// black away underneath it.
class _Arcade extends ThemeVariant {
  const _Arcade();

  static const Color _magenta = Color(0xFFFF2E97);
  static const Color _cyan = Color(0xFF00EAFF);
  static const Color _neon = Color(0xFF39FF14);
  static const Color _void = Color(0xFF0A0510);
  static const Color _panel = Color(0xFF170A24);
  static const Color _line = Color(0xFF6A2B8F);
  static const Color _ice = Color(0xFFEAFCFF);

  @override
  String get id => 'arcade';
  @override
  String get name => 'Arcade';
  // Says "fixed" because the colour grid below the picker genuinely does
  // nothing while this is selected: the palette is written out here rather
  // than seeded. A control that silently ignores you reads as broken.
  @override
  String get description => 'Neon on black. Always dark, fixed colours.';

  @override
  Color get seed => _magenta;

  @override
  Brightness resolveBrightness(Brightness requested) => Brightness.dark;

  @override
  ColorScheme colorScheme(Brightness brightness, Color seedColor) =>
      ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: _magenta,
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      ).copyWith(
        surface: _void,
        onSurface: _ice,
        onSurfaceVariant: const Color(0xFFC9A6E0),
        surfaceContainerLowest: const Color(0xFF06030A),
        surfaceContainerLow: const Color(0xFF120720),
        surfaceContainer: _panel,
        surfaceContainerHigh: const Color(0xFF1F0E31),
        surfaceContainerHighest: const Color(0xFF2A1440),
        primary: _magenta,
        onPrimary: const Color(0xFF17000B),
        primaryContainer: const Color(0xFF7A0048),
        onPrimaryContainer: const Color(0xFFFFD9E9),
        secondary: _cyan,
        onSecondary: const Color(0xFF00212A),
        secondaryContainer: const Color(0xFF00404F),
        onSecondaryContainer: const Color(0xFFB8F6FF),
        tertiary: _neon,
        onTertiary: const Color(0xFF07240A),
        tertiaryContainer: const Color(0xFF10240A),
        onTertiaryContainer: const Color(0xFFB7FFA8),
        error: const Color(0xFFFF2E2E),
        onError: const Color(0xFF2A0808),
        outline: _line,
        outlineVariant: const Color(0xFF43195C),
      );

  @override
  double? get titleLetterSpacing => 1.1;
  @override
  FontWeight? get titleWeight => FontWeight.w900;

  @override
  double get borderRadius => 2.0;
  @override
  double get inputBorderRadius => 2.0;

  @override
  ThemeData decorate(ThemeData base) {
    final colorScheme = base.colorScheme;
    return base.copyWith(
      dividerColor: _line,
      scaffoldBackgroundColor: _void,
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: _cyan),
        shape: const RoundedRectangleBorder(),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: _void,
        foregroundColor: _cyan,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _magenta,
          foregroundColor: const Color(0xFF17000B),
          elevation: 0,
          padding: const EdgeInsets.all(16),
          shape: const RoundedRectangleBorder(),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _cyan,
          side: const BorderSide(width: 1, color: _cyan),
          shape: const RoundedRectangleBorder(),
        ),
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: _magenta,
        foregroundColor: const Color(0xFF17000B),
        shape: const RoundedRectangleBorder(),
      ),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        color: _neon,
        refreshBackgroundColor: colorScheme.surfaceContainer,
      ),
    );
  }
}

/// The opposite pole from Console: round, soft and loud.
class _Pillow extends ThemeVariant {
  const _Pillow();

  @override
  String get id => 'pillow';
  @override
  String get name => 'Pillow';
  @override
  String get description => 'Round, soft and loud.';

  @override
  Color get seed => const Color(0xFFE8617A);
  @override
  DynamicSchemeVariant get schemeVariant => DynamicSchemeVariant.expressive;

  @override
  String get fontFamily => 'Comfortaa';
  @override
  double? get titleLetterSpacing => 0.3;

  @override
  double get borderRadius => 28.0;
  @override
  double get inputBorderRadius => 24.0;

  @override
  ThemeData decorate(ThemeData base) => base.copyWith(
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: base.colorScheme.secondaryContainer,
        foregroundColor: base.colorScheme.onSecondaryContainer,
        elevation: 0,
        padding: const EdgeInsets.all(16),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(width: 1, color: base.colorScheme.primary),
        shape: const StadiumBorder(),
      ),
    ),
  );
}
