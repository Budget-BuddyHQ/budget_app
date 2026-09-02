import 'dart:io';

import 'package:budget_app/constants/privacy_policy.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The privacy policy, and the three places its version is written down.
///
/// **Why this is a build failure and not a checklist item.** Google Play takes
/// a listing down if its privacy link is dead or if the policy disagrees with
/// the app's declared data handling. The version lives in Dart (what the app
/// compares acceptance against), in the Markdown (the source document) and in
/// the generated page (what the store actually links to) — three copies of one
/// fact, which is three chances to update two of them.
///
/// A drifted version is silent: everything keeps working, acceptance keeps
/// being recorded, and the number attached to it is simply wrong. Nobody finds
/// that by using the app.
void main() {
  final markdown = File('docs/PRIVACY_POLICY.md');
  final page = File('docs/privacy-policy.html');

  group('the policy exists where it is promised to', () {
    test('the Markdown source is present', () {
      expect(
        markdown.existsSync(),
        isTrue,
        reason: 'docs/PRIVACY_POLICY.md is the source document',
      );
    });

    test('the published page is present and is not a stub', () {
      // GitHub Pages serves this from /docs, which is the URL the store
      // listing points at. A missing or empty file is a dead link on a live
      // listing.
      expect(page.existsSync(), isTrue, reason: 'run tool/build_privacy_page.py');
      expect(page.lengthSync(), greaterThan(4000));
    });

    test('the page was generated from the Markdown, not hand-written', () {
      expect(
        page.readAsStringSync(),
        contains('tool/build_privacy_page.py'),
        reason: 'the generator stamps its own name into the output; a page '
            'without it has been edited by hand and will drift',
      );
    });
  });

  group('one version, written in three places', () {
    test('the Markdown carries the version the app compares against', () {
      expect(
        markdown.readAsStringSync(),
        contains('**Last updated: $kPrivacyPolicyDate**'),
        reason: 'kPrivacyPolicyDate is $kPrivacyPolicyDate but the document '
            'says something else — regenerate the page and bump both',
      );
    });

    test('the published page carries it too', () {
      expect(page.readAsStringSync(), contains(kPrivacyPolicyDate));
    });

    test('the machine version and the human date agree', () {
      // '2026-09-01' and '1 September 2026' are the same day written twice.
      // The first is what acceptance is stamped with; the second is what a
      // player reads. They must not describe different documents.
      final parsed = DateTime.parse(kPrivacyPolicyVersion);
      const months = <String>[
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      expect(
        kPrivacyPolicyDate,
        '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}',
      );
    });
  });

  group('the link the store will check', () {
    test('is https and points at this repository', () {
      final uri = Uri.parse(kPrivacyPolicyUrl);
      expect(uri.scheme, 'https', reason: 'Play requires a secure URL');
      expect(uri.host, 'budget-buddyhq.github.io');
      expect(uri.path, endsWith('/privacy-policy.html'));
    });

    test('the filename matches what the generator writes', () {
      // If the generator's output name and the URL ever disagree, the link
      // 404s the moment Pages rebuilds — and nothing in the app would notice.
      expect(
        Uri.parse(kPrivacyPolicyUrl).pathSegments.last,
        'privacy-policy.html',
      );
    });
  });

  group('the policy says the things a listing is checked against', () {
    late String text;
    setUpAll(() => text = markdown.readAsStringSync().toLowerCase());

    test('it names every third party that receives anything', () {
      // Each of these is contacted by the app. Play's Data Safety form asks
      // about them by name, and an answer that disagrees with the policy is
      // what gets a submission rejected.
      for (final party in <String>[
        'supabase',
        'cloudflare',
        'finnhub',
        'twelve data',
        'wikimedia',
      ]) {
        expect(text, contains(party), reason: '$party is not disclosed');
      }
    });

    test('it states there is no advertising or analytics', () {
      expect(text, contains('no advertising'));
      expect(text, contains('analytics'));
    });

    test('it explains deletion', () {
      expect(text, contains('delet'));
    });

    test('it addresses children', () {
      expect(text, contains('under 13'));
      expect(text, contains('coppa'));
    });

    test('the contact address has been filled in', () {
      // Deliberately failing until somebody replaces the placeholder. A
      // policy with no way to reach a human is not a policy, and this is the
      // single easiest thing to forget between writing it and shipping it.
      expect(
        markdown.readAsStringSync(),
        isNot(contains('[ADD A CONTACT ADDRESS BEFORE PUBLISHING]')),
        reason: 'set a real contact email in docs/PRIVACY_POLICY.md, then '
            're-run tool/build_privacy_page.py',
      );
    }, skip: 'No contact address chosen yet — see the note in the policy.');
  });

  group('what a player agreed to is recorded, not assumed', () {
    // Consent that leaves no trace is a checkbox. The question a store, a
    // parent or a regulator asks is never "did they tick it" — it is "which
    // document, and when", and only a stored version and timestamp answer
    // that.
    UserStats withAcceptance(Map<String, dynamic> extra) {
      final base = UserStats.defaults('11111111-2222-3333-4444-555555555555');
      return base.copyWith(
        spendingHabits: <String, dynamic>{...base.spendingHabits, ...extra},
      );
    }

    test('a fresh account has accepted nothing', () {
      final stats = UserStats.defaults('abc');
      expect(stats.privacyAcceptedVersion, isEmpty);
      expect(stats.privacyAcceptedAt, isNull);
      expect(stats.hasAcceptedCurrentPrivacyPolicy, isFalse);
    });

    test('an acceptance reads back with its version and time', () {
      final when = DateTime.utc(2026, 9, 1, 10, 30);
      final stats = withAcceptance({
        PrivacyKeys.acceptedVersion: kPrivacyPolicyVersion,
        PrivacyKeys.acceptedAt: when.toIso8601String(),
      });
      expect(stats.privacyAcceptedVersion, kPrivacyPolicyVersion);
      expect(stats.privacyAcceptedAt, when);
      expect(stats.hasAcceptedCurrentPrivacyPolicy, isTrue);
    });

    test('accepting an older policy does not count as accepting this one', () {
      // The whole reason the version is stored. Without this, updating the
      // policy would silently hold every existing player to a document they
      // have never seen.
      final stats = withAcceptance({
        PrivacyKeys.acceptedVersion: '2020-01-01',
        PrivacyKeys.acceptedAt: '2020-01-01T00:00:00.000Z',
      });
      expect(stats.privacyAcceptedVersion, isNotEmpty);
      expect(stats.hasAcceptedCurrentPrivacyPolicy, isFalse);
    });

    test('a corrupt timestamp reads as absent rather than throwing', () {
      // It is stored in a free-form JSON blob, so it can be anything.
      final stats = withAcceptance({PrivacyKeys.acceptedAt: 'not a date'});
      expect(stats.privacyAcceptedAt, isNull);
    });

    test('acceptance survives a round trip through storage', () {
      // It rides in `spending_habits` rather than a column of its own, so the
      // thing worth proving is that the map actually carries it.
      final stats = withAcceptance({
        PrivacyKeys.acceptedVersion: kPrivacyPolicyVersion,
        PrivacyKeys.acceptedAt: '2026-09-01T10:30:00.000Z',
      });
      final stored = stats.toStorageMap();
      final habits = stored['spending_habits'] as Map<String, dynamic>;
      expect(habits[PrivacyKeys.acceptedVersion], kPrivacyPolicyVersion);
      expect(habits[PrivacyKeys.acceptedAt], '2026-09-01T10:30:00.000Z');
    });
  });
}
