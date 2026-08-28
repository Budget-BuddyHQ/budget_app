import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_extras.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_sources.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Academy claims its facts are checkable. This is what makes that true.
///
/// An app that teaches money to children is making claims — about interest,
/// credit scores, payroll withholding, retirement rules — to an audience that
/// mostly cannot evaluate them. "Says who?" is the fair question, and the most
/// useful habit a finance app can model is *check the source*. Content with no
/// attribution is indistinguishable from content someone invented.
///
/// So these are not stylistic checks. Each one is a promise the app makes to a
/// reader, expressed as something that fails the build.
void main() {
  final lessons = <Lesson>[
    for (final unit in lessonUnits)
      for (final lesson in unit.lessons)
        if (lesson.type == LessonNodeType.lesson) lesson,
  ];

  group('every lesson is sourced', () {
    test('no lesson ships without a citation', () {
      // The promise. A lesson with no source is a lesson a parent cannot
      // check, and adding one is a two-line change — there is no reason for
      // an exception to exist.
      final uncited = lessons
          .where(
            (lesson) => (kLessonCitations[lesson.id] ?? const []).isEmpty,
          )
          .map((lesson) => '${lesson.id} (${lesson.title})')
          .toList();
      expect(
        uncited,
        isEmpty,
        reason: 'these lessons have no source:\n  ${uncited.join('\n  ')}',
      );
    });

    test('every citation resolves to a real source', () {
      // A citation pointing at a deleted id renders as nothing, which looks
      // exactly like a lesson that was never sourced.
      final broken = <String>[];
      kLessonCitations.forEach((lessonId, ids) {
        for (final id in ids) {
          if (!kLessonSources.containsKey(id)) {
            broken.add('$lessonId cites unknown source "$id"');
          }
        }
      });
      expect(broken, isEmpty, reason: broken.join('\n'));
    });

    test('citations name lessons that exist', () {
      // The other direction: a citation for a lesson that was renamed or
      // removed is dead weight that hides the fact its replacement is
      // uncited.
      final ids = lessons.map((lesson) => lesson.id).toSet();
      final orphans = kLessonCitations.keys
          .where((id) => !ids.contains(id))
          .toList();
      expect(
        orphans,
        isEmpty,
        reason: 'citations exist for lessons that do not: $orphans',
      );
    });
  });

  group('the sources themselves', () {
    test('every source is HTTPS', () {
      for (final entry in kLessonSources.entries) {
        final uri = Uri.tryParse(entry.value.url);
        expect(uri, isNotNull, reason: '${entry.key} has an unparseable URL');
        expect(
          uri!.scheme,
          'https',
          reason: '${entry.key} is not served over HTTPS',
        );
      }
    });

    test('every source is on a trusted publisher', () {
      // Deliberately narrow: federal agencies and the regulators' own
      // investor/consumer education arms. A bank's blog would be easier to
      // quote and would tie the curriculum's credibility to a company that
      // sells the products being explained.
      final untrusted = <String>[];
      for (final entry in kLessonSources.entries) {
        final host = Uri.parse(entry.value.url).host;
        if (!kTrustedSourceHosts.contains(host)) {
          untrusted.add('${entry.key} -> $host');
        }
      }
      expect(
        untrusted,
        isEmpty,
        reason:
            'add the host to kTrustedSourceHosts deliberately, or cite a '
            'primary publisher instead:\n${untrusted.join('\n')}',
      );
    });

    test('every source names a publisher and a title', () {
      for (final entry in kLessonSources.entries) {
        expect(entry.value.publisher, isNotEmpty, reason: entry.key);
        expect(entry.value.title, isNotEmpty, reason: entry.key);
      }
    });

    test('no source is defined and never used', () {
      // Dead citations drift out of date silently, and an unused one is a URL
      // nobody will notice has rotted.
      final used = <String>{
        for (final ids in kLessonCitations.values) ...ids,
      };
      final unused = kLessonSources.keys
          .where((id) => !used.contains(id))
          .toList();
      expect(unused, isEmpty, reason: 'unused sources: $unused');
    });
  });

  group('every quiz topic is sourced', () {
    test('every skill a live question uses has sources', () {
      // Keyed by skill rather than by question — 161 questions would be 161
      // places for a dead URL to hide, and the honest answer is the same for
      // all questions on a topic. The effect of this test is that adding a
      // question in a new topic area forces its author to say where the
      // answer comes from.
      final used = allQuizQuestions.map((q) => q.skillId).toSet();
      final missing = used
          .where((skill) => (kQuizSkillSources[skill] ?? const []).isEmpty)
          .toList()
        ..sort();
      expect(missing, isEmpty, reason: 'unsourced quiz skills: $missing');
    });

    test('every quiz source resolves', () {
      final broken = <String>[];
      kQuizSkillSources.forEach((skill, ids) {
        for (final id in ids) {
          if (!kLessonSources.containsKey(id)) {
            broken.add('$skill cites unknown source "$id"');
          }
        }
      });
      expect(broken, isEmpty, reason: broken.join(', '));
    });

    test('no quiz source table entry is for a skill nothing uses', () {
      final used = allQuizQuestions.map((q) => q.skillId).toSet();
      final stale = kQuizSkillSources.keys
          .where((skill) => !used.contains(skill))
          .toList()
        ..sort();
      expect(stale, isEmpty, reason: 'sources for unused skills: $stale');
    });
  });

  group('the depth pass', () {
    test('every lesson has at least one deep dive', () {
      // The other half of the brief: the lessons were too short. This is the
      // floor, not the target.
      final shallow = lessons
          .where((lesson) => (kLessonDeepDives[lesson.id] ?? const []).isEmpty)
          .map((lesson) => lesson.id)
          .toList();
      expect(shallow, isEmpty, reason: 'no added depth for: $shallow');
    });

    test('deep dives name lessons that exist', () {
      final ids = lessons.map((lesson) => lesson.id).toSet();
      final orphans = kLessonDeepDives.keys
          .where((id) => !ids.contains(id))
          .toList();
      expect(orphans, isEmpty, reason: 'orphaned deep dives: $orphans');
    });

    test('deep dives are substantial, not one-liners', () {
      // A "deep dive" of eight words is a subtitle. The bar is low on
      // purpose — it catches placeholders, not prose style.
      kLessonDeepDives.forEach((lessonId, dives) {
        for (final dive in dives) {
          expect(dive.title, isNotEmpty, reason: lessonId);
          expect(
            dive.content.length,
            greaterThan(120),
            reason: '$lessonId · "${dive.title}" is too short to be a section',
          );
        }
      });
    });

    test('the curriculum grew by a meaningful amount', () {
      // Guards against the depth pass being quietly reverted or half-applied.
      final passages = kLessonDeepDives.values
          .fold<int>(0, (sum, dives) => sum + dives.length);
      expect(
        passages,
        greaterThanOrEqualTo(70),
        reason: 'only $passages added passages across ${lessons.length} lessons',
      );
    });
  });
}
