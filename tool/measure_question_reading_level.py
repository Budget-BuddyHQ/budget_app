# -*- coding: utf-8 -*-
"""Measure how hard each quiz question is to *read*.

WHY
---
Budget Buddy claims to teach ages 4 to 21 with one question bank. Two facts
make that claim hollow today:

  * `AgeBand.under13` puts a **four-year-old and a twelve-year-old in the same
    bucket**, so they are served identical content.
  * Of 187 questions, only 41 carry a `QuizDifficulty` at all. The other 146
    are untagged, so in practice nothing is differentiated by anything.

Hand-tagging 187 questions by eye would be slow, inconsistent between sittings,
and unreviewable — three people would produce three different answers and none
could show their working.

WHAT THIS MEASURES
------------------
**Flesch-Kincaid grade level**, the standard readability formula used by US
government plain-language rules and by most school reading software:

    0.39 * (words / sentences) + 11.8 * (syllables / words) - 15.59

The output is a US grade level, which maps to age directly: grade 3 is about
eight years old, grade 7 about twelve, grade 11 about sixteen.

It measures *reading difficulty*, not conceptual difficulty. Those are
different things and the distinction matters: "What is a Roth IRA?" is short,
plain, and utterly beyond a nine-year-old. So this is one input to banding, not
the whole of it — the concept a question belongs to is the other, and it is
already recorded.

Syllable counting is heuristic (vowel groups, silent-e, common suffixes). It is
accurate enough for banding across a bank this size and would not be for a
single sentence, which is why the tool reports distributions rather than
verdicts on individual items.

USAGE
-----
    python tool/measure_question_reading_level.py
    python tool/measure_question_reading_level.py --list-hardest 15
"""
import argparse
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BANK = os.path.join(ROOT, 'lib', 'models_Like_Skins_and_lessons_templates',
                    'quiz_bank.dart')

VOWELS = 'aeiouy'


def syllables(word):
    """Vowel groups, with the usual corrections.

    Not a dictionary lookup. Across a bank of ~190 questions the errors
    average out; on any single word they will not, which is why nothing here
    reports a grade for one question in isolation.
    """
    word = re.sub(r'[^a-z]', '', word.lower())
    if not word:
        return 0

    count = 0
    previous_was_vowel = False
    for ch in word:
        is_vowel = ch in VOWELS
        if is_vowel and not previous_was_vowel:
            count += 1
        previous_was_vowel = is_vowel

    # Silent terminal e: "make" is one syllable, not two.
    if word.endswith('e') and not word.endswith(('le', 'ee', 'ye')):
        count -= 1
    # -ed is usually silent unless it follows t or d: "asked" vs "wanted".
    if word.endswith('ed') and len(word) > 3 and word[-3] not in 'td':
        count -= 1

    return max(1, count)


def grade_level(text):
    """Flesch-Kincaid grade for one passage."""
    # Numerals read as their digits rather than as words, so a bare "$1,200"
    # would otherwise count as one short syllable and flatter the score.
    text = re.sub(r'\$?\d[\d,]*', ' number ', text)

    sentences = max(1, len(re.findall(r'[.!?]+', text)))
    words = re.findall(r"[A-Za-z']+", text)
    if not words:
        return 0.0

    total_syllables = sum(syllables(w) for w in words)
    return (0.39 * (len(words) / sentences)
            + 11.8 * (total_syllables / len(words))
            - 15.59)


def read_questions():
    src = io.open(BANK, encoding='utf8').read()
    out = []
    for block in src.split('QuizQuestion(')[1:]:
        qid = re.search(r"id:\s*'([^']+)'", block)
        if not qid:
            continue

        # Prompts come in three shapes: a plain literal, several adjacent
        # literals concatenated across lines, and a **raw** string (r'...')
        # -- the last used wherever a prompt contains a dollar sign, which in
        # a money app is a lot of them. The first version of this parser did
        # not allow for the `r` prefix and silently skipped nine questions.
        # They then had no measured grade, so they were served to every age
        # band regardless, which is the exact bug this tool exists to fix.
        # An optional `r` on each literal covers all three shapes.
        joined = re.search(r"prompt:\s*((?:r?'(?:\\.|[^'])*'\s*)+)", block)
        if not joined:
            continue
        text = ''.join(re.findall(r"r?'((?:\\.|[^'])*)'", joined.group(1)))

        text = text.replace("\\'", "'").replace('\\$', '$')
        difficulty = re.search(r'QuizDifficulty\.(\w+)', block)
        out.append({
            'id': qid.group(1),
            'prompt': text,
            'difficulty': difficulty.group(1) if difficulty else 'untagged',
            'grade': grade_level(text),
        })
    return out


# Grade -> the youngest band that can comfortably read it.
BANDS = [
    (3.5, 'under9', '4 to 8'),
    (6.5, 'age9to12', '9 to 12'),
    (9.5, 'teen13to15', '13 to 15'),
    (12.0, 'teen16to17', '16 to 17'),
    (99.0, 'adult18plus', '18 or older'),
]


def band_for(grade):
    for ceiling, key, label in BANDS:
        if grade <= ceiling:
            return key, label
    return BANDS[-1][1], BANDS[-1][2]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--list-hardest', type=int, default=0)
    ap.add_argument('--write', action='store_true')
    args = ap.parse_args()

    questions = read_questions()
    if not questions:
        print('parsed no questions — the bank format changed')
        return 1

    print('%d questions parsed\n' % len(questions))

    buckets = {}
    for q in questions:
        key, label = band_for(q['grade'])
        buckets.setdefault((key, label), []).append(q)

    print('reading level, by the youngest band that can read it:')
    for ceiling, key, label in BANDS:
        got = buckets.get((key, label), [])
        bar = '#' * int(len(got) / max(1, len(questions)) * 50)
        print('  %-12s (%-10s) %4d  %s' % (key, label, len(got), bar))

    grades = sorted(q['grade'] for q in questions)
    print('\nmedian grade %.1f, range %.1f to %.1f'
          % (grades[len(grades) // 2], grades[0], grades[-1]))

    tagged = sum(1 for q in questions if q['difficulty'] != 'untagged')
    print('%d of %d carry an explicit QuizDifficulty (%d untagged)'
          % (tagged, len(questions), len(questions) - tagged))

    if args.write:
        lines = [
            '// GENERATED BY tool/measure_question_reading_level.py',
            '// DO NOT EDIT BY HAND. Re-run the tool after changing the bank.',
            '//',
            '// Flesch-Kincaid grade level per question, used to serve a',
            '// six-year-old and an eighteen-year-old different questions out',
            '// of one bank. See `ageAppropriateQuestions` in quiz_bank.dart.',
            '//',
            '// A separate lookup rather than a field on all %d questions:'
            % len(questions),
            '// the bank is 3,000 lines of hand-written content, and a',
            '// generator that rewrites it in place is one bad regex away from',
            '// corrupting questions nobody would notice were wrong.',
            '',
            'const Map<String, double> kQuestionReadingGrade = '
            '<String, double>{',
        ]
        for q in sorted(questions, key=lambda q: q['id']):
            lines.append("  '%s': %.1f," % (q['id'], q['grade']))
        lines.append('};')
        out = os.path.join(
            ROOT, 'lib', 'models_Like_Skins_and_lessons_templates',
            'question_reading_levels.dart')
        io.open(out, 'w', encoding='utf8', newline='\n').write(
            '\n'.join(lines) + '\n')
        print('\nwrote %s' % out)

    if args.list_hardest:
        print('\nhardest to read:')
        for q in sorted(questions, key=lambda q: -q['grade'])[
                :args.list_hardest]:
            print('  grade %5.1f  %s' % (q['grade'], q['prompt'][:78]))

    return 0


if __name__ == '__main__':
    sys.exit(main())
