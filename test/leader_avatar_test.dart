import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/widgets_custom_lotties/avatar_sprite.dart';
import 'package:budget_app/widgets_custom_lotties/leader_avatar.dart';

/// Everybody on a list of people has a face.
///
/// **The report:** *"I don't think you can see other profile pictures or
/// yours in like the most gold section and all other sections other than the
/// LP board."*
///
/// Three faults were producing that, which is why it looked inconsistent
/// rather than simply broken:
///
///  1. `_buildCachedLeaderboard` built every entry **without
///     `profileImageUrl`**, so every face vanished the moment the board fell
///     back to cache — no network, a timeout, an empty response. The two tabs
///     failed over at different moments, which is what made it read as "one
///     tab works".
///  2. The "Your saved progress" header had a **hardcoded person icon** and
///     was never passed an image, so a player saw their own photo on the
///     podium and a grey silhouette in their own header on the same screen.
///  3. Everywhere else fell back to the first letter of the username — and
///     most players have never uploaded a photo, so the board was a column of
///     initials in a font with 10 to 23 confusable capital pairs.
void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  group('what gets drawn', () {
    testWidgets('a photo wins when there is one', (tester) async {
      await tester.pumpWidget(
        host(
          const LeaderAvatar(
            size: 48,
            imageUrl: 'https://example.test/me.png',
            skinId: 'classic_turtle',
            username: 'Prince',
          ),
        ),
      );

      expect(find.byType(Image), findsWidgets);
      expect(find.text('P'), findsNothing);
    });

    testWidgets('no photo falls back to the equipped skin, not a letter', (
      tester,
    ) async {
      // The important one. A letter is the worst possible fallback here: an
      // isolated capital has no word around it, and this app's display face
      // cannot tell B, E, G and S apart. Everybody has a skin.
      await tester.pumpWidget(
        host(
          const LeaderAvatar(
            size: 48,
            skinId: 'classic_turtle',
            username: 'Prince',
          ),
        ),
      );

      expect(find.byType(AvatarSprite), findsOneWidget);
      expect(find.text('P'), findsNothing);
    });

    testWidgets('an unknown skin still falls back to the initial', (
      tester,
    ) async {
      // The last resort has to keep working: a row from an older client, or
      // a skin that was renamed, must not render an empty circle.
      await tester.pumpWidget(
        host(
          const LeaderAvatar(
            size: 48,
            skinId: 'not_a_real_skin',
            username: 'Prince',
          ),
        ),
      );

      expect(find.text('P'), findsOneWidget);
    });

    testWidgets('a nameless, skinless row is not blank', (tester) async {
      await tester.pumpWidget(host(const LeaderAvatar(size: 48)));
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('the initial is not set in the pixel face', (tester) async {
      // Pixelify's capitals measure 10-23 confusable pairs of 325 at every
      // size — see `caps_legibility_test.dart`. A monogram is the one place
      // there is no context to recover from that.
      await tester.pumpWidget(
        host(const LeaderAvatar(size: 48, username: 'Sam')),
      );

      final text = tester.widget<Text>(find.text('S'));
      expect(text.style?.fontFamily, isNot(contains('Pixelify')));
    });
  });

  group('the leaderboard uses it everywhere', () {
    String read(String path) =>
        File(path).readAsStringSync().replaceAll('\r\n', '\n');

    test('the board has no hand-rolled avatar left', () {
      final board = read(
        'lib/screens_minigames_admin_etc/Gameplay/dashboard/'
        'leaderboard_screen.dart',
      );

      // Three sites: the header, the podium, the rows.
      expect(
        'LeaderAvatar('.allMatches(board).length,
        greaterThanOrEqualTo(3),
        reason: 'a leaderboard surface is still drawing its own avatar',
      );
      expect(
        board.contains('Icon(Icons.person_rounded'),
        isFalse,
        reason: 'the header still has its hardcoded silhouette',
      );
    });

    test('the friends board knows which row is yours', () {
      // **This was hardcoded `isCurrentUser: false`** on the one board that
      // deliberately inserts you into itself — `friendIds.add(currentUserId)`
      // sits a few lines above it. So on the friends podium you appeared as a
      // stranger: no "(you)", no highlight, and no fall back to your own
      // locally stored photo, which is why your header showed your picture
      // and your podium entry showed a letter on the same screen.
      final service = read(
        'lib/services_backend_and_other_services/supabase_service.dart',
      );
      final start = service.indexOf('friendIds.add(currentUserId)');
      expect(start, greaterThan(-1));

      final body = service.substring(start, start + 2500);
      expect(
        body.contains('isCurrentUser: false'),
        isFalse,
        reason: 'your own row on your own friends board is not marked as you',
      );
      expect(body.contains("isCurrentUser: entry.value['id']"), isTrue);
    });

    test('both boards label your row', () {
      final board = read(
        'lib/screens_minigames_admin_etc/Gameplay/dashboard/'
        'leaderboard_screen.dart',
      );
      // The podium and the rows. A podium is three faces and three numbers,
      // and "where am I" is the question it exists to answer.
      expect(
        '(you)'.allMatches(board).length,
        greaterThanOrEqualTo(2),
        reason: 'the podium or the rows do not say which one is you',
      );
    });

    test('your own row can draw a face without the database', () {
      // `0005_leaderboard_profile.sql` has not been run against the live
      // database, so the view supplies no `equipped_skin`. Your own row does
      // not need it — the app already knows your skin.
      final board = read(
        'lib/screens_minigames_admin_etc/Gameplay/dashboard/'
        'leaderboard_screen.dart',
      );
      expect(board.contains('currentUserSkin'), isTrue);
    });

    test('the cached board carries the face', () {
      // The fault that made this look tab-specific. If these two fields are
      // ever dropped again, every avatar disappears the next time the query
      // times out — and nothing else about the screen changes, which is what
      // made it hard to see.
      final service = read(
        'lib/services_backend_and_other_services/supabase_service.dart',
      );
      // The *definition*, not the first call site — there are several calls
      // above it, and searching for the bare name lands on one of those.
      final start = service.indexOf('List<LeaderboardEntry> _buildCached');
      expect(start, greaterThan(-1));

      final body = service.substring(start, start + 2000);
      expect(
        body.contains('profileImageUrl: stats.profileImageUrl'),
        isTrue,
        reason: 'cached rows have no photo, so the board empties on fallback',
      );
      expect(
        body.contains('equippedSkin: stats.equippedSkin'),
        isTrue,
        reason: 'cached rows have no skin either, so there is no fallback',
      );
    });
  });
}
