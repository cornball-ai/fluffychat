// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/setting_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A setting is written on the settings page while the page it configures is
/// still mounted behind it, so the write has to announce itself. Without this
/// the chat list picked up a unified-inbox toggle in pieces: rooms from both
/// accounts at the next sync, but no account badges and a sync subscription
/// still pointed at one account, because those were captured by a build that
/// never re-ran.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.init(loadWebConfigFile: false);
  });

  test('a bool write bumps the change counter', () async {
    final before = AppSettings.changes.value;
    await AppSettings.unifiedInbox.setItem(true);
    expect(AppSettings.changes.value, greaterThan(before));
    expect(AppSettings.unifiedInbox.value, isTrue);
  });

  test('turning it back off announces itself too', () async {
    await AppSettings.unifiedInbox.setItem(true);
    final before = AppSettings.changes.value;
    await AppSettings.unifiedInbox.setItem(false);
    expect(AppSettings.changes.value, greaterThan(before));
    expect(AppSettings.unifiedInbox.value, isFalse);
  });

  test('a listener is notified, not merely a counter incremented', () async {
    var notified = 0;
    void listener() => notified++;
    AppSettings.changes.addListener(listener);
    addTearDown(() => AppSettings.changes.removeListener(listener));

    await AppSettings.unifiedInbox.setItem(true);
    expect(notified, 1);
  });

  test('every typed write announces itself, not just bools', () async {
    // The chat list rebuilds off this notifier, and it reads string and int
    // settings too -- the active filter, the preview line count.
    final before = AppSettings.changes.value;
    await AppSettings.chatFilter.setItem('unread');
    await AppSettings.messagePreviewMaxLines.setItem(12);
    await AppSettings.fontSizeFactor.setItem(1.5);
    expect(AppSettings.changes.value, before + 3);
  });
}
