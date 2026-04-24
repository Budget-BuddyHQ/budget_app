import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final supabase = Supabase.instance.client;

  bool showDeleted = false;

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final query = supabase
        .from('profiles')
        .select('id, email, role, disabled, user_stats(gold, xp)');

    final data = showDeleted
        ? await query.eq('disabled', true)
        : await query.or('disabled.is.null,disabled.eq.false');

    return List<Map<String, dynamic>>.from(data);
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
    final newRole = currentRole == 'admin' ? 'user' : 'admin';

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

  @override
  Widget build(BuildContext context) {
    final currentUser = supabase.auth.currentUser;

    if (currentUser?.email != 'brucksheferaw@gmail.com') {
      return const Scaffold(
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
              final role = user['role'] ?? 'user';

              final stats = user['user_stats'];
              final gold = stats != null ? stats['gold'] ?? 0 : 0;
              final xp = stats != null ? stats['xp'] ?? 0 : 0;

              return ListTile(
                title: Text(
                  user['email'] ?? 'No email',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Role: $role | Gold: $gold | XP: $xp',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!showDeleted)
                      ElevatedButton(
                        onPressed: () => _toggleRole(user['id'], role),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                        ),
                        child: Text(
                          role == 'admin' ? 'Make User' : 'Make Admin',
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (!showDeleted &&
                        role != 'admin' &&
                        user['id'] != currentUser?.id)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () => _confirmDelete(user['id']),
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
                        onPressed: () => _restoreUser(user['id']),
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
  }
}