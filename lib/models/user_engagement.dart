import 'user_profile.dart';
import 'visit.dart';

class UserEngagement {
  final UserProfile profile;
  final int visitCount;
  final double avgSessionMinutes;
  final DateTime? lastVisit;
  final double engagementScore;

  UserEngagement({
    required this.profile,
    required this.visitCount,
    required this.avgSessionMinutes,
    required this.lastVisit,
    required this.engagementScore,
  });

  factory UserEngagement.fromData(UserProfile profile, List<Visit> userVisits) {
    final int visitCount = userVisits.length;
    
    final durations = userVisits.where((v) => v.durationSeconds != null).map((v) => v.durationSeconds!);
    final double avgSessionMinutes = durations.isEmpty 
        ? 0 
        : (durations.reduce((a, b) => a + b) / durations.length) / 60.0;

    DateTime? lastVisit;
    if (userVisits.isNotEmpty) {
      userVisits.sort((a, b) => (b.lastUpdate ?? b.timestamp ?? DateTime(2000)).compareTo(a.lastUpdate ?? a.timestamp ?? DateTime(2000)));
      lastVisit = userVisits.first.lastUpdate ?? userVisits.first.timestamp;
    }

    // Engagement Score formülü: (Ziyaret Sayısı * 2) + (Ort. Oturum Dakikası * 1.5)
    final double score = (visitCount * 2.0) + (avgSessionMinutes * 1.5);

    return UserEngagement(
      profile: profile,
      visitCount: visitCount,
      avgSessionMinutes: avgSessionMinutes,
      lastVisit: lastVisit,
      engagementScore: score,
    );
  }
}
