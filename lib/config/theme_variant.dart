// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

/// A named bundle of design decisions -- colour, typeface, shape, density --
/// that together make up one look for the app.
///
/// A variant only states the knobs it cares about and inherits the rest, so
/// adding a look to `theme_variants.dart` is a dozen lines. `FluffyThemes
/// .buildTheme` reads these knobs and assembles the [ThemeData]; a variant
/// that wants more than the knobs cover overrides [decorate] and edits the
/// finished theme.
abstract class ThemeVariant {
  const ThemeVariant();

  /// Persisted in settings, so never repurpose an id. An id that no longer
  /// resolves falls back to the default variant.
  String get id;

  /// Shown in the picker. Deliberately not localised -- these are names.
  String get name;

  /// One line, shown under the name in the picker.
  String get description;

  // --- Colour ---------------------------------------------------------

  /// Adopted as the colour-scheme seed when the variant is selected. The
  /// colour grid in settings still overrides it afterwards.
  Color get seed;

  DynamicSchemeVariant get schemeVariant => DynamicSchemeVariant.tonalSpot;

  /// Some looks only hold together at one brightness. Returning a fixed
  /// value makes the variant ignore the light/dark switch. buildTheme feeds
  /// the result to both the colour scheme and ThemeData.brightness, so the
  /// two cannot drift apart and leave Material picking text colours for the
  /// wrong background.
  Brightness resolveBrightness(Brightness requested) => requested;

  ColorScheme colorScheme(Brightness brightness, Color seedColor) =>
      ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: seedColor,
        dynamicSchemeVariant: schemeVariant,
      );

  // --- Type -----------------------------------------------------------

  /// null keeps the platform's default typeface.
  String? get fontFamily => null;

  /// null keeps Material's own tracking, which is tuned per text size.
  double? get bodyLetterSpacing => null;
  double? get titleLetterSpacing => null;
  FontWeight? get titleWeight => null;

  /// Message bubble text size, mirrored into `AppConfig.messageFontSize`.
  double get messageFontSize => 16.0;

  // --- Shape and density ----------------------------------------------

  /// Mirrored into `AppConfig.borderRadius`, which bubbles, sheets and
  /// dialogs read directly.
  double get borderRadius => 18.0;

  double get inputBorderRadius => borderRadius / 2;

  VisualDensity get visualDensity => VisualDensity.standard;

  // --- Assembly hooks --------------------------------------------------

  /// Applies the tracking and weight knobs. The family is already set by
  /// [ThemeData.fontFamily] before this runs.
  TextTheme applyTypography(TextTheme base) {
    if (bodyLetterSpacing == null &&
        titleLetterSpacing == null &&
        titleWeight == null) {
      return base;
    }
    TextStyle? title(TextStyle? style) => style?.copyWith(
      letterSpacing: titleLetterSpacing ?? style.letterSpacing,
      fontWeight: titleWeight ?? style.fontWeight,
    );
    TextStyle? body(TextStyle? style) => style?.copyWith(
      letterSpacing: bodyLetterSpacing ?? style.letterSpacing,
    );
    return base.copyWith(
      displayLarge: title(base.displayLarge),
      displayMedium: title(base.displayMedium),
      displaySmall: title(base.displaySmall),
      headlineLarge: title(base.headlineLarge),
      headlineMedium: title(base.headlineMedium),
      headlineSmall: title(base.headlineSmall),
      titleLarge: title(base.titleLarge),
      titleMedium: title(base.titleMedium),
      titleSmall: title(base.titleSmall),
      bodyLarge: body(base.bodyLarge),
      bodyMedium: body(base.bodyMedium),
      bodySmall: body(base.bodySmall),
      labelLarge: body(base.labelLarge),
      labelMedium: body(base.labelMedium),
      labelSmall: body(base.labelSmall),
    );
  }

  /// Last word on the theme, for anything the knobs above cannot express.
  ThemeData decorate(ThemeData base) => base;
}
