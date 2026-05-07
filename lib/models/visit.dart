import 'package:cloud_firestore/cloud_firestore.dart';

class Visit {
  final String id;
  final String userId; 
  final int? durationSeconds;
  final DateTime? lastUpdate;
  final String? appVersion;
  final String? platform;
  final DateTime? timestamp;
  final String? appId; 

  Visit({
    required this.id,
    required this.userId,
    this.durationSeconds,
    this.lastUpdate,
    this.appVersion,
    this.platform,
    this.timestamp,
    this.appId,
  });

  factory Visit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // In collectionGroup queries, we can get parent userId from reference if structured as users/{userId}/visits
    String parsedUserId = '';
    if (doc.reference.parent.parent != null) {
      parsedUserId = doc.reference.parent.parent!.id;
    }

    return Visit(
      id: doc.id,
      userId: parsedUserId,
      durationSeconds: data['durationSeconds'] as int?,
      lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate(),
      appVersion: data['appVersion']?.toString(),
      platform: data['platform']?.toString(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      appId: data['appId']?.toString(),
    );
  }
}
