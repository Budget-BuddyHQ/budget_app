/// Leak Patrol is unlocked by owning the Mushroom Goomba.
///
/// # Why this game and not another
///
/// Asked for directly: *"when they unlock the mushroom goomba only then they
/// can play it"*.
///
/// It is also the right fit rather than an arbitrary pairing. Leak Patrol
/// exists in part to give that skin a job — it had been in the catalogue,
/// buyable and equippable, with an 8-frame walk cycle reached only by
/// `AvatarSkin.walkFrames`, a method with **no callers anywhere**. The sprite
/// existed and had never animated once. The creatures that come out of the
/// holes are built from it.
///
/// So the lock is not a toll gate on a game somebody would otherwise play. It
/// is the game *being about* the thing you unlocked, which is the only kind
/// of lock worth having: winning the Goomba now hands you something to do
/// with it rather than a picture for your profile.
///
/// # Why owning it, not equipping it
///
/// Requiring it to be equipped would mean taking off whatever skin you like
/// in order to play, every time. Owning is the achievement; wearing is a
/// preference, and tying a mode to a preference is how you teach people to
/// resent both.
///
/// # How you get it
///
/// It is an epic in the skin case, and anyone can also buy it outright with
/// `buySkinDirectly` for the same gold. So the lock is reachable without
/// anybody having to gamble for it.
library;

const String kLeakPatrolSkinId = 'mushroom_goomba';

/// Whether this player may open Leak Patrol.
bool leakPatrolUnlocked(Iterable<String> ownedSkinIds) =>
    ownedSkinIds.contains(kLeakPatrolSkinId);

/// What the locked card says.
///
/// Names the skin and where to get it. A lock that only says "locked" reads
/// as a bug and teaches nothing about how to open it — the same rule the town
/// building locks follow in `town_unlocks.dart`.
const String kLeakPatrolLockHint =
    'Unlock the Mushroom Goomba in Customize to play. This whole game is '
    'built out of that sprite.';
