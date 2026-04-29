import 'dart:math';

import 'package:flutter/foundation.dart';

import 'user_stats_controller.dart';

@immutable
class CombatQuestion {
  const CombatQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

class AdventureStateController extends ChangeNotifier {
  final Random _random = Random();
  UserStatsController? _userStatsController;

  int _level = 1;
  int _xp = 0;
  int _gold = 0;
  int _literacyPoints = 0;
  int _health = 100;
  final int _maxHealth = 100;
  String _equippedPet = 'Emerald Turtle';
  bool _combatVisible = false;
  bool _answerResolved = false;
  String _encounterEnemyName = '';
  String _currentDistrict = 'Starter Village';
  String _sessionFocus =
      'Warm up in the academy and scout your first encounter.';
  String? _combatFeedback;
  CombatQuestion? _currentQuestion;
  int _encountersWon = 0;
  int _streakDays = 1;

  int get level => _level;
  int get xp => _xp;
  int get gold => _gold;
  int get literacyPoints => _literacyPoints;
  int get health => _health;
  int get maxHealth => _maxHealth;
  String get equippedPet => _equippedPet;
  bool get combatVisible => _combatVisible;
  bool get answerResolved => _answerResolved;
  String get encounterEnemyName => _encounterEnemyName;
  String get currentDistrict => _currentDistrict;
  String get sessionFocus => _sessionFocus;
  int get encountersWon => _encountersWon;
  int get streakDays => _streakDays;
  String? get combatFeedback => _combatFeedback;
  CombatQuestion? get currentQuestion => _currentQuestion;

  double get xpProgress => (_xp % 120) / 120;
  int get chapter => ((_level - 1) ~/ 3) + 1;
  double get chapterProgress => ((_xp % 360) / 360).clamp(0.0, 1.0);
  int get readinessScore =>
      ((_health * 0.55) + (xpProgress * 100 * 0.30) + (_streakDays * 3))
          .round()
          .clamp(0, 100);

  String get readinessLabel {
    if (readinessScore >= 80) {
      return 'Mission Ready';
    }
    if (readinessScore >= 55) {
      return 'Steady Momentum';
    }
    return 'Recovery Mode';
  }

  List<String> get sessionObjectives => <String>[
    'Finish one academy lesson to grow your mastery path.',
    combatVisible
        ? 'Resolve the current encounter with $_encounterEnemyName.'
        : 'Scout a fresh encounter in $currentDistrict.',
    'Keep your streak alive with one strong decision today.',
  ];

  void attachUserStats(UserStatsController controller) {
    _userStatsController = controller;
    final stats = controller.stats;
    final nextLevel = stats.level;
    final nextXp = stats.xp;
    final nextGold = stats.gold;
    final nextLiteracy = stats.literacyPoints;
    final nextPet = _derivePetName(stats.equippedSkin);
    final nextDistrict = _districts[(nextLevel - 1) % _districts.length];
    final nextFocus = _buildSessionFocus(nextLevel, stats.literacyPoints);

    final changed =
        nextLevel != _level ||
        nextXp != _xp ||
        nextGold != _gold ||
        nextLiteracy != _literacyPoints ||
        nextPet != _equippedPet ||
        nextDistrict != _currentDistrict ||
        nextFocus != _sessionFocus;

    _level = nextLevel;
    _xp = nextXp;
    _gold = nextGold;
    _literacyPoints = nextLiteracy;
    _equippedPet = nextPet;
    _currentDistrict = nextDistrict;
    _sessionFocus = nextFocus;

    if (changed) {
      notifyListeners();
    }
  }

  void scoutEncounter() {
    if (_combatVisible) {
      return;
    }
    _currentDistrict =
        _districts[(_encountersWon + _level) % _districts.length];
    beginEncounter(
      _enemyNames[(_encountersWon + _level + _random.nextInt(3)) %
          _enemyNames.length],
    );
  }

  void recoverHealth() {
    final nextHealth = min(_maxHealth, _health + 18);
    if (nextHealth == _health) {
      return;
    }
    _health = nextHealth;
    _sessionFocus = 'Recovered some health. You are ready for the next run.';
    notifyListeners();
  }

  void beginEncounter(String enemyName) {
    if (_combatVisible) {
      return;
    }
    _encounterEnemyName = enemyName;
    _currentQuestion =
        _questionBank[enemyName.hashCode.abs() % _questionBank.length];
    _combatVisible = true;
    _answerResolved = false;
    _combatFeedback = null;
    _sessionFocus =
        'Encounter active in $_currentDistrict. Jump into the field.';
    notifyListeners();
  }

  void cancelEncounter() {
    _combatVisible = false;
    _answerResolved = false;
    _combatFeedback = null;
    _currentQuestion = null;
    _encounterEnemyName = '';
    _sessionFocus =
        'Encounter cancelled. Regroup and choose your next objective.';
    notifyListeners();
  }

  Future<bool> submitAnswer(int optionIndex) async {
    final question = _currentQuestion;
    if (question == null) {
      return false;
    }

    final correct = optionIndex == question.correctIndex;
    if (correct) {
      _answerResolved = true;
      _combatFeedback = question.explanation;
      _encountersWon += 1;
      _streakDays = min(30, _streakDays + 1);
      _sessionFocus =
          'Great win. Keep the momentum going with another lesson or run.';
      notifyListeners();

      final userStatsController = _userStatsController;
      if (userStatsController != null) {
        await userStatsController.applyChallengePayload(<String, dynamic>{
          'title': 'Field Encounter Victory',
          'description':
              'Defeated $_encounterEnemyName in $_currentDistrict using a strong financial literacy answer.',
          'gold': 35,
          'xp': 28,
          'literacy_points': 12,
        });
        attachUserStats(userStatsController);
      } else {
        _gold += 35;
        _xp += 28;
        _literacyPoints += 12;
        _level = max(1, _xp ~/ 120);
      }
      notifyListeners();
      return true;
    }

    _health = max(0, _health - 8);
    _combatFeedback = 'Not quite. ${question.explanation}';
    _sessionFocus = 'Take a breather, then try the encounter again.';
    notifyListeners();
    return false;
  }

  void restoreMovementAfterCombat() {
    _combatVisible = false;
    _answerResolved = false;
    _combatFeedback = null;
    _currentQuestion = null;
    _encounterEnemyName = '';
    _sessionFocus = 'The path is clear. Explore more of $_currentDistrict.';
    notifyListeners();
  }

  String _buildSessionFocus(int nextLevel, int literacyPoints) {
    if (_combatVisible) {
      return 'Encounter active in $_currentDistrict. Jump into the field.';
    }
    if (literacyPoints < 900) {
      return 'Build your foundation in the academy before pushing deeper into the world.';
    }
    if (nextLevel < 4) {
      return 'Keep stacking easy wins. A few short sessions will unlock the next district.';
    }
    return 'Mix lessons and encounters to keep your rewards and mastery climbing together.';
  }

  String _derivePetName(String equippedSkin) {
    switch (equippedSkin) {
      case 'coin_shell':
        return 'Coin Shell Turtle';
      case 'emerald_strider':
        return 'Emerald Strider';
      case 'guild_runner':
        return 'Guild Runner';
      case 'cyber_turtle':
        return 'Cyber Turtle';
      case 'piggy_bank_turtle':
        return 'Piggy Bank Turtle';
      case 'explorer_turtle':
        return 'Explorer Turtle';
      case 'starlight_turtle':
        return 'Starlight Turtle';
      case 'canopy_guardian':
        return 'Canopy Guardian';
      case 'shell_sprinter':
        return 'Shell Sprinter';
      case 'trailblazer':
        return 'Trailblazer';
      case 'ancient_giant':
        return 'Ancient Giant';
      case 'field_captain':
        return 'Field Captain';
      default:
        return 'Emerald Turtle';
    }
  }
}

const List<String> _districts = <String>[
  'Starter Village',
  'Market Square',
  'Savings Grove',
  'Credit Cliffs',
  'Investor Ridge',
];

const List<String> _enemyNames = <String>[
  'Impulse Goblin',
  'Fee Phantom',
  'Debt Drake',
  'Budget Bandit',
  'Late Bill Beast',
];

const List<CombatQuestion> _questionBank = <CombatQuestion>[
  CombatQuestion(
    prompt:
        'You earn \$20 and save \$5. What percent of your money did you save?',
    options: <String>['10%', '25%', '40%', '50%'],
    correctIndex: 1,
    explanation: 'Saving \$5 out of \$20 is 5 ÷ 20 = 25%.',
  ),
  CombatQuestion(
    prompt: 'Which choice is usually the best first step for avoiding debt?',
    options: <String>[
      'Ignore bills until later',
      'Track spending with a budget',
      'Open more credit cards',
      'Only pay the minimum forever',
    ],
    correctIndex: 1,
    explanation:
        'A clear budget helps you avoid overspending before debt builds up.',
  ),
  CombatQuestion(
    prompt:
        'If an item costs \$12 and you have a \$15 budget, how much money is left?',
    options: <String>['\$1', '\$2', '\$3', '\$4'],
    correctIndex: 2,
    explanation: '\$15 - \$12 = \$3 left in the budget.',
  ),
];
