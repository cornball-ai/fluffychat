// SPDX-FileCopyrightText: 2026-Present cornball.ai
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/voice/self_echo_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a transcript of the in-progress reply is echo', () {
    final filter = SelfEchoFilter();
    filter.replyText('The Cubs lost five to four to Arizona last night.');
    expect(filter.isSelfEcho('the cubs lost five to four to arizona'), isTrue);
  });

  test('ASR mangling of a few words still reads as echo', () {
    // "mockdown formatting" for "markdown formatting" survived a real run;
    // the composition bar has to tolerate a mangled word or two.
    final filter = SelfEchoFilter();
    filter.replyText(
      'Yep, that read badly because I used markdown formatting.',
    );
    expect(
      filter.isSelfEcho('that read badly because I used mockdown formatting'),
      isTrue,
    );
  });

  test('short turns are never filtered, even when they match', () {
    final filter = SelfEchoFilter();
    filter.replyText('Yes exactly, that is the plan for today.');
    expect(filter.isSelfEcho('yes exactly'), isFalse);
  });

  test('a genuine turn quoting a phrase back is kept', () {
    final filter = SelfEchoFilter();
    filter.replyText('General Kenobi. You are a bold one.');
    expect(
      filter.isSelfEcho('why did you say you are a bold one just now'),
      isFalse,
    );
  });

  test('badly mangled echo is caught by the lower speaking bar', () {
    // Real ASR of speaker bleed comes back worse than a word or two off:
    // "Cubs lost a rough one last night, 5-4 to Arizona at Chase Field"
    // was heard as this. While a reply is actually playing, a partial
    // match is echo until proven otherwise.
    final filter = SelfEchoFilter();
    filter.replyText(
      'Cubs lost a rough one last night, 5-4 to Arizona at Chase Field.',
    );
    const heard =
        'a rough one last night asterisk 5 bend forward to Arizona '
        'asterisk a chase field';
    expect(filter.isSelfEcho(heard, speaking: true), isTrue);
  });

  test('a real interruption is not echo, speaking or not', () {
    final filter = SelfEchoFilter();
    filter.replyText('Saturday looks warm and partly sunny in Naperville.');
    expect(
      filter.isSelfEcho('no wait what about Sunday evening', speaking: true),
      isFalse,
    );
  });

  test('nothing spoken yet means nothing is echo', () {
    final filter = SelfEchoFilter();
    expect(filter.isSelfEcho('hello there general kenobi'), isFalse);
  });

  test('a finished reply stays an echo source inside the tail window', () {
    var now = DateTime(2026, 8, 26, 12);
    final filter = SelfEchoFilter(clock: () => now);
    filter.replyText('The bullpen coughed up the whole thing.');
    filter.replyEnded();

    now = now.add(const Duration(seconds: 5));
    expect(filter.isSelfEcho('the bullpen coughed up the whole thing'), isTrue);

    // Reverb does not last a quarter hour: past the window the same words
    // are the user's own.
    now = now.add(const Duration(seconds: 30));
    expect(
      filter.isSelfEcho('the bullpen coughed up the whole thing'),
      isFalse,
    );
  });

  test('a new reply replaces the previous as the primary source', () {
    final now = DateTime(2026, 8, 26, 12);
    final filter = SelfEchoFilter(clock: () => now);
    filter.replyText('First reply about the weather forecast today.');
    filter.replyEnded();
    filter.replyText('Second reply naming the Chicago Fire result.');
    expect(
      filter.isSelfEcho('second reply naming the chicago fire result'),
      isTrue,
    );
    // Inside the tail window the previous reply still counts too.
    expect(
      filter.isSelfEcho('first reply about the weather forecast today'),
      isTrue,
    );
  });
}
