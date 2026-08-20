// SPDX-FileCopyrightText: 2026-Present cornball.ai
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/theme_variants.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Covers the two ways the variant layer fails without raising anything.
///
/// A variant naming a typeface that is not bundled renders in the platform
/// default instead, so two variants quietly become the same look. And the
/// shape knobs reach widgets by being mirrored onto AppConfig during the
/// theme build rather than by being read off ThemeData, so a build path that
/// skips the mirror leaves every corner at whatever loaded first.
void main() {
  group('variant registry', () {
    test('every id is unique and resolves back to its own variant', () {
      final ids = ThemeVariants.all.map((variant) => variant.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate variant id');
      for (final variant in ThemeVariants.all) {
        expect(ThemeVariants.byId(variant.id), same(variant));
      }
    });

    test('an unknown id degrades to the fallback', () {
      expect(ThemeVariants.byId('no-such-variant'), ThemeVariants.fallback);
      expect(ThemeVariants.byId(''), ThemeVariants.fallback);
      expect(ThemeVariants.all, contains(ThemeVariants.fallback));
    });
  });

  test('every typeface a variant names is bundled and present on disk', () {
    // Parsed rather than restated: a hard-coded copy of the family list would
    // only ever agree with itself, which is the case this test exists to
    // catch. Flutter's font declarations are a flat enough shape to read with
    // a couple of patterns, so this stays free of a yaml dependency.
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final declaredFamilies = <String>{};
    final declaredAssets = <String>[];
    for (final line in pubspec) {
      final family = RegExp(r'^\s*-\s*family:\s*(\S+)\s*$').firstMatch(line);
      if (family != null) declaredFamilies.add(family[1]!);
      final asset = RegExp(
        r'^\s*-\s*asset:\s*(assets/fonts/\S+)\s*$',
      ).firstMatch(line);
      if (asset != null) declaredAssets.add(asset[1]!);
    }

    // Guard the instrument itself: if the patterns stop matching, the loop
    // above finds nothing and every family below passes vacuously.
    expect(
      declaredFamilies,
      isNotEmpty,
      reason: 'parsed no font families out of pubspec.yaml',
    );

    final used = ThemeVariants.all
        .map((variant) => variant.fontFamily)
        .whereType<String>()
        .toSet();
    expect(
      used,
      isNotEmpty,
      reason: 'no variant names a typeface, so this test proves nothing',
    );
    for (final family in used) {
      expect(
        declaredFamilies,
        contains(family),
        reason: '$family is used by a variant but not declared in pubspec.yaml',
      );
    }
    for (final asset in declaredAssets) {
      expect(
        File(asset).existsSync(),
        isTrue,
        reason: '$asset is declared in pubspec.yaml but missing on disk',
      );
    }
  });

  group('buildTheme', () {
    /// Builds under a real BuildContext, which buildTheme needs for its
    /// column-mode media query. No Matrix provider is involved, so this
    /// settles where upstream's own widget tests do not.
    Future<ThemeData> build(WidgetTester tester, variant) async {
      late ThemeData built;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              built = FluffyThemes.buildTheme(
                context,
                Brightness.light,
                variant.seed,
                variant,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return built;
    }

    testWidgets('mirrors the variant shape knobs onto AppConfig', (
      tester,
    ) async {
      for (final variant in ThemeVariants.all) {
        await build(tester, variant);
        expect(
          AppConfig.borderRadius,
          variant.borderRadius,
          reason: '${variant.id} did not mirror its corner radius',
        );
        expect(
          AppConfig.messageFontSize,
          variant.messageFontSize,
          reason: '${variant.id} did not mirror its message font size',
        );
      }
    });

    testWidgets('carries the variant typeface into the theme', (tester) async {
      // A variant that names no family keeps the platform's own face, which
      // Flutter resolves to a real name rather than leaving null.
      final platformFace = ThemeData().textTheme.bodyMedium?.fontFamily;
      for (final variant in ThemeVariants.all) {
        final theme = await build(tester, variant);
        expect(
          theme.textTheme.bodyMedium?.fontFamily,
          variant.fontFamily ?? platformFace,
          reason: '${variant.id} lost its typeface',
        );
      }
    });

    testWidgets('the fallback variant still paints the stock look', (
      tester,
    ) async {
      final theme = await build(tester, ThemeVariants.fallback);
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        ThemeData().textTheme.bodyMedium?.fontFamily,
      );
      expect(AppConfig.borderRadius, 18.0);
      expect(AppConfig.messageFontSize, 16.0);
      expect(theme.visualDensity, VisualDensity.standard);
    });

    testWidgets('variants are actually distinguishable from one another', (
      tester,
    ) async {
      final looks = <String>{};
      for (final variant in ThemeVariants.all) {
        final theme = await build(tester, variant);
        looks.add(
          '${theme.textTheme.bodyMedium?.fontFamily}'
          '/${variant.borderRadius}'
          '/${theme.colorScheme.primary}'
          '/${variant.visualDensity}',
        );
      }
      expect(
        looks.length,
        ThemeVariants.all.length,
        reason: 'two variants resolve to the same font, shape and colour',
      );
    });
  });
}
