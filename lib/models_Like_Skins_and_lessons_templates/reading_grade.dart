/// Flesch-Kincaid reading grade, computed at runtime.
///
/// # Why this exists as well as the generated lookup
///
/// `question_reading_levels.dart` is generated from the Academy bank by
/// `tool/measure_question_reading_level.py`, which is right for that bank: it
/// is a fixed list of 187 items, and a build step that can be re-run and
/// reviewed is better than arithmetic hidden inside the app.
///
/// Finance Brawl's questions are not like that. They live inline in a
/// 3,800-line widget file plus a second module, and keying a generated lookup
/// by prompt text would be brittle in the exact way that matters — edit one
/// word of a question and it silently loses its grade, which fails *open* and
/// serves it to a four-year-old.
///
/// **That is not hypothetical. It already happened.** The Academy was routed
/// by age and Finance Brawl was not, so a player who set their age to "8 or
/// under" was asked *"What is a CD Ladder strategy?"* — with "staggering
/// multiple CD maturity dates to keep liquidity while earning higher rates"
/// as the correct answer. Every test passed, because nothing tested the game
/// that had its own bank.
///
/// So: one formula, two callers, and a test asserting they agree. Computing
/// it here means a new question is graded the moment it is written, with no
/// build step to forget.
///
/// # The formula
///
/// ```
/// 0.39 * (words / sentences) + 11.8 * (syllables / words) - 15.59
/// ```
///
/// The standard US grade level used by federal plain-language rules and most
/// school reading software. Grade 3 is roughly eight years old, grade 7 about
/// twelve, grade 11 about sixteen.
///
/// # What it does not measure
///
/// Conceptual difficulty. "What is a Roth IRA?" is five plain words and
/// hopeless for a nine-year-old, and this returns a low grade for it. The
/// grade is one input to age routing; the topic is the other, and both are
/// used — see `kAdultOnlyTopics`.
library;

/// Words that mark a question as adult regardless of how simply it is worded.
///
/// **The gap the reading grade cannot close.** Flesch-Kincaid measures
/// sentence and word length, so a short question about a complicated thing
/// scores as easy. "What is a CD Ladder?" is four words and grade 2.9; it is
/// also meaningless to an eight-year-old, and it is exactly the question that
/// was served to one.
///
/// Deliberately a small list of *topics*, not a blocklist of scary words. It
/// names financial instruments and adult obligations a child has no way to
/// have met — not "debt" or "loan" or "tax", which are things a nine-year-old
/// can and should learn about.
const Set<String> kAdultOnlyTopics = <String>{
  'cd ladder',
  'certificate of deposit',
  'roth',
  '401(k)',
  '401k',
  'ira',
  'vesting',
  'amortization',
  'amortisation',
  'apr',
  'apy',
  'escrow',
  'annuity',
  'mutual fund',
  'index fund',
  'etf',
  'capital gains',
  'dividend',
  'mortgage',
  'refinanc',
  'credit score',
  'credit utilization',
  'credit utilisation',
  'deductible',
  'premium',
  'copay',
  'w-2',
  'w2 ',
  '1099',
  'withholding',
  'tax bracket',
  'depreciation',
  'liquidity',
  'diversif',
  'compound annual',
  'portfolio',
  'brokerage',
  'bond yield',
  'inflation-adjusted',
};

/// Syllables in one word, by vowel groups with the usual corrections.
///
/// Not a dictionary lookup. Errors average out across a whole question and
/// would not across a single word, which is why nothing here reports a grade
/// for one word in isolation.
int syllablesIn(String word) {
  final cleaned = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  if (cleaned.isEmpty) return 0;

  const vowels = 'aeiouy';
  var count = 0;
  var previousWasVowel = false;
  for (final ch in cleaned.split('')) {
    final isVowel = vowels.contains(ch);
    if (isVowel && !previousWasVowel) count++;
    previousWasVowel = isVowel;
  }

  // Silent terminal e: "make" is one syllable, not two.
  if (cleaned.endsWith('e') &&
      !cleaned.endsWith('le') &&
      !cleaned.endsWith('ee') &&
      !cleaned.endsWith('ye')) {
    count--;
  }
  // -ed is usually silent unless it follows t or d: "asked" vs "wanted".
  if (cleaned.endsWith('ed') &&
      cleaned.length > 3 &&
      !'td'.contains(cleaned[cleaned.length - 3])) {
    count--;
  }

  return count < 1 ? 1 : count;
}

/// The Flesch-Kincaid grade level of [text].
double readingGrade(String text) {
  // Numerals read as their digits rather than as one short word, so "$1,200"
  // would otherwise flatter the score.
  final normalised = text.replaceAll(RegExp(r'\$?\d[\d,]*'), ' number ');

  final sentences = RegExp(r'[.!?]+').allMatches(normalised).length;
  final words = RegExp(r"[A-Za-z']+")
      .allMatches(normalised)
      .map((m) => m.group(0)!)
      .toList();
  if (words.isEmpty) return 0;

  final totalSyllables = words.fold<int>(0, (sum, w) => sum + syllablesIn(w));
  final sentenceCount = sentences < 1 ? 1 : sentences;

  return 0.39 * (words.length / sentenceCount) +
      11.8 * (totalSyllables / words.length) -
      15.59;
}

/// True when [text] names something only an older reader could have met.
///
/// Checked *in addition to* the reading grade, never instead of it. A question
/// can be hard to read and about something simple, or easy to read and about
/// something no child has encountered — and the second one is what let a CD
/// ladder question reach an eight-year-old.
bool mentionsAdultTopic(String text) {
  final lower = text.toLowerCase();
  for (final topic in kAdultOnlyTopics) {
    if (lower.contains(topic)) return true;
  }
  return false;
}
