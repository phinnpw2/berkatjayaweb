import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> logActivity({
  required String userId,
  required String username,
  required String activity,
}) async {
  await FirebaseFirestore.instance.collection('activity_log').add({
    'userId': userId,
    'username': username,
    'activity': activity,
    'timestamp': FieldValue.serverTimestamp(),
  });
}
