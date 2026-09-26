import 'dart:convert';

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// Guest mode's actual load-bearing pieces: that local-only progress
/// survives a restart (it did not, before this), that choosing to be a
/// guest is a durable, per-device choice, and that a guest converting to a
/// real account keeps what they built rather than starting over.
///
/// `SupabaseService.instance` is a real singleton with no test double, so
/// every test here stays entirely on its local-only path -- `initialize()`
/// is never called, so `isSupabaseConnected` is false throughout, exactly
/// like `account_deletion_test.dart` already relies on.
void main() {
  const cacheKeyPrefix = 'budget_buddy_user_stats_';
  const guestModeKey = 'budget_buddy_local_guest_mode';

  late SharedPreferences prefs;

  setUpAll(() async {
    // `SupabaseService.instance` is a real singleton that caches its
    // `SharedPreferences` reference the first time anything touches it and
    // never refreshes it (see `_ensurePreferences`). Calling the *static*
    // `SharedPreferences.setMockInitialValues` again from a per-test
    // `setUp` -- which swaps out the platform-level backing store for
    // whichever `getInstance()` call comes next -- would silently stop
    // reaching that already-cached reference. Reset the mock store once,
    // up front, before anything caches it, then reuse this exact instance
    // for every test.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  setUp(() async {
    await prefs.clear();
  });

  tearDown(() async {
    // `SupabaseService.instance` outlives any one test, so its guest flag
    // has to be put back or it leaks into whichever test runs next.
    await SupabaseService.instance.setLocalGuestMode(false);
  });

  test('a brand-new device with nothing cached still gets the starter profile', () async {
    final controller = UserStatsController(service: SupabaseService.instance);
    await controller.initialize();

    expect(controller.stats.gold, 2000);
    expect(controller.stats.xp, 850);
  });

  test('local-only progress survives a restart instead of resetting', () async {
    await prefs.setString(
      '$cacheKeyPrefix' 'user_123',
      jsonEncode(
        UserStats.defaults('user_123').copyWith(gold: 4321, xp: 77).toStorageMap(),
      ),
    );

    final controller = UserStatsController(service: SupabaseService.instance);
    await controller.initialize();

    expect(
      controller.stats.gold,
      4321,
      reason: 'a cold start used to always overwrite this with the canned '
          '2000/850 starter profile, even when real progress was cached',
    );
    expect(controller.stats.xp, 77);
  });

  test('continueAsGuest persists across a fresh read of preferences', () async {
    final controller = UserStatsController(service: SupabaseService.instance);
    await controller.initialize();

    expect(controller.isGuest, isFalse);
    await controller.continueAsGuest();
    expect(controller.isGuest, isTrue);

    expect(prefs.getBool(guestModeKey), isTrue);
  });

  test('eraseGuestDataAndRestart clears the cache and the guest flag', () async {
    final controller = UserStatsController(service: SupabaseService.instance);
    await controller.initialize();
    await controller.continueAsGuest();

    await controller.updateOnboardingProfile(
      personalityType: 'Saver',
      spendingHabits: const <String, dynamic>{},
    );
    expect(controller.stats.personalityType, 'Saver');

    await controller.eraseGuestDataAndRestart();

    expect(controller.isGuest, isFalse);
    expect(controller.stats.gold, 2000, reason: 'back to the starter profile');

    expect(prefs.getBool(guestModeKey), isFalse);
    expect(prefs.getString('$cacheKeyPrefix' 'user_123'), isNull);
  });

  test(
    'migrateGuestStatsToUser carries the guest\'s progress onto the real id',
    () async {
      final guestStats = UserStats.defaults('user_123').copyWith(
        gold: 9999,
        xp: 42,
      );
      const fakeUser = User(
        id: '11111111-2222-3333-4444-555555555555',
        appMetadata: <String, dynamic>{},
        userMetadata: <String, dynamic>{'username': 'RealPlayer'},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        email: 'player@example.com',
      );

      final provisioned = await SupabaseService.instance.migrateGuestStatsToUser(
        guestStats: guestStats,
        user: fakeUser,
      );

      expect(provisioned.stats.id, fakeUser.id);
      expect(provisioned.stats.gold, 9999);
      expect(provisioned.stats.xp, 42);
      expect(provisioned.stats.username, 'RealPlayer');
      expect(
        provisioned.createdProfile,
        isFalse,
        reason: 'this is a migration of existing data, not a fresh profile',
      );
    },
  );
}
