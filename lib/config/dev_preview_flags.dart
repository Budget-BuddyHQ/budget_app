// TEMPORARY LOCAL-ONLY DEV FLAG — DO NOT COMMIT AS true.
//
// When true, the Supabase auth gate in main.dart is skipped so the app
// boots straight to the dashboard without a real login. This exists only
// to preview UI locally without signing in. Flip back to false (or delete
// this file and its call site in main.dart) before pushing anything.
const bool kDevSkipAuthGate = true;

// Shows an internal "Dev Tools" card on the Profile screen linking to
// reference/preview screens (e.g. the coded turtle sprite gallery). Not a
// security boundary — just keeps dev-only reference UI out of the way for
// everyday use. Safe to leave true; flip off if you want a clean Profile
// screen for a demo or screenshots.
const bool kShowDevTools = true;
