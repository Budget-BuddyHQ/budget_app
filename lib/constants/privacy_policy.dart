/// The one place that knows which privacy policy is current.
///
/// **Why a version and not just a link.** Google Play wants a policy you can
/// reach from the store listing *and* from inside the app, and it wants the
/// account-creation step to be honest about what is being agreed to. A bare
/// URL does none of that on its own: without a version, an updated policy is
/// something existing players are silently held to, and there is no way to
/// tell who agreed to what.
///
/// So acceptance is recorded as a version plus a timestamp, and [current] is
/// what a recorded acceptance is compared against. Bump it whenever the policy
/// changes in a way that affects what is collected, and everybody is asked
/// again.
library;

/// Where the policy is published.
///
/// Hosted on the Budget Buddy marketing site (Vercel), not the Supabase
/// `pages` edge function that still serves the password-reset landing page.
/// That function's copy of this policy still had a placeholder contact
/// address (`[ADD A CONTACT ADDRESS BEFORE PUBLISHING]`); the marketing
/// site's `/policy` route is the one with a real address filled in
/// (`budgetbuddyhq@gmail.com`), so it is the one the store listing and the
/// in-app link should both point at.
const String kPrivacyPolicyUrl = 'https://budget-buddy-website-one.vercel.app/policy';

/// The version a player is agreeing to when they tick the box.
///
/// Date-based rather than a counter, so the version *is* the answer to "which
/// policy is this" without anybody having to look it up. Must match the
/// `Last updated` line in `docs/PRIVACY_POLICY.md` and the published page —
/// `privacy_policy_test.dart` fails the build if the three ever disagree.
const String kPrivacyPolicyVersion = '2026-09-01';

/// Human-readable form of [kPrivacyPolicyVersion], for the acceptance row.
const String kPrivacyPolicyDate = '1 September 2026';

/// Keys the acceptance is stored under, inside the player's synced profile.
///
/// In `spending_habits` with everything else rather than in a column of its
/// own: it syncs, it survives a reinstall, and it costs no migration. The
/// trade is that it is not queryable as a column — acceptable, because the
/// question this answers is always about one specific player.
abstract final class PrivacyKeys {
  static const String acceptedVersion = 'privacy_accepted_version';
  static const String acceptedAt = 'privacy_accepted_at';
}
