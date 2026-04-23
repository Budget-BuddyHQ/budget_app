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
  String? _combatFeedback;
  CombatQuestion? _currentQuestion;

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
  String? get combatFeedback => _combatFeedback;
  CombatQuestion? get currentQuestion => _currentQuestion;

  double get xpProgress => (_xp % 120) / 120;

  void attachUserStats(UserStatsController controller) {
    _userStatsController = controller;
    final stats = controller.stats;
    final nextLevel = stats.level;
    final nextXp = stats.xp;
    final nextGold = stats.gold;
    final nextLiteracy = stats.literacyPoints;
    final nextPet = _derivePetName(stats.equippedSkin);

    final changed = nextLevel != _level ||
        nextXp != _xp ||
        nextGold != _gold ||
        nextLiteracy != _literacyPoints ||
        nextPet != _equippedPet;

    _level = nextLevel;
    _xp = nextXp;
    _gold = nextGold;
    _literacyPoints = nextLiteracy;
    _equippedPet = nextPet;

    if (changed) {
      notifyListeners();
    }
  }

  void beginEncounter(String enemyName) {
    if (_combatVisible) {
      return;
    }
    _encounterEnemyName = enemyName;
    _currentQuestion = _questionBank[enemyName.hashCode.abs() % _questionBank.length];
    _combatVisible = true;
    _answerResolved = false;
    _combatFeedback = null;
    notifyListeners();
  }

  void cancelEncounter() {
    _combatVisible = false;
    _answerResolved = false;
    _combatFeedback = null;
    _currentQuestion = null;
    _encounterEnemyName = '';
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
      notifyListeners();

      final userStatsController = _userStatsController;
      if (userStatsController != null) {
        await userStatsController.applyChallengePayload(
          <String, dynamic>{
            'title': 'Field Encounter Victory',
            'description':
                'Defeated $_encounterEnemyName using a financial literacy answer.',
            'gold': 35,
            'xp': 28,
            'literacy_points': 12,
          },
        );
        attachUserStats(userStatsController);
      } else {
        _gold += 35;
        _xp += 28;
        _literacyPoints += 12;
        _level = ((_xp ~/ 120).clamp(1, 9999) as num).toInt();
      }
      notifyListeners();
      return true;
    }

    _health = ((_health - 8).clamp(0, _maxHealth) as num).toInt();
    _combatFeedback = 'Not quite. ${question.explanation}';
    notifyListeners();
    return false;
  }

  void restoreMovementAfterCombat() {
    _combatVisible = false;
    _answerResolved = false;
    _combatFeedback = null;
    _currentQuestion = null;
    _encounterEnemyName = '';
    notifyListeners();
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

const List<CombatQuestion> _questionBank = <CombatQuestion>[
  CombatQuestion(
    prompt: 'You earn \$20 and save \$5. What percent of your money did you save?',
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
    explanation: 'A clear budget helps you avoid overspending before debt builds up.',
  ),
  CombatQuestion(
    prompt: 'If an item costs \$12 and you have a \$15 budget, how much money is left?',
    options: <String>['\$1', '\$2', '\$3', '\$4'],
    correctIndex: 2,
    explanation: '\$15 - \$12 = \$3 left in the budget.',
  ),
];
