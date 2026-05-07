import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String? originalName;
  final int? age;
  final DateTime? registrationDate;
  final String? platform;
  final String? appId;
  final String? appVersion; // Eklendi
  final DateTime? createdAt;
  final bool? isMigrated;

  UserProfile({
    required this.id,
    this.originalName,
    this.age,
    this.registrationDate,
    this.platform,
    this.appId,
    this.appVersion, // Eklendi
    this.createdAt,
    this.isMigrated,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Fallback logic for field names
    final String? pAppVersion = data['lastVersion']?.toString() ?? data['appVersion']?.toString();
    final DateTime? pRegDate = (data['registrationDate'] as Timestamp?)?.toDate() ?? (data['lastVisit'] as Timestamp?)?.toDate();
    final DateTime? pCreatedAt = (data['createdAt'] as Timestamp?)?.toDate() ?? pRegDate;

    return UserProfile(
      id: doc.id,
      originalName: data['originalName']?.toString() ?? data['name']?.toString(),
      age: data['age'] is int ? data['age'] as int : null,
      registrationDate: pRegDate,
      platform: data['platform']?.toString(),
      appId: data['appId']?.toString(),
      appVersion: pAppVersion,
      createdAt: pCreatedAt,
      isMigrated: data['isMigrated'] as bool? ?? (data.containsKey('appId')), // appId varsa yeni sistemle bir bağ kurmuştur
    );
  }
}
