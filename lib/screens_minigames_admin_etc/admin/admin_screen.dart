import 'package:google_fonts/google_fonts.dart';
import '../../services_backend_and_other_services/supabase_service.dart';
  // Null when Supabase was never initialized (no keys configured) — the
  // rest of this screen checks for that via _canAccessAdminPanel() rather
  // than crashing on a bare Supabase.instance access.
  final SupabaseClient? supabase = SupabaseService.instance.client;
    final client = supabase;
    if (client == null) {
      return const <Map<String, dynamic>>[];
    }
    final profilesQuery = client
      final statsData = await client
        .map((user) {
          final userId = user['id']?.toString();
          final email = user['email']?.toString().trim().toLowerCase();
          Map<String, dynamic>? stats;

          if (userId != null && userId.isNotEmpty) {
            stats = statsByUserId[userId];
          }

          if (stats == null && email != null && email.isNotEmpty) {
            final legacyId = SupabaseService.legacyUserIdFromEmail(email);
            stats = statsByLegacyId[legacyId] ?? statsByEmail[email];
          }

          return <String, dynamic>{...user, 'user_stats': stats};
        })
    // Only ever called from a button that's already past the
    // _canAccessAdminPanel gate, which requires supabase to be non-null.
    await supabase!.from('profiles').update({'role': newRole}).eq('id', userId);
    await supabase!.from('profiles').update({'disabled': true}).eq('id', userId);
    await supabase!
    final client = supabase;
    if (client == null) {
      return false;
    }
    final user = client.auth.currentUser;
    final currentUser = supabase?.auth.currentUser;
          return Scaffold(
            backgroundColor: const Color(0xFF0A211A),
                style: GoogleFonts.quicksand(color: Colors.white),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
                return Center(
                    style: GoogleFonts.quicksand(color: Colors.white),
  const _AdminErrorState({required this.message, required this.onRetry});
