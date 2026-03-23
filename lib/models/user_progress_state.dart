import 'package:flutter/foundation.dart';

/// App-wide gameplay economy state shared across dashboard, play, and profile.
class UserProgressState extends ChangeNotifier {
  UserProgressState._();

  static final UserProgressState instance = UserProgressState._();

  int _gold = 2450;
  int _xp = 850;
  int _literacyPoints = 850;
  int _level = 7;

  int get gold => _gold;
  int get xp => _xp;
  int get literacyPoints => _literacyPoints;
  int get level => _level;

  /// Placeholder until auth wiring is added.
  String get userId => 'user_123';

  String get levelTitle => 'Level $_level Finance Wizard';

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
    notifyListeners();
  }

  int _levelFromXp(int totalXp) {
    // Simple level curve: 150 XP per level.
    final computedLevel = (totalXp ~/ 150).clamp(1, 999);
    return computedLevel;
  }
}
