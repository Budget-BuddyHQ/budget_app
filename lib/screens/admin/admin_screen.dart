import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFF0A211A),
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder(
        future: supabase.from('profiles').select(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data as List;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                title: Text(
                  user['email'] ?? 'No email',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Role: ${user['role']}',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          );
        },
      ),
    );
  }
}