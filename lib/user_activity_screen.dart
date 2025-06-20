import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_session.dart'; // 🔄 Tambahkan ini untuk akses session global

class UserActivityScreen extends StatelessWidget {
  const UserActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = UserSession.userDocId;
    final username = UserSession.username;

    return Scaffold(
      appBar: AppBar(
        title: Text('Aktivitas $username'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activity_log')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: \${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada aktivitas.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final activity = data['activity'] ?? 'Aktivitas tidak diketahui';
              final timestampRaw = data['timestamp'];

              DateTime? timestamp;
              if (timestampRaw is Timestamp) {
                timestamp = timestampRaw.toDate();
              }

              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(activity),
                subtitle: Text(
                  timestamp != null
                      ? '${timestamp.toLocal()}'
                      : 'Waktu belum tercatat',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
