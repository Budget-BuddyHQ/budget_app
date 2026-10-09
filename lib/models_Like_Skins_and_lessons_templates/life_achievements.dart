import 'package:flutter/material.dart';

import 'life_record.dart';

/// Things a single life can achieve, beyond which ending it reached.
///
/// The app is described as having "endings and different achievements that
/// [players] can obtain from playing" Life. The endings were real (seven of
/// them, collected on Profile), but the only achievements were three badges
/// for *counting* endings. These are earned by how a life actually went —
/// out of debt, a home of your own, a budget that saved — which is the thing
/// the game is teaching, so they reward the lesson rather than the grind.
///
/// Each is read off the [LifeRecord] filed when a life ends, and saved once
/// earned (`UserStats.lifeAchievements`), because the record book only keeps
/// the latest twenty lives and an achievement should not expire with them.
enum LifeAchievement {
  debtFree(
    'Debt Free',
    'Finish a life at 60 or older owing nothing',
    Icons.money_off_rounded,
    Color(0xFF9BE870),
  ),
  homeowner(
    'Homeowner',
    'End a life owning your home',
    Icons.house_rounded,
    Color(0xFF58C7FF),
  ),
  sixFigures(
    'Six Figures',
    'Finish a life worth 100,000 or more',
    Icons.savings_rounded,
    Color(0xFFFFC800),
  ),
  budgetBoss(
    'Budget Boss',
    'Set your own budget and save at least 20%',
    Icons.pie_chart_rounded,
    Color(0xFF6CD34A),
  ),
  climber(
    'Climber',
    'Earn 3 promotions in one life',
    Icons.trending_up_rounded,
    Color(0xFFFF8A5B),
  ),
  familyLife(
    'Family Life',
    'Have a partner and a child',
    Icons.family_restroom_rounded,
    Color(0xFFFF8FB1),
  ),
  goldenYears(
    'Golden Years',
    'Live to 85',
    Icons.elderly_rounded,
    Color(0xFFE1BB72),
  );

  const LifeAchievement(this.label, this.detail, this.icon, this.color);

  final String label;
  final String detail;
  final IconData icon;
  final Color color;

  /// Whether [record] earned this. Records filed before the details were
  /// saved have no detail or facts, and earn nothing that needs them.
  bool earnedBy(LifeRecord record) {
    final detail = record.detail;
    final facts = record.facts;
    return switch (this) {
      LifeAchievement.debtFree =>
        record.age >= 60 &&
            detail != null &&
            detail.loansOwed == 0 &&
            (facts?.debt ?? 0) == 0,
      LifeAchievement.homeowner => detail?.ownedHome ?? false,
      LifeAchievement.sixFigures => record.netWorth >= 100000,
      LifeAchievement.budgetBoss =>
        facts != null && facts.budgetSet && facts.savingsPct >= 20,
      LifeAchievement.climber => (detail?.promotions ?? 0) >= 3,
      LifeAchievement.familyLife =>
        detail != null && detail.hadPartner && detail.children >= 1,
      LifeAchievement.goldenYears => record.age >= 85,
    };
  }
}
