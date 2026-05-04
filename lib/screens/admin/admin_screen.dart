import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final supabase = Supabase.instance.client;

  bool showDeleted = false;

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final profilesQuery = supabase
        .from('profiles')
        .select('id, email, role, disabled');

    final profilesData = showDeleted
        ? await profilesQuery.eq('disabled', true)
        : await profilesQuery.or('disabled.is.null,disabled.eq.false');

    final users = List<Map<String, dynamic>>.from(profilesData);
    if (users.isEmpty) {
      return users;
    }

    final statsByUserId = <String, Map<String, dynamic>>{};
    final statsByLegacyId = <String, Map<String, dynamic>>{};
    final statsByEmail = <String, Map<String, dynamic>>{};
    try {
      final statsData = await supabase
          .from(SupabaseService.userStatsTable)
          .select('id, username, gold, xp, spending_habits');
      for (final stats in List<Map<String, dynamic>>.from(statsData)) {
        final statsId = stats['id']?.toString();
        if (statsId != null && statsId.isNotEmpty) {
          statsByUserId[statsId] = stats;
          statsByLegacyId[statsId] = stats;
        }

        final habits = stats['spending_habits'];
        if (habits is Map) {
          final email = habits['email']?.toString().trim().toLowerCase();
          if (email != null && email.isNotEmpty) {
            statsByEmail[email] = stats;
            statsByLegacyId[SupabaseService.legacyUserIdFromEmail(email)] =
                stats;
          }
        }
      }
    } catch (error) {
      debugPrint('Admin stats lookup failed: $error');
    }

    return users
        .map(
          (user) {
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

            return <String, dynamic>{
              ...user,
              'user_stats': stats,
            };
          },
        )
        .toList(growable: false);
  }

  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = _fetchUsers();
    });
  }

  Future<void> _toggleRole(String userId, String currentRole) async {
    final newRole = currentRole.trim().toLowerCase() == 'admin'
        ? 'user'
        : 'admin';

    await supabase
        .from('profiles')
        .update({'role': newRole})
        .eq('id', userId);

    _refresh();
  }

  Future<void> _deleteUser(String userId) async {
    await supabase
        .from('profiles')
        .update({'disabled': true})
        .eq('id', userId);

    _refresh();
  }

  Future<void> _restoreUser(String userId) async {
    await supabase
        .from('profiles')
        .update({'disabled': false})
        .eq('id', userId);

    _refresh();
  }

  Future<void> _confirmDelete(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteUser(userId);
    }
  }

  Future<bool> _canAccessAdminPanel() async {
    final user = supabase.auth.currentUser;
    if (SupabaseService.hasAdminMetadata(user) ||
        SupabaseService.isKnownAdminEmail(user?.email)) {
      return true;
    }
    final profile = await SupabaseService.instance.getCurrentUserProfile();
    return profile?.isAdmin ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = supabase.auth.currentUser;

    return FutureBuilder<bool>(
      future: _canAccessAdminPanel(),
      builder: (context, accessSnapshot) {
        if (accessSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A211A),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (accessSnapshot.data != true) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A211A),
            body: Center(
              child: Text(
                'Access denied',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A211A),
          appBar: AppBar(
            title: Text(showDeleted ? 'Deleted Users' : 'Admin Panel'),
            backgroundColor: Colors.black,
            actions: [
              IconButton(
                icon: Text(
                  showDeleted ? 'Active' : 'Deleted',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  setState(() {
                    showDeleted = !showDeleted;
                    _usersFuture = _fetchUsers();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refresh,
              ),
            ],
          ),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _usersFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _AdminErrorState(
                  message: 'Unable to load users: ${snapshot.error}',
                  onRetry: _refresh,
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!;

              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final userId = user['id']?.toString() ?? '';
                  final role = (user['role'] ?? 'user').toString();

                  final stats = user['user_stats'];
                  final gold = stats is Map ? stats['gold'] ?? 0 : null;
                  final xp = stats is Map ? stats['xp'] ?? 0 : null;
                  final statsLabel = stats is Map
                      ? 'Gold: $gold | XP: $xp'
                      : 'No stats row';

                  return ListTile(
                    title: Text(
                      user['email'] ?? 'No email',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Role: $role | $statsLabel',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!showDeleted)
                          ElevatedButton(
                            onPressed: userId.isEmpty
                                ? null
                                : () => _toggleRole(userId, role),
                            style: ElevatedButton.styleFrom(elevation: 0),
                            child: Text(
                              role.trim().toLowerCase() == 'admin'
                                  ? 'Make User'
                                  : 'Make Admin',
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (!showDeleted &&
                            role.trim().toLowerCase() != 'admin' &&
                            userId != currentUser?.id)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: userId.isEmpty
                                ? null
                                : () => _confirmDelete(userId),
                            child: const Text('Delete'),
                          ),
                        if (showDeleted)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: userId.isEmpty
                                ? null
                                : () => _restoreUser(userId),
                            child: const Text('Restore'),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  const _AdminErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF8E72),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
