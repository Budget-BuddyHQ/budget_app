import 'lesson.dart';
import 'player_profile.dart';
import 'question_stage.dart';
import 'quiz_bank.dart';
import 'reading_grade.dart';

/// Which questions Finance Brawl may ask, for a player of a given age.
///
/// **Reported as:** a ten-year-old playing the Brawl *"is getting questions
/// that he should not even be facing."*
///
/// **Why it happened.** The Brawl's own bank was written for teenagers and
/// adults: Roth IRAs, required minimum distributions, tax-loss harvesting, CD
/// ladders, IPOs, bear markets. Below thirteen it was screened by a reading
/// grade and a short list of adult words. Reading grade measures how long the
/// words are, not whether a child has ever met the thing, and the word list
/// missed most of a bank like that. "What is a bear market?" is short, plain,
/// and meaningless to a ten-year-old.
///
/// **What replaces it.** Younger players are not shown the Brawl's own bank at
/// all. They are asked the Academy's questions, which each belong to a unit that
/// somebody hand-assigned an age to (`question_stage.dart`), and only the units
/// written for seven-to-ten-year-olds and younger. Older players still get the
/// Brawl's own questions, screened by a longer list of topics that belong to a
/// later part of life, and everybody gets the Academy's questions as well.
class BrawlItem {
  const BrawlItem({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  /// One of the Brawl's own questions, which have no id of their own.
  factory BrawlItem.native({
    required String question,
    required List<String> options,
    required int correctIndex,
    required String explanation,
  }) => BrawlItem(
    id: 'brawl:${question.hashCode}',
    question: question,
    options: options,
    correctIndex: correctIndex,
    explanation: explanation,
  );

  factory BrawlItem.fromAcademy(QuizQuestion q) => BrawlItem(
    id: q.id,
    question: q.prompt,
    options: q.options,
    correctIndex: q.correctIndex,
    explanation: q.explanation,
  );
}

/// Topics that belong to teenage or adult life: retirement accounts, markets,
/// payroll, how loans and taxes are structured.
///
/// Kept apart from [kAdultOnlyTopics], which is the shorter list the Academy has
/// always used to guard the youngest readers. This one is what the Brawl's own
/// bank needs, because that bank is written almost entirely in this vocabulary.
const Set<String> kBrawlLaterLifeTopics = <String>{
  'rmd',
  'required minimum',
  'tax-loss',
  'ipo',
  'initial public',
  'bear market',
  'bull market',
  'dollar-cost',
  'asset allocation',
  'volatility',
  'marginal tax',
  'progressive income',
  'fica',
  'payroll',
  'paystub',
  'payslip',
  'gross',
  'net pay',
  'sinking fund',
  'rule of 72',
  'nominal',
  'debt avalanche',
  'debt snowball',
  'consolidation',
  'balance transfer',
  'co-signer',
  'cosigner',
  'default',
  'predatory',
  'unsecured',
  'secured',
  'grace period',
  'money market',
  'stock',
  'share price',
  'bond',
  'invest',
  'retire',
  'pension',
  'inflation',
  'interest rate',
  'compound',
  'recession',
  'bankrupt',
  'lease',
  'insurance',
  'hedge',
  'equity',
  'asset',
  'liabilit',
  'net worth',
  'securit',
  'tax',
  'credit',
  'loan',
  'lending',
  'lifestyle creep',
  'opportunity cost',
};

bool _mentions(String text, Set<String> topics) {
  final lower = text.toLowerCase();
  for (final topic in topics) {
    if (lower.contains(topic)) return true;
  }
  return false;
}

bool _itemMentions(BrawlItem item, Set<String> topics) =>
    _mentions(item.question, topics) ||
    item.options.any((o) => _mentions(o, topics));

/// The stage a question's unit was written for, or null for one with no unit.
AgeStage? _stageOf(BrawlItem item) => kQuestionStage[item.id];

/// The smallest pool a young player is ever served, before the next stage up is
/// let in. A run reaches several checkpoints of three questions each, and fewer
/// than this repeats within one sitting.
const int kBrawlMinimumKidPool = 30;

/// The questions Finance Brawl may ask a player in [band].
///
/// [native] is the Brawl's own bank, already converted to [BrawlItem]s.
List<BrawlItem> brawlPool({
  required AgeBand band,
  required List<BrawlItem> native,
}) {
  final academy = [
    for (final q in ageAppropriateQuestions(allQuizQuestions.toList(), band))
      BrawlItem.fromAcademy(q),
  ];

  switch (band) {
    case AgeBand.under9:
    case AgeBand.age9to12:
      // Only the units written for ten and under, and never the Brawl's own
      // bank. If that leaves too few, the next stage up is let in, but only the
      // questions that also avoid the later-life topics.
      final young = [
        for (final item in academy)
          if ((_stageOf(item)?.index ?? 0) <= AgeStage.youngKids.index) item,
      ];
      if (young.length >= kBrawlMinimumKidPool) return young;
      final gentler = [
        for (final item in academy)
          if ((_stageOf(item)?.index ?? 0) > AgeStage.youngKids.index &&
              !_itemMentions(item, kBrawlLaterLifeTopics) &&
              !_itemMentions(item, kAdultOnlyTopics))
            item,
      ];
      return [...young, ...gentler];

    case AgeBand.teen13to15:
    case AgeBand.undisclosed:
      return [
        ...academy,
        for (final item in native)
          if (!_itemMentions(item, kBrawlLaterLifeTopics) &&
              !_itemMentions(item, kAdultOnlyTopics) &&
              readingGrade(item.question) <= band.maxReadingGrade)
            item,
      ];

    case AgeBand.teen16to17:
      return [
        ...academy,
        for (final item in native)
          if (readingGrade(item.question) <= band.maxReadingGrade) item,
      ];

    case AgeBand.adult18plus:
      return [...academy, ...native];
  }
}
