/// When each town encounter starts being offered.
///
/// **The problem.** `townEncounterFor` already mixes the character's age into
/// which scene a building shows, so walking into the bank at seven and at
/// seventy gets you different conversations. What it did *not* do is care
/// which conversations are plausible at seven — it picked uniformly from
/// everything the building had. So a six-year-old could be handed
/// `pawn_quick_cash` ("rent is short by \$70 and payday is nine days away"),
/// `bank_overdraft_fee`, or a room-share advert. The variety was real and the
/// world it implied was nonsense.
///
/// That is worse than a repetitive town, because it quietly contradicts the
/// thing the rest of the simulation is careful about. `OutingPermission`
/// already refuses to let a small child leave the house alone, and
/// `life_age_gates` already refuses to offer a job to a nine-year-old. A town
/// that then asks that child how they are covering rent undoes both.
///
/// **Why a side-table rather than a field on [TownScenario].** `kTownScenarios`
/// is a two-thousand-line `const` map, and adding an argument to fifty-seven
/// entries is fifty-seven chances to put a number on the wrong scenario while
/// reviewing a diff nobody can read. Keeping the ages in one sorted list makes
/// the *policy* reviewable in one screen — which is the thing that actually
/// needs checking — and it is the same shape `kTownScenarios` itself already
/// uses to extend `kTownSpots` from outside.
///
/// **Anything absent is available at any age**, which is the right default:
/// most of these are about a shop, a snack or a bus fare and are exactly as
/// true at eight as at twenty-eight. Only the ones that presuppose a job, a
/// tenancy, a bank account or a bill are held back.
library;

/// Minimum character age per scenario id. Absent means "any age".
///
/// Three bands, and the reasoning is deliberately conservative — the cost of
/// gating a scene too late is a player who never sees it, and the cost of
/// gating too early is a nine-year-old being asked about overdraft coverage.
///
/// * **13** — has pocket money of their own, a phone, and can be sold to. Old
///   enough for scams aimed at teenagers and for a first job to be on the
///   horizon.
/// * **16** — old enough to have that job, a payslip and a bank account they
///   actually operate. `OutingPermission` frees everybody at 16 too, so it is
///   already the age this world treats as the start of independence.
/// * **18** — signing for things. Rent, credit, bills in your own name.
const Map<String, int> kTownScenarioMinAge = <String, int>{
  // --- 13: money of your own, and people trying to get it ---------------
  'store_subscription': 13, // a monthly membership is a standing commitment
  'school_average': 13, // careers advice, and the mean-vs-median trick in it
  'home_subscriptions': 13,
  'library_money_talk': 13, // "understanding your payslip"
  'notice_text_scam': 13,
  'notice_scam': 13,
  'notice_job_ad': 13, // the one that asks for your bank details
  'pawn_phone_value': 13, // depreciation, learned on your own phone
  'cafe_round': 13, // splitting a bill with friends, unsupervised

  // --- 16: employed, and banked ----------------------------------------
  'job_first_payslip': 16,
  'job_tips_week': 16,
  'job_ask_for_more': 16,
  'job_two_offers': 16,
  'job_paystub': 16,
  'bank_auto_save': 16,
  'bank_atm_fee': 16,
  'pawn_ring': 16,
  'clinic_sick_day': 16, // costs a day's pay, which needs there to be pay

  // --- 18: your name on the paperwork ----------------------------------
  'bank_overdraft': 18,
  'bank_overdraft_fee': 18,
  'home_bill_spike': 18,
  'home_bills': 18,
  'home_repair_or_replace': 18,
  'clinic_bill_shock': 18,
  'pawn_quick_cash': 18, // rent short, payday nine days away
  'notice_room_share': 18,
};

/// The age [scenarioId] becomes available. Unlisted scenarios are for anyone.
int townScenarioMinAge(String scenarioId) =>
    kTownScenarioMinAge[scenarioId] ?? 0;
