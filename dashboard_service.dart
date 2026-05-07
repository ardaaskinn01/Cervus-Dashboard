import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardService with WidgetsBindingObserver {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  FirebaseApp? _dashboardApp;
  FirebaseFirestore? _firestore;
  bool _isInitialized = false;

  // Oturum takibi değişkenleri
  DateTime? _sessionStartTime;
  String? _currentUserId;
  String? _currentVisitId;
  int _totalSecondsThisSession = 0;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 🎯 YENİ PROJE BİLGİLERİ (dashboard-baf3f)
      _dashboardApp = Firebase.apps.any((app) => app.name == 'dashboard')
          ? Firebase.app('dashboard')
          : await Firebase.initializeApp(
              name: 'dashboard',
              options: const FirebaseOptions(
                apiKey: "AIzaSyBPOS5L2Qdoi0kVXgyQnCoWuAdbUfh_YAo",
                authDomain: "dashboard-baf3f.firebaseapp.com",
                projectId: "dashboard-baf3f",
                storageBucket: "dashboard-baf3f.firebasestorage.app",
                messagingSenderId: "607527844560",
                appId: "1:607527844560:web:2415525d9fa986fdc03cd5", // Web/Universal ID
                measurementId: "G-5CN9G1FZ0B",
              ),
            );

      _firestore = FirebaseFirestore.instanceFor(app: _dashboardApp!);
      _isInitialized = true;
      
      if (WidgetsBinding.instance.lifecycleState != null) {
        WidgetsBinding.instance.addObserver(this);
      } else {
        // Observers only work when the binding is fully set up
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addObserver(this);
        });
      }
      
      debugPrint('✅ Merkezi Dashboard Projesi Bağlandı (ID: dashboard-baf3f)');
    } catch (e) {
      debugPrint('❌ Dashboard Başlatma Hatası: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _updateCurrentSessionDuration();
    } else if (state == AppLifecycleState.resumed) {
      _sessionStartTime = DateTime.now();
    }
  }

  void startSession(String userId, String visitId) {
    _currentUserId = userId;
    _currentVisitId = visitId;
    _sessionStartTime = DateTime.now();
    _totalSecondsThisSession = 0;
  }

  Future<void> _updateCurrentSessionDuration() async {
    if (_sessionStartTime == null || _currentUserId == null || _currentVisitId == null) return;

    final now = DateTime.now();
    final int elapsedSeconds = now.difference(_sessionStartTime!).inSeconds;
    _totalSecondsThisSession += elapsedSeconds;
    _sessionStartTime = now;

    try {
      await _firestore!
          .collection('users')
          .doc(_currentUserId)
          .collection('visits')
          .doc(_currentVisitId)
          .update({
        'durationSeconds': _totalSecondsThisSession,
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Süre Kaydı Hatası: $e');
    }
  }

  FirebaseFirestore? get firestore => _firestore;
  bool get isInitialized => _isInitialized;

  // SYNC METODU (Eski kullanıcıları çekmek için)
  Future<void> syncExistingUser(String userId, Map<dynamic, dynamic> userData) async {
    if (!_isInitialized || _firestore == null) return;
    try {
      final userDoc = await _firestore!.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        await _firestore!.collection('users').doc(userId).set({
          'originalName': userData['originalName'],
          'age': userData['age'],
          'registrationDate': userData['registrationDate'] is String 
              ? Timestamp.fromDate(DateTime.parse(userData['registrationDate']))
              : userData['registrationDate'],
          'platform': Platform.isIOS ? 'iOS' : 'Android',
          'appId': 'quitly', // 👈 Diğer uygulamalarda burayı 'alarmly' vb. değiştirin
          'isMigrated': true,
          'migratedAt': FieldValue.serverTimestamp(),
          'createdAt': userData['registrationDate'] is String 
              ? Timestamp.fromDate(DateTime.parse(userData['registrationDate']))
              : userData['registrationDate'],
        });
      }
    } catch (e) {
      debugPrint('⚠️ Sync Hatası: $e');
    }
  }
}
