# Budget Buddy Patch Notes

## April 6, 2026

### Navigation + MVP Layout
- Reworked the main shell into a cleaner 5-tab flow: `Dashboard`, `Game Hub`, `Customize`, `Lessons`, and `Profile`.
- Updated the bottom navigation to a simpler glassmorphic bar that is easier to scan on mobile.
- Added direct routes for `/hub`, `/customize`, and `/lessons`.

### Dashboard
- Refreshed the home dashboard with a turtle-led welcome header.
- Added a larger Daily Challenge hero card with quick access to the featured battle and the Game Hub.
- Added a dedicated literacy progress card and a simplified global leaderboard preview.

### Game Hub
- Replaced the old Town Square role with a new 3x3 `GameHubScreen`.
- Wired `Bill Dodger`, `Budget Battle`, and `Budget Sprint`.
- Added placeholder slots for `Prodigy Demo`, `Grocery Rush`, and future June MVP minigames.

### Customize System
- Added a new `CustomizeScreen` with turtle preview, unlock inventory, and equip flow.
- Added Emerald Case opening with weighted rarity rolls: Common, Rare, and Epic.
- Added duplicate protection behavior with a gold rebate.
- Synced unlocked skins and equipped skin through the shared user stats save path.

### Profile
- Simplified the profile tab into a cleaner settings list for Notifications, Sound, and Account.
- Kept the logout flow functional with full session reset and navigation back to the auth screen.

### Data + Sync
- Extended the user stats model to persist:
  - equipped skin
  - unlocked skins
- Stored these values inside the existing Supabase-backed `spending_habits` payload for compatibility with the current backend shape.

### Notes
- `bill_dodger.dart` gameplay logic was left untouched in this patch.
- `BudgetPage` and older financial screens remain in the repo, but the primary MVP navigation now routes through the new dashboard/game hub/customize structure.
