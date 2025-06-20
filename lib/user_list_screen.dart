import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_activity_screen.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Akun'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('user').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Tidak ada akun terdaftar'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userId = user.id;
              final username = user['username'];
              final role = user['role'];

              return ListTile(
                title: Text(username),
                subtitle: Text('Role: $role'),
                trailing: Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserActivityScreen(
                      userId: userId,
                      username: username,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class UserActivityScreen extends StatelessWidget {
  final String userId;
  final String username;

  const UserActivityScreen({super.key, required this.userId, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aktivitas $username'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activity_log')
            .where('userId', isEqualTo: userId)
            .where('timestamp', isGreaterThan: DateTime(2000))
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Belum ada aktivitas.'));
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final data = logs[index];
              final activity = data['activity'];
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return ListTile(
                leading: Icon(Icons.history),
                title: Text(activity),
                subtitle: Text(timestamp != null ? '${timestamp.toLocal()}' : 'Waktu tidak tersedia'),
              );
            },
          );
        },
      ),
    );
  }
}
