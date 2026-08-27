// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';

import 'package:matrix/matrix.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'platform_infos.dart';

/// System-tray presence for desktop Linux: an AppIndicator beside the
/// clock, a menu to show or quit, and close-to-tray instead of quit.
///
/// Linux only for now, because that is the desktop this fork actually runs
/// on and each platform's tray has its own conventions worth doing
/// deliberately. On GNOME the icon appears through the AppIndicator
/// extension (default-enabled on Ubuntu); the runtime dependency is
/// libayatana-appindicator3.
///
/// Menu labels are plain English rather than l10n: the tray initializes
/// before any BuildContext exists, and rebuilding the menu on locale
/// changes is machinery the two words don't yet deserve.
class TrayService with TrayListener, WindowListener {
  TrayService._();

  static final TrayService _instance = TrayService._();
  static bool _initialized = false;

  /// Idempotent, and deliberately non-fatal: a broken tray (missing
  /// system library, no indicator host) must never take the app down
  /// with it.
  static Future<void> init() async {
    if (_initialized || kIsWeb || !PlatformInfos.isLinux) return;
    _initialized = true;
    try {
      await windowManager.ensureInitialized();
      // Close hides to the tray; Quit in the tray menu actually exits.
      await windowManager.setPreventClose(true);
      windowManager.addListener(_instance);
      trayManager.addListener(_instance);
      await trayManager.setIcon('assets/logo/mini/logo_mini.png');
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(key: _show, label: 'Show'),
            MenuItem.separator(),
            MenuItem(key: _quit, label: 'Quit'),
          ],
        ),
      );
    } catch (e, s) {
      Logs().w('Tray unavailable, close will quit as before', e, s);
      try {
        await windowManager.setPreventClose(false);
      } catch (_) {}
    }
  }

  static const _show = 'show';
  static const _quit = 'quit';

  @override
  void onTrayIconMouseDown() {
    // AppIndicator clicks open the menu; this fires only where the
    // platform reports direct clicks, and then it should just show.
    _showWindow();
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case _show:
        await _showWindow();
      case _quit:
        await trayManager.destroy();
        await windowManager.setPreventClose(false);
        await windowManager.destroy();
    }
  }

  @override
  Future<void> onWindowClose() async {
    if (await windowManager.isPreventClose()) {
      await windowManager.hide();
    }
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }
}
