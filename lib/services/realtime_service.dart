// lib/services/realtime_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RealtimeService {
  final _collection = FirebaseFirestore.instance.collection('realtime_data');

  Future<Map<String, dynamic>?> fetchLatestData() async {
    final snapshot = await _collection.orderBy('tanggal', descending: true).limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    } else {
      return null;
    }
  }
}
