import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final CollectionReference _realtimeData =
      FirebaseFirestore.instance.collection('realtime_data');

  Future<Map<String, dynamic>?> getLatestRealtimeData() async {
    final snapshot = await _realtimeData
        .orderBy('tanggal', descending: true)
        .orderBy('waktu', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data() as Map<String, dynamic>;
    } else {
      return null;
    }
  }
}
