/// What fixing a Coach suggestion pays.
///
/// **Asked for as:** *"when the coach gives suggestions and then they fix the
/// suggestion, give them a lot of incentives."* So every suggestion says what
/// it is worth before it is fixed, fixing it pays gold and XP with a
/// celebration, and ten fixes unlock a mythic skin.
///
/// **Why there is a cooldown.** A weak topic is made by getting a question
/// wrong, which anybody can do on purpose. Without a limit, missing a
/// question and then answering it right would be a gold tap, the same
/// "infinite coins" loop the lessons had. So each thing pays at most once
/// every [cooldown], and that is recorded on the account, not the device.
class CoachRewards {
  CoachRewards._();

  /// A finding card the Coach stops flagging.
  static const int findingGold = 120;
  static const int findingXp = 40;
  static const ({int gold, int xp}) finding = (
    gold: findingGold,
    xp: findingXp,
  );

  /// A weak quiz topic answered right again. Smaller, because it is the one
  /// a player can create themselves.
  static const int skillGold = 40;
  static const int skillXp = 15;
  static const ({int gold, int xp}) skill = (gold: skillGold, xp: skillXp);

  /// How long before the same thing can pay again.
  static const Duration cooldown = Duration(days: 30);

  /// Fixes needed for [skinId].
  static const int skinMilestone = 10;

  /// The mythic "Golden" Buddy, unlocked free at [skinMilestone].
  static const String skinId = 'buddy_golden';

  /// What fixing the Coach item [id] pays (ids are `skill:...` for weak
  /// topics, anything else for findings).
  static ({int gold, int xp}) forId(String id) =>
      id.startsWith('skill:') ? skill : finding;

  /// Whether [id] can pay now, given when each item last paid.
  static bool canPay(String id, Map<String, DateTime> lastPaid, DateTime now) {
    final last = lastPaid[id];
    return last == null || now.difference(last) >= cooldown;
  }
}

/// What claiming a batch of fixes paid.
class CoachClaim {
  const CoachClaim({
    required this.gold,
    required this.xp,
    required this.paidCount,
    required this.totalFixes,
    this.unlockedSkinId,
  });

  final int gold;
  final int xp;

  /// How many of the fixes paid (others were inside the cooldown).
  final int paidCount;

  /// Every fix ever rewarded, this one included.
  final int totalFixes;

  /// Set when this claim reached the skin milestone.
  final String? unlockedSkinId;

  bool get paidAnything => paidCount > 0;
}
