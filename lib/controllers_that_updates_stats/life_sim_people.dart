part of 'life_sim_controller.dart';

/// The people in a life, in the controller. See `life_people.dart` for the
/// rules and `relationship.dart` for the model.
extension LifeSimPeople on LifeSimController {
  // ---- Groups, for the relationships screen -----------------------------------

  /// Parents, brothers, sisters, grandparents and the like, closest first.
  List<Relationship> get familyMembers => [
    for (final p in people)
      if (p.kind == RelationshipKind.family && p.isAlive) p,
  ];

  /// A partner or a spouse.
  List<Relationship> get partners => [
    for (final p in people)
      if ((p.kind == RelationshipKind.partner ||
              p.kind == RelationshipKind.spouse) &&
          p.isAlive)
        p,
  ];

  List<Relationship> get childrenOfYours => [
    for (final p in people)
      if (p.kind == RelationshipKind.child && p.isAlive) p,
  ];

  List<Relationship> get friendList => [
    for (final p in people)
      if (p.kind == RelationshipKind.friend && p.isAlive) p,
  ];

  /// Coworkers, contacts and mentors.
  List<Relationship> get workPeople => [
    for (final p in people)
      if (p.kind.isProfessional && p.isAlive) p,
  ];

  /// People who have died. They stay in the list under a heading of their own.
  List<Relationship> get remembered => [
    for (final p in people)
      if (!p.isAlive) p,
  ];

  bool get hasPartner => partners.isNotEmpty;
  bool get isMarried =>
      _people.any((p) => p.kind == RelationshipKind.spouse && p.isAlive);

  Relationship? personByName(String name) => _personNamed(name);

  /// Test seam: put a fully described person into the life.
  @visibleForTesting
  void debugPutPerson(Relationship person) {
    _people.add(person);
    _changed();
  }

  /// Gives a life the family it starts with.
  void _seedFamily() {
    for (final p in buildFamily(_random, surname: surnameOf(name))) {
      _people.add(p);
    }
  }

  // ---- What can be done, and what stops it ---------------------------------------

  LifeAction? _budgetFor(PersonAction action) => switch (action) {
    PersonAction.conversation ||
    PersonAction.askAdvice => LifeAction.conversation,
    PersonAction.compliment => LifeAction.compliment,
    PersonAction.spendTime => LifeAction.spendTime,
    PersonAction.gift => LifeAction.buyGift,
    PersonAction.askMoney => LifeAction.askMoney,
    PersonAction.date => LifeAction.date,
    PersonAction.propose || PersonAction.startFamily => null,
  };

  /// The actions the screen should show for [name].
  List<PersonAction> actionsFor(String name) {
    final p = _personNamed(name);
    if (p == null) return const <PersonAction>[];
    return personActionsFor(p, playerAge: _age);
  }

  /// Why [action] cannot be done with [name] now, or null.
  String? personActionGate(PersonAction action, String name) {
    final p = _personNamed(name);
    if (p == null) return 'You do not know them';
    if (finished) return 'This life is over';
    if (!p.isAlive) return 'They have passed away';
    if (!personActionsFor(p, playerAge: _age).contains(action)) {
      return 'Not something you can do with them';
    }
    if ((_touchesThisYear[name] ?? 0) >= kTouchesPerPersonPerYear) {
      return 'You have given them a lot of time this year';
    }
    final budget = _budgetFor(action);
    if (budget != null && budgetFor(budget).exhausted) {
      return 'Done for this year';
    }
    switch (action) {
      case PersonAction.gift:
        // `giveGift` asks for the 50 whoever is asking, so the gate does too.
        if (_money < 50) return 'A gift costs 50 coins';
      case PersonAction.date:
        if (_age < 18) return 'You need to be 18';
        if (_money < 40) return 'A date costs 40 coins';
      case PersonAction.askMoney:
        if (p.closeness < 40) return 'They do not know you well enough';
      case PersonAction.propose:
        if (_age < 21) return 'You need to be 21';
        if (isMarried) return 'You are already married';
        if (p.closeness < 70) return 'Only when you are closer';
      case PersonAction.startFamily:
        if (_age < 20) return 'You need to be 20';
        if (_age > 46) return 'It is a bit late for that now';
        if (_lastChildAge != null && _age - _lastChildAge! < 2) {
          return 'Give it a couple of years';
        }
      default:
        break;
    }
    return null;
  }

  void _touch(String name) {
    _touchesThisYear[name] = (_touchesThisYear[name] ?? 0) + 1;
  }

  String _first(Relationship p) => p.name.split(' ').first;

  T _pickOf<T>(List<T> options) => options[_random.nextInt(options.length)];

  /// Does [action] with [name]. Returns whether it happened.
  bool doPersonAction(PersonAction action, String name) {
    if (personActionGate(action, name) != null) return false;
    final p = _personNamed(name)!;
    switch (action) {
      case PersonAction.conversation:
        return _talk(p);
      case PersonAction.askAdvice:
        return _advice(p);
      case PersonAction.compliment:
        return _compliment(p);
      case PersonAction.spendTime:
        spendTimeWith(name);
        _touch(name);
        return true;
      case PersonAction.gift:
        giveGift(name);
        _touch(name);
        return true;
      case PersonAction.askMoney:
        return _askForMoney(p);
      case PersonAction.date:
        return _goOnDate(p);
      case PersonAction.propose:
        return _propose(p);
      case PersonAction.startFamily:
        return _startFamily(p);
    }
  }

  void _closer(Relationship p, int by) {
    _updatePerson(
      p.name,
      p.copyWith(
        closeness: (p.closeness + by).clamp(0, 100),
        lastSeenAge: _age,
      ),
    );
  }

  bool _talk(Relationship p) {
    final gain = _scaled(
      LifeAction.conversation,
      closenessFor(PersonAction.conversation),
    );
    final joy = _scaled(LifeAction.conversation, 2);
    if (!_spend(LifeAction.conversation)) return false;
    _touch(p.name);
    _happiness = _clamp(_happiness + joy);
    _closer(p, gain);
    final first = _first(p);
    _setLog(
      _pickOf([
        'You talked with $first for a couple of hours about nothing in '
            'particular. It was the best part of the week.',
        'You and $first caught up properly, for the first time in a while.',
        '$first told you a story you had never heard before.',
        'You asked $first how they were really doing, and they told you.',
      ]),
      kind: LifeLogKind.people,
    );
    _changed();
    return true;
  }

  bool _advice(Relationship p) {
    final gain = _scaled(
      LifeAction.conversation,
      closenessFor(PersonAction.askAdvice),
    );
    if (!_spend(LifeAction.conversation)) return false;
    _touch(p.name);
    _closer(p, gain);
    _smarts = _clamp(_smarts + 2);
    final first = _first(p);
    _setLog(
      _pickOf([
        'You asked $first what they would do. You came away with a better plan '
            'than you went in with.',
        '$first told you about a mistake they made at your age. It saved you '
            'making it.',
      ]),
      kind: LifeLogKind.people,
    );
    _changed();
    return true;
  }

  bool _compliment(Relationship p) {
    final gain = _scaled(
      LifeAction.compliment,
      closenessFor(PersonAction.compliment),
    );
    if (!_spend(LifeAction.compliment)) return false;
    _touch(p.name);
    _happiness = _clamp(_happiness + 1);
    _closer(p, gain);
    final first = _first(p);
    _setLog(
      _pickOf([
        'You told $first something you admire about them. They went a bit '
            'pink and changed the subject.',
        'You noticed something $first had done and said so. It meant more to '
            'them than it cost you.',
      ]),
      kind: LifeLogKind.people,
    );
    _changed();
    return true;
  }

  bool _askForMoney(Relationship p) {
    if (!_spend(LifeAction.askMoney)) return false;
    _touch(p.name);
    final isParent = p.role == 'Mother' || p.role == 'Father';
    final chance =
        (p.closeness * 0.8 +
                (isParent && _age < 25 ? 20 : 0) -
                (_age >= 30 ? 15 : 0))
            .round()
            .clamp(10, 90);
    final first = _first(p);
    if (_random.nextInt(100) < chance) {
      final amount = isParent
          ? 60 + _random.nextInt(90)
          : 20 + _random.nextInt(45);
      _money += amount;
      _closer(p, closenessFor(PersonAction.askMoney));
      _setLog(
        '$first gave you $amount. It helped, and you both felt a little '
        'awkward about it. Money between people is never only money.',
        kind: LifeLogKind.people,
      );
      _teach(FinanceConcept.needsVsWants);
    } else {
      _closer(p, -3);
      _happiness = _clamp(_happiness - 3);
      _setLog(
        '$first said they could not spare it right now, kindly. Better to '
        'have asked than to have gone without.',
        kind: LifeLogKind.people,
      );
    }
    _changed();
    return true;
  }

  bool _goOnDate(Relationship p) {
    final gain = _scaled(LifeAction.date, closenessFor(PersonAction.date));
    final joy = _scaled(LifeAction.date, 6);
    if (!_spend(LifeAction.date)) return false;
    _touch(p.name);
    _money -= 40;
    _happiness = _clamp(_happiness + joy);
    _closer(p, gain);
    _setLog(
      'You took ${_first(p)} out for a proper evening: +$joy Happiness, '
      '-40 coins. Some things are worth the money.',
      kind: LifeLogKind.people,
    );
    _changed();
    return true;
  }

  bool _propose(Relationship p) {
    _touch(p.name);
    final chance = (p.closeness - 15).clamp(20, 95);
    final first = _first(p);
    if (_random.nextInt(100) < chance) {
      _updatePerson(
        p.name,
        p.copyWith(
          kind: RelationshipKind.spouse,
          role: 'Spouse',
          closeness: (p.closeness + 10).clamp(0, 100),
          lastSeenAge: _age,
        ),
      );
      _happiness = _clamp(_happiness + 10);
      _setLog('$first said yes. You are engaged.', kind: LifeLogKind.people);
      _queueWeddingCard(p);
    } else {
      _closer(p, -8);
      _happiness = _clamp(_happiness - 6);
      _setLog(
        '$first was not ready. Nothing is ruined, and it stung. Time '
        'together is what changes that.',
        kind: LifeLogKind.people,
      );
    }
    _changed();
    return true;
  }

  void _queueWeddingCard(Relationship p) {
    _queuedEvents.add(
      LifeEvent(
        id: 'v2_wedding_$_age',
        prompt:
            'You and ${_first(p)} are getting married. How big should the day '
            'be?',
        icon: Icons.celebration_rounded,
        choices: [
          for (final w in Wedding.values)
            LifeChoice(
              label: '${w.label} (${w.cost})',
              outcome: switch (w) {
                Wedding.small =>
                  'Twenty people, a nice meal, and money left for the years '
                      'that follow. The marriage is the same.',
                Wedding.family =>
                  'Everybody who mattered came, and it was warm and loud and '
                      'reasonable.',
                Wedding.big =>
                  'A wonderful day, and a bill that lasted longer than the '
                      'flowers. A wedding is a day. A marriage is years.',
              },
              money: -w.cost,
              happiness: w.joy,
              teaches: FinanceConcept.opportunityCost,
            ),
        ],
      ),
    );
  }

  bool _startFamily(Relationship p) {
    _touch(p.name);
    final girl = _random.nextBool();
    final child = childName(_random, surname: surnameOf(name), girl: girl);
    _people.add(
      Relationship(
        name: child,
        kind: RelationshipKind.child,
        closeness: 85,
        metAtAge: _age,
        lastSeenAge: _age,
        role: girl ? 'Daughter' : 'Son',
        ageOffset: -_age,
      ),
    );
    _lastChildAge = _age;
    _applyEventMoney(-120);
    _happiness = _clamp(_happiness + 12);
    _setLog(
      'You and ${_first(p)} welcomed ${child.split(' ').first}. It is '
      'wonderful, and it is also about 40 a year for a long time to come.',
      kind: LifeLogKind.people,
    );
    _teach(FinanceConcept.needsVsWants);
    _changed();
    return true;
  }

  // ---- Meeting people --------------------------------------------------------------

  /// Somebody new, if there is room in a life for them.
  bool _meetFriend({String? role}) {
    final friends = _people.where(
      (p) => p.kind == RelationshipKind.friend && p.isAlive,
    );
    if (friends.length >= 12) return false;
    final taken = {for (final p in _people) p.name};
    final person = freshContactName(_random, taken);
    _people.add(
      Relationship(
        name: person,
        kind: RelationshipKind.friend,
        closeness: 50,
        metAtAge: _age,
        lastSeenAge: _age,
        role: role ?? 'Friend',
      ),
    );
    _setLog('You met $person and got on right away.', kind: LifeLogKind.people);
    return true;
  }

  /// A chance of finding somebody to be with.
  bool _maybeMeetPartner(int chancePercent) {
    if (hasPartner) return false;
    final looks = (_looks - 50) / 10;
    final charm = (_skills[LifeSkill.charisma] ?? 0) / 8;
    final chance = (chancePercent + looks + charm).round().clamp(5, 90);
    if (_random.nextInt(100) >= chance) return false;
    final taken = {for (final p in _people) p.name};
    final person = freshContactName(_random, taken);
    _people.add(
      Relationship(
        name: person,
        kind: RelationshipKind.partner,
        closeness: 55,
        metAtAge: _age,
        lastSeenAge: _age,
        role: 'Partner',
      ),
    );
    _happiness = _clamp(_happiness + 8);
    _setLog(
      'You met $person, and it turned into something. Take your time.',
      kind: LifeLogKind.people,
    );
    return true;
  }

  // ---- The years -----------------------------------------------------------------------

  /// Once a year: the people older than you get older, and some do not make it
  /// through.
  ///
  /// Only family and partners are aged, because those are the people whose
  /// ages a life tracks. Nobody's child dies here, on purpose.
  void _agePeople() {
    for (var i = 0; i < _people.length; i++) {
      final p = _people[i];
      if (!p.isAlive) continue;
      if (p.kind != RelationshipKind.family &&
          p.kind != RelationshipKind.partner &&
          p.kind != RelationshipKind.spouse) {
        continue;
      }
      final age = p.ageWhen(_age) ?? _age;
      if (_random.nextDouble() >= yearlyDeathChance(age)) continue;
      _people[i] = p.copyWith(passedAge: _age);
      final how = PassingKind.roll(_random, age);
      _queuedEvents.add(bereavementEvent(person: p, how: how, playerAge: _age));
      final elder =
          p.role == 'Mother' ||
          p.role == 'Father' ||
          p.role.startsWith('Grand');
      if (elder && _age >= 21) _receiveInheritance(p);
    }
  }

  void _receiveInheritance(Relationship p) {
    final scale = switch (origin) {
      LifeOrigin.struggling => 0.5,
      LifeOrigin.workingClass => 1.0,
      LifeOrigin.comfortable => 2.0,
      LifeOrigin.wealthy => 5.0,
    };
    final amount = ((60 + _random.nextInt(240)) * scale).round();
    _money += amount;
    _setLog(
      '${_first(p)} left you $amount. Money that comes from losing somebody '
      'never feels like a windfall.',
      kind: LifeLogKind.money,
    );
    _teach(FinanceConcept.incomeVsWealth);
  }

  /// Cards that belong to a particular age rather than to the random pool.
  void _queueAgeCards() {
    if (_age == 22 &&
        _rentalId == kFamilyHome.id &&
        !ownsHome &&
        !_edu.inPostSecondary &&
        _people.any((p) => p.kind == RelationshipKind.family && p.isAlive)) {
      _queuedEvents.add(
        const LifeEvent(
          id: 'v2_move_out',
          prompt:
              'You are 22 and still at home. Time to think about a place of '
              'your own?',
          icon: Icons.home_work_rounded,
          choices: [
            LifeChoice(
              label: 'Rent a room in a shared house (60 a year)',
              outcome:
                  'Cheap, a bit chaotic, and you split the bills. Most first '
                  'homes look like this.',
              moveTo: 'shared',
              teaches: FinanceConcept.needsVsWants,
            ),
            LifeChoice(
              label: 'Get a small apartment (130 a year)',
              outcome:
                  'Your own front door, and a big slice of every paycheck. '
                  'Rent is a need, so it comes out of that part of the budget.',
              moveTo: 'studio',
              teaches: FinanceConcept.needsVsWants,
            ),
            LifeChoice(
              label: 'Stay with family and save',
              outcome:
                  'Free rent means more to save. It is a real choice, and it '
                  'is not a failure to make it.',
              happiness: -1,
              teaches: FinanceConcept.needsVsWants,
            ),
          ],
        ),
      );
    }
  }
}
