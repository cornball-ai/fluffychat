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

  /// Picker order.
  static const List<ThemeVariant> all = [fluffy, console, slate, paper, pillow];

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
