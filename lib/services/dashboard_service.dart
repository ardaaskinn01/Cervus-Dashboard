import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/visit.dart';

class DashboardService {
  // Singleton pattern
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String profilesCollection = 'users';

  // Future to check connection
  Future<bool> checkConnection() async {
    try {
      await _firestore.collection(profilesCollection).limit(1).get();
      return true;
    } catch (e) {
      print('Firebase Connection Error: $e');
      return false;
    }
  }

  // Get stream for all visits using collectionGroup ('users/{userId}/visits')
  Stream<List<Visit>> getVisitsStream() {
    return _firestore
        .collectionGroup('visits')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Visit.fromFirestore(doc)).toList();
    });
  }

  // Get stream for all user profiles
  Stream<List<UserProfile>> getProfilesStream() {
    return _firestore.collection(profilesCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
    });
  }

  // Get stream for a specific user's visits
  Stream<List<Visit>> getUserVisitsStream(String userId) {
    return _firestore
        .collection(profilesCollection)
        .doc(userId)
        .collection('visits')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Visit.fromFirestore(doc)).toList();
    });
  }

  // Futures for one-time fetch
  Future<List<Visit>> getAllVisits() async {
    final querySnapshot = await _firestore.collectionGroup('visits').get();
    return querySnapshot.docs.map((doc) => Visit.fromFirestore(doc)).toList();
  }

  Future<List<UserProfile>> getAllProfiles() async {
    final querySnapshot = await _firestore.collection(profilesCollection).get();
    return querySnapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
  }
}
