import 'package:flutter/foundation.dart';

class LedgerEntry {
  const LedgerEntry({
    required this.label,
    required this.amount,
    required this.meta,
    required this.isCredit,
  });

  final String label;
  final String amount;
  final String meta;
  final bool isCredit;
}

/// App-wide gameplay economy state shared across dashboard, play, and profile.
class UserProgressState extends ChangeNotifier {
  UserProgressState._();

  static final UserProgressState instance = UserProgressState._();

  int _gold = 2450;
  int _xp = 850;
  int _literacyPoints = 850;
  int _level = 7;
  String _personalityType = 'Spender';
  Map<String, dynamic> _spendingHabits = <String, dynamic>{
    'risk_tolerance': 'balanced',
    'impulse_spend_score': 0.62,
    'missed_questions': <String>[],
  };
  final List<LedgerEntry> _ledgerEntries = <LedgerEntry>[
    const LedgerEntry(
      label: 'Daily Challenge Reward',
      amount: '+120 gold',
      meta: '2 mins ago',
      isCredit: true,
    ),
    const LedgerEntry(
      label: 'Library Lesson Unlock',
      amount: '-40 gold',
      meta: 'Yesterday',
      isCredit: false,
    ),
    const LedgerEntry(
      label: 'Boss Battle Bonus',
      amount: '+200 gold',
      meta: 'Yesterday',
      isCredit: true,
    ),
    const LedgerEntry(
      label: 'Market Mistake Recovery',
      amount: '-15 gold',
      meta: '2 days ago',
      isCredit: false,
    ),
  ];
  bool _isCloudSyncing = false;
  String? _cloudStatusMessage;

  int get gold => _gold;
  int get xp => _xp;
  int get literacyPoints => _literacyPoints;
  int get level => _level;
  String get personalityType => _personalityType;
  Map<String, dynamic> get spendingHabits => Map.unmodifiable(_spendingHabits);
  List<LedgerEntry> get ledgerEntries => List.unmodifiable(_ledgerEntries);
  bool get isCloudSyncing => _isCloudSyncing;
  String? get cloudStatusMessage => _cloudStatusMessage;

  /// Placeholder until auth wiring is added.
  String get userId => 'user_123';

  String get levelTitle => 'Level $_level Finance Wizard';

  String get wizardAdvice {
    switch (_personalityType.toLowerCase()) {
      case 'spender':
      case 'the spender':
      case 'impulse spender':
      case 'the impulse spender':
        return 'The market is volatile today, maybe save your gold?';
      case 'risk-taker':
      case 'the risk-taker':
        return 'Risk can build momentum, but keep a safety pouch before the next boss battle.';
      case 'saver':
      case 'the saver':
        return 'Your discipline is strong. Consider moving a little extra gold into growth this week.';
      default:
        return 'You are building smart habits. Keep balancing saving, learning, and challenge rewards.';
    }
  }

  /// Adds rewards returned from React minigames and recomputes level from XP.
  void applyGameRewards({
    required int goldEarned,
    required int xpEarned,
    required int literacyPointsEarned,
  }) {
    _gold += goldEarned;
    _xp += xpEarned;
    _literacyPoints += literacyPointsEarned;
    _level = _levelFromXp(_xp);
    if (goldEarned != 0) {
      _ledgerEntries.insert(
        0,
        LedgerEntry(
          label: 'React Challenge Reward',
          amount: '${goldEarned >= 0 ? '+' : ''}$goldEarned gold',
          meta: 'Just now',
          isCredit: goldEarned >= 0,
        ),
      );
    }
    notifyListeners();
  }

  void applyRemoteProgress({
    required int gold,
    required int xp,
    required int literacyScore,
    String? personalityType,
    Map<String, dynamic>? spendingHabits,
  }) {
    _gold = gold;
    _xp = xp;
    _literacyPoints = literacyScore;
    _level = _levelFromXp(_xp);

    if (personalityType != null && personalityType.trim().isNotEmpty) {
      _personalityType = personalityType.trim();
    }

    if (spendingHabits != null && spendingHabits.isNotEmpty) {
      _spendingHabits = Map<String, dynamic>.from(spendingHabits);
    }

    notifyListeners();
  }

  void setCloudSyncState({
    required bool isSyncing,
    String? message,
  }) {
    _isCloudSyncing = isSyncing;
    _cloudStatusMessage = message;
    notifyListeners();
  }

  int _levelFromXp(int totalXp) {
    // Simple level curve: 150 XP per level.
    final computedLevel = (totalXp ~/ 150).clamp(1, 999) as int;
    return computedLevel;
  }
}
