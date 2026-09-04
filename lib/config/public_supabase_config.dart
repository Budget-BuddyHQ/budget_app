// GENERATED FILE — do not edit by hand.
// Regenerate with: python tool/write_public_config.py
//
// **These two values are public on purpose, and this file is committed.**
//
// `SUPABASE_ANON_KEY` is not a password. It identifies the project and
// nothing more; every row it can reach is guarded by row-level security, and
// Supabase publishes it in their own client examples — it is designed to live
// in a browser bundle where anybody can read it.
//
// Baking it in is what makes a plain `flutter build` produce a working app.
// Before this, the only source that survived onto a phone was
// `--dart-define`, so a release built without the right flags shipped with no
// Supabase config at all: sign-in did nothing, the Market Board had no proxy,
// and friends could not load. It worked on a laptop only because
// `supabase.env.json` happens to sit in the project folder.
//
// **The market API keys are deliberately absent.** Finnhub and Twelve Data
// credentials are rate-limited and tied to a personal account, and anything
// in an APK can be recovered with `strings`. They live as Supabase secrets on
// the `market` edge function, which is the whole reason that function exists.
// `tool/write_public_config.py` refuses to write them here.
//
// These are still the *lowest* priority source — an environment variable or a
// `--dart-define` overrides them, so a different build can point at a
// different project without touching this file.
library;

const Map<String, String> kPublicSupabaseConfig = <String, String>{
  'SUPABASE_URL': 'https://cwqjduingvevagrxbwts.supabase.co',
  'SUPABASE_ANON_KEY':
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3cWpkdWluZ3ZldmFncnhid3RzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1MTQ4OTEsImV4cCI6MjA5MTA5MDg5MX0.XIHeR4oRiwJHCjRj9XDr-2by_6YY67YolSxeggdgDdc',
};
