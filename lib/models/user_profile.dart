import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String? originalName;
  final int? age;
  final DateTime? registrationDate;
  final String? platform;
  final String? appId;
  final String? appVersion;
  final DateTime? createdAt;
  final bool? isMigrated;

  UserProfile({
    required this.id,
    this.originalName,
    this.age,
    this.registrationDate,
    this.platform,
    this.appId,
    this.appVersion,
    this.createdAt,
    this.isMigrated,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Fallback logic for field names with safe parsing
    final String? pAppVersion = data['lastVersion']?.toString() ?? data['appVersion']?.toString();
    
    final DateTime? pRegDate = _parseDate(data['registrationDate']) ?? _parseDate(data['lastVisit']);
    final DateTime? pCreatedAt = _parseDate(data['createdAt']) ?? pRegDate;

    return UserProfile(
      id: doc.id,
      originalName: data['originalName']?.toString() ?? data['name']?.toString(),
      age: data['age'] is int ? data['age'] as int : null,
      registrationDate: pRegDate,
      platform: data['platform']?.toString(),
      appId: data['appId']?.toString(),
      appVersion: pAppVersion,
      createdAt: pCreatedAt,
      isMigrated: data['isMigrated'] as bool? ?? (data.containsKey('appId')),
    );
  }
}
