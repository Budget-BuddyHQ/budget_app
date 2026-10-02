/// Questions for the Job Board's in-person interview.
///
/// **Why this exists.** Applying for a job from the Occupation tab and
/// applying from the Town's Job Board used to be the exact same roll, so
/// there was never a real reason to make the walk — "the job board hires on
/// the spot" was a line of flavor text describing a bonus nothing actually
/// paid out. This is the thing that makes it true: a short interview with a
/// real answer, scored, and the score raises the odds the Occupation tab
/// alone cannot reach.
///
/// Each question has exactly one best answer, one weak one and one in
/// between, scored 2/1/0, in that fixed order — [InterviewRound] shuffles the
/// *display* order so the right answer is never always the top button.
library;

/// One answer and what it is worth. 2 is the best answer, 0 the worst.
class InterviewAnswer {
  const InterviewAnswer({required this.label, required this.score});

  final String label;
  final int score;
}

/// One interview question and its three answers, best first.
class InterviewQuestion {
  const InterviewQuestion({required this.prompt, required this.answers});

  final String prompt;

  /// Exactly three, ordered worst (0) to best (2) — see [InterviewAnswer].
  final List<InterviewAnswer> answers;
}

const List<InterviewQuestion> kInterviewQuestions = <InterviewQuestion>[
  InterviewQuestion(
    prompt: 'Why do you want this job?',
    answers: [
      InterviewAnswer(label: 'I just need money right now.', score: 0),
      InterviewAnswer(label: 'It seemed easy.', score: 1),
      InterviewAnswer(
        label: "I want to learn the trade, and I'll show up on time.",
        score: 2,
      ),
    ],
  ),
  InterviewQuestion(
    prompt: 'You make a mistake and a customer is upset. What now?',
    answers: [
      InterviewAnswer(label: 'Hope nobody notices.', score: 0),
      InterviewAnswer(label: 'Have a coworker handle it.', score: 1),
      InterviewAnswer(label: 'Apologize and fix it.', score: 2),
    ],
  ),
  InterviewQuestion(
    prompt: 'How would you handle a disagreement with a coworker?',
    answers: [
      InterviewAnswer(label: 'Avoid them for the rest of the shift.', score: 0),
      InterviewAnswer(
        label: 'Complain about them to everyone else.',
        score: 1,
      ),
      InterviewAnswer(label: 'Talk it out directly and calmly.', score: 2),
    ],
  ),
  InterviewQuestion(
    prompt: 'What would you do with your first paycheck?',
    answers: [
      InterviewAnswer(label: 'Spend all of it the same day.', score: 0),
      InterviewAnswer(label: 'Save a little, spend the rest.', score: 1),
      InterviewAnswer(
        label: 'Cover what I owe first, save some, spend the rest.',
        score: 2,
      ),
    ],
  ),
  InterviewQuestion(
    prompt: "You don't know how to do something you're asked to do. "
        'What now?',
    answers: [
      InterviewAnswer(label: 'Fake it and hope it works out.', score: 0),
      InterviewAnswer(label: 'Skip it and hope nobody asks again.', score: 1),
      InterviewAnswer(label: 'Ask how it is done.', score: 2),
    ],
  ),
  InterviewQuestion(
    prompt: 'A coworker asks you to cover for a mistake they made. '
        'What do you do?',
    answers: [
      InterviewAnswer(label: 'Lie for them.', score: 0),
      InterviewAnswer(label: 'Say nothing either way.', score: 1),
      InterviewAnswer(label: 'Tell them to own up to it, honestly.', score: 2),
    ],
  ),
  InterviewQuestion(
    prompt: 'You are told no to a raise. What do you do?',
    answers: [
      InterviewAnswer(label: 'Stop trying as hard.', score: 0),
      InterviewAnswer(label: 'Quit without a plan.', score: 1),
      InterviewAnswer(label: 'Ask what it would take to earn one.', score: 2),
    ],
  ),
  InterviewQuestion(
    prompt: 'The shift runs long and you are tired. What do you do?',
    answers: [
      InterviewAnswer(label: 'Leave without telling anyone.', score: 0),
      InterviewAnswer(label: 'Complain until someone lets you go.', score: 1),
      InterviewAnswer(
        label: 'Finish the shift and mention it afterward.',
        score: 2,
      ),
    ],
  ),
];
