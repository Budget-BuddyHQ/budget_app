part of 'life_sim_controller.dart';

/// What to do with a year, in the controller. See `life_activities.dart` for
/// the catalogue.
extension LifeSimActivities on LifeSimController {
  int activityUses(String id) => _activityUses[id] ?? 0;

  double _activityYield(ActivityDef def) {
    final used = activityUses(def.id);
    return used >= def.tiers.length ? 0.0 : def.tiers[used];
  }

  int activityLeft(ActivityDef def) =>
      (def.tiers.length - activityUses(def.id)).clamp(0, def.tiers.length);

  /// The line under an activity: what is left of its yearly limit.
  String? activityNote(ActivityDef def) {
    final left = activityLeft(def);
    if (left == 0) return 'Done for this year';
    final noun = left == 1 ? 'use' : 'uses';
    final next = _activityYield(def);
    if (def.tiers.length == 1) return null;
    if (next >= 1.0) return '$left $noun left this year';
    return '$left $noun left · pays ${(next * 100).round()}% now';
  }

  /// Why [def] cannot be done right now, or null.
  ///
  /// Cost only stops an adult. A child's family pays for a day out, and it is
  /// the family's money and not the child's, which is how it works. Anything
  /// that earns money is different: the stake is the player's own.
  String? activityGate(ActivityDef def) {
    if (finished) return 'This life is over';
    if (_age < def.minAge) return 'You need to be ${def.minAge}';
    if (activityLeft(def) == 0) return 'Done for this year';
    final pays = def.cost > 0 && (!isDependent || def.earns);
    if (pays && _money < def.cost) return 'Costs ${def.cost} coins';
    if (def.partnerChance > 0 && hasPartner) {
      return 'You are already with someone';
    }
    if (def.meetsFriend &&
        _people
                .where((p) => p.kind == RelationshipKind.friend && p.isAlive)
                .length >=
            12) {
      return 'You know plenty of people already';
    }
    return null;
  }

  int _byRate(int amount, double rate) {
    if (amount == 0) return 0;
    if (amount < 0) return amount;
    return max(1, (amount * rate).round());
  }

  /// Does [id]. Returns whether it happened.
  bool doActivity(String id) {
    final def = activityById(id);
    if (def == null || activityGate(def) != null) return false;
    final rate = _activityYield(def);
    _activityUses[id] = activityUses(id) + 1;

    final pays = def.cost > 0 && (!isDependent || def.earns);
    if (pays) _applyEventMoney(-def.cost);

    final joy = _byRate(def.happiness, rate);
    final well = _byRate(def.health, rate);
    final wit = _byRate(def.smarts, rate);
    final look = _byRate(def.looks, rate);
    _happiness = _clamp(_happiness + joy);
    _health = _clamp(_health + well);
    _smarts = _clamp(_smarts + wit);
    _looks = _clamp(_looks + look);
    final skill = def.skill;
    if (skill != null && def.skillGain != 0) {
      _skills[skill] = ((_skills[skill] ?? 0) + _byRate(def.skillGain, rate))
          .clamp(0, 100);
    }

    if (def.friendsBoost > 0) {
      final boost = _byRate(def.friendsBoost, rate);
      for (var i = 0; i < _people.length; i++) {
        final p = _people[i];
        if (p.kind == RelationshipKind.friend && p.isAlive) {
          _people[i] = p.copyWith(
            closeness: (p.closeness + boost).clamp(0, 100),
            lastSeenAge: _age,
          );
        }
      }
    }

    final bits = <String>[
      if (joy != 0) '${joy > 0 ? '+' : ''}$joy Happiness',
      if (well != 0) '${well > 0 ? '+' : ''}$well Health',
      if (wit != 0) '${wit > 0 ? '+' : ''}$wit Smarts',
      if (look != 0) '${look > 0 ? '+' : ''}$look Looks',
    ];

    var extra = '';
    if (def.earns) {
      final span = def.earnsMax - def.earnsMin;
      final made = def.earnsMin + (span <= 0 ? 0 : _random.nextInt(span + 1));
      final net = made - (def.cost > 0 ? 0 : 0);
      if (net >= 0) {
        _money += net;
        extra = ' It brought in $net.';
      } else {
        _applyEventMoney(net);
        extra = ' It lost ${-net}. Some days do.';
      }
    }

    _setLog(
      '${def.outcome}${bits.isEmpty ? '' : ' ${bits.join(', ')}.'}$extra'
      '${pays ? ' -${def.cost} coins.' : ''}',
      kind: def.category == ActivityCategory.learning
          ? LifeLogKind.learning
          : def.category == ActivityCategory.mindBody
          ? LifeLogKind.health
          : def.category == ActivityCategory.money
          ? LifeLogKind.money
          : def.category == ActivityCategory.social ||
                def.category == ActivityCategory.love
          ? LifeLogKind.people
          : LifeLogKind.life,
    );

    if (def.meetsFriend && _random.nextInt(100) < (70 * rate).round()) {
      _meetFriend();
    }
    if (def.partnerChance > 0) {
      if (!_maybeMeetPartner((def.partnerChance * rate).round())) {
        _setLog(
          'Nothing came of it this time, which is how it usually goes.',
          kind: LifeLogKind.people,
        );
      }
    }
    final lesson = def.teaches;
    if (lesson != null) _teach(lesson);
    _changed();
    return true;
  }

  // ---- Test seams -------------------------------------------------------------------

  /// Test seam: put the player on a team at a given standing.
  @visibleForTesting
  void debugSetSport(LifeSport? sport, {int standing = 50}) {
    _sport = sport;
    _sportStanding = sport == null ? 0 : standing.clamp(0, 100);
    _changed();
  }

  /// Test seam: set a skill level.
  @visibleForTesting
  void debugSetSkill(LifeSkill skill, int value) {
    _skills[skill] = value.clamp(0, 100);
  }

  // ---- Sport -----------------------------------------------------------------------

  LifeSport? get sport => _sport;

  /// How the player is doing on the team, 0 to 100. The bar on the sport card.
  int get sportStanding => _sportStanding;
  int get seasonsPlayed => _seasons;

  /// Whether the player is a professional athlete.
  bool get isProAthlete => _jobId != null && _jobId!.startsWith('pro_sport');

  int get sportSkill => _skills[LifeSkill.sports] ?? 0;

  int tryoutOdds() => tryoutChance(skill: sportSkill, health: _health);

  String? tryoutGate(LifeSport sport) {
    if (finished) return 'This life is over';
    if (_age < 9) return 'You need to be 9';
    if (_sport != null) return 'You are already on a team';
    if (activityUses('tryout') >= 2) return 'Done for this year';
    return null;
  }

  bool tryOut(LifeSport sport) {
    if (tryoutGate(sport) != null) return false;
    _activityUses['tryout'] = activityUses('tryout') + 1;
    if (_random.nextInt(100) < tryoutOdds()) {
      _sport = sport;
      _sportStanding = (45 + sportSkill / 4).round().clamp(0, 100);
      _seasons = 0;
      _happiness = _clamp(_happiness + 6);
      _setLog(
        'You made the ${sport.label.toLowerCase()} team. Training and seasons '
        'are what move you up it.',
        kind: LifeLogKind.life,
      );
      _meetFriend(role: 'Teammate');
    } else {
      _happiness = _clamp(_happiness - 3);
      _setLog(
        'You tried out for ${sport.label.toLowerCase()} and did not make the '
        'team. Practice changes those odds.',
        kind: LifeLogKind.life,
      );
    }
    _changed();
    return true;
  }

  bool leaveTeam() {
    if (_sport == null || finished) return false;
    final left = _sport!;
    _sport = null;
    _sportStanding = 0;
    _setLog(
      'You left the ${left.label.toLowerCase()} team.',
      kind: LifeLogKind.life,
    );
    _changed();
    return true;
  }

  String? trainGate() {
    if (finished) return 'This life is over';
    if (_sport == null) return 'Join a team first';
    if (activityUses('train') >= 3) return 'Done for this year';
    return null;
  }

  bool trainWithTeam() {
    if (trainGate() != null) return false;
    final rate = const <double>[1.0, 0.5, 0.25][activityUses('train')];
    _activityUses['train'] = activityUses('train') + 1;
    final gain = _byRate(6, rate);
    _sportStanding = (_sportStanding + gain).clamp(0, 100);
    _skills[LifeSkill.sports] =
        ((_skills[LifeSkill.sports] ?? 0) + _byRate(3, rate)).clamp(0, 100);
    _health = _clamp(_health + _byRate(2, rate));
    _happiness = _clamp(_happiness + 1);
    _setLog(
      'You trained with the team. Standing +$gain.',
      kind: LifeLogKind.health,
    );
    _changed();
    return true;
  }

  /// A season, once a year, for anybody on a team.
  void _playSeason(int trained) {
    final s = _sport;
    if (s == null) return;
    _seasons++;
    _sportStanding = nextStanding(
      standing: _sportStanding,
      skill: sportSkill,
      health: _health,
      trainingUses: trained,
      luck: _random.nextInt(9) - 4,
    );
    _skills[LifeSkill.sports] = ((_skills[LifeSkill.sports] ?? 0) + 2).clamp(
      0,
      100,
    );
    _health = _clamp(_health + 2);
    _happiness = _clamp(_happiness + 3);
    final hurt = _random.nextInt(100) < 8;
    if (hurt) {
      _health = _clamp(_health - 8);
      _happiness = _clamp(_happiness - 3);
    }
    // Speaks every second season, and whenever something happened, so a long
    // career on a team does not read as the same line printed forty times.
    if (_seasons.isEven || hurt || _sportStanding >= 88) {
      _setLog(
        hurt
            ? 'A ${s.label.toLowerCase()} injury kept you out for part of the '
                  'season. It healed, and it is a reminder to look after '
                  'yourself.'
            : 'The ${s.label.toLowerCase()} season was ${seasonSummary(s, _sportStanding)}.',
        kind: LifeLogKind.life,
      );
    }
    if (_age >= 45) {
      _sport = null;
      _sportStanding = 0;
      _setLog(
        'You hung up your ${s.label.toLowerCase()} boots after a good run.',
        kind: LifeLogKind.life,
      );
    }
  }

  // ---- Paths that are not on the job board ---------------------------------------------

  String? proTryoutGate() {
    if (finished) return 'This life is over';
    if (_sport == null) return 'Join a team first';
    if (isProAthlete) return 'You are already a professional';
    if (_age < 18) return 'You need to be 18';
    if (_age > 32) return 'The professional ranks want somebody younger';
    if (_sportStanding < 85) return 'Your standing needs to reach 85';
    if (activityUses('pro_tryout') >= 1) return 'Done for this year';
    return null;
  }

  int get proTryoutChance => (35 + (_sportStanding - 85) * 3).clamp(10, 75);

  bool tryOutForPros() {
    if (proTryoutGate() != null) return false;
    _activityUses['pro_tryout'] = 1;
    final job = jobById('pro_sport_0')!;
    if (_random.nextInt(100) < proTryoutChance) {
      _hire(job);
      _job = 'Professional ${_sport!.label} Player';
      _happiness = _clamp(_happiness + 10);
      _setLog(
        'You signed a professional contract in ${_sport!.label.toLowerCase()}. '
        'Careers in sport are short, so the money you save now matters.',
        kind: LifeLogKind.career,
      );
      _teach(FinanceConcept.incomeVsWealth);
    } else {
      _happiness = _clamp(_happiness - 5);
      _setLog(
        'The scouts liked you and did not sign you. Another year of training '
        'and you can try again.',
        kind: LifeLogKind.career,
      );
    }
    _changed();
    return true;
  }

  String? officeGate() {
    if (finished) return 'This life is over';
    if (_age < 25) return 'You need to be 25';
    if (_jobId != null && _jobId!.startsWith('politics')) {
      return 'You already hold office';
    }
    if (!_edu.level.atLeast(EducationLevel.secondary)) {
      return 'You need a high school diploma';
    }
    if ((_skills[LifeSkill.charisma] ?? 0) < 25) {
      return 'You need more Charisma. Drama and debate build it';
    }
    if (activityUses('election') >= 1) return 'Done for this year';
    if (_money < 100) return 'A campaign costs 100 coins';
    return null;
  }

  int get electionChance {
    final charisma = (_skills[LifeSkill.charisma] ?? 0) / 2;
    return (20 + charisma + networkReading.strength / 4 + _fame / 3)
        .round()
        .clamp(10, 80);
  }

  bool runForOffice() {
    if (officeGate() != null) return false;
    _activityUses['election'] = 1;
    _money -= 100;
    if (_random.nextInt(100) < electionChance) {
      final job = jobById('politics_0')!;
      _hire(job);
      _fame = (_fame + 6).clamp(0, 100);
      _setLog(
        'You ran for the town council on fixing the roads and keeping the '
        'library open, and you won. Being elected is a job, with a salary.',
        kind: LifeLogKind.career,
      );
    } else {
      _happiness = _clamp(_happiness - 5);
      _setLog(
        'You ran for office and lost by a few hundred votes. The 100 you spent '
        'on the campaign is gone. Most people who win lost first.',
        kind: LifeLogKind.career,
      );
    }
    _changed();
    return true;
  }
}
