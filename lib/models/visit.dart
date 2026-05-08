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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory Visit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    String parsedUserId = '';
    if (doc.reference.parent.parent != null) {
      parsedUserId = doc.reference.parent.parent!.id;
    }

    return Visit(
      id: doc.id,
      userId: parsedUserId,
      durationSeconds: data['durationSeconds'] as int?,
      lastUpdate: _parseDate(data['lastUpdate']),
      appVersion: data['appVersion']?.toString(),
      platform: data['platform']?.toString(),
      timestamp: _parseDate(data['timestamp']),
      appId: data['appId']?.toString(),
    );
  }
}
