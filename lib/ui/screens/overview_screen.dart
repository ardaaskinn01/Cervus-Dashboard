import 'package:flutter/material.dart';
import '../../models/visit.dart';
import '../../models/user_profile.dart';
import '../../models/date_filter.dart';
import '../../services/dashboard_service.dart';
import '../widgets/kpi_card.dart';
import '../../theme/app_theme.dart';

class OverviewScreen extends StatelessWidget {
  final DateFilter dateFilter;
  final String appIdFilter;

  const OverviewScreen({super.key, required this.dateFilter, required this.appIdFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Visit>>(
      stream: DashboardService().getVisitsStream(),
      builder: (context, visitSnapshot) {
        return StreamBuilder<List<UserProfile>>(
          stream: DashboardService().getProfilesStream(),
          builder: (context, profileSnapshot) {
            if (visitSnapshot.connectionState == ConnectionState.waiting || 
                profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final visits = visitSnapshot.data ?? [];
            final profiles = profileSnapshot.data ?? [];

            // 1. Filtrleme (AppId)
            var fVisits = appIdFilter == 'Hepsi' ? visits : visits.where((v) => v.appId == appIdFilter).toList();
            var fProfiles = appIdFilter == 'Hepsi' ? profiles : profiles.where((p) => p.appId == appIdFilter).toList();

            // 2. Filtreleme (Tarih)
            fVisits = fVisits.where((v) => _isWithinDate(v.lastUpdate ?? v.timestamp, dateFilter)).toList();
            fProfiles = fProfiles.where((p) => _isWithinDate(p.createdAt, dateFilter)).toList();

            // 3. Hesaplamalar
            final totalVisits = fVisits.length;
            final totalNewUsers = fProfiles.length;
            final activeUsers = fVisits.map((v) => v.userId).toSet().length;
            
            final validDurations = fVisits.where((v) => v.durationSeconds != null).map((v) => v.durationSeconds!);
            final avgDuration = validDurations.isEmpty ? 0 : validDurations.reduce((a, b) => a + b) / validDurations.length;

            final iosVisits = fVisits.where((v) => v.platform?.toLowerCase() == 'ios').length;
            final androidVisits = fVisits.where((v) => v.platform?.toLowerCase() == 'android').length;

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Sistem Özeti', 'Seçili döneme ait kritik performans göstergeleri.'),
                    const SizedBox(height: 16),
                    
                    // Ana KPI Kartları
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _kpi(300, 'Toplam Ziyaret', totalVisits.toString(), Icons.analytics, Colors.blueAccent),
                        _kpi(300, 'Yeni Kayıt', totalNewUsers.toString(), Icons.person_add_alt_1, Colors.greenAccent),
                        _kpi(300, 'Aktif Kullanıcı', activeUsers.toString(), Icons.visibility, Colors.orangeAccent),
                        _kpi(300, 'Ort. Oturum', '${(avgDuration / 60).toStringAsFixed(1)} Dk', Icons.av_timer, Colors.purpleAccent),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Cihaz ve Platform Dağılımı', 'Kullanıcıların hangi işletim sistemlerini tercih ettiği.'),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _buildPlatformBox('iOS', iosVisits, totalVisits, Icons.apple, Colors.white70),
                        const SizedBox(width: 20),
                        _buildPlatformBox('Android', androidVisits, totalVisits, Icons.android, Colors.greenAccent),
                      ],
                    ),

                    const SizedBox(height: 48),
                    _buildSectionHeader('Uygulama Bazlı Performans', 'Projelerinizin güncel trafik durumu.'),
                    const SizedBox(height: 24),

                    // Uygulama Listesi
                    Container(
                      width: double.infinity,
                      decoration: AppTheme.glassDecoration,
                      child: Column(
                        children: [
                          _appRow('Quitly', fVisits.where((v) => v.appId == 'quitly').length, Colors.cyanAccent),
                          _appRow('Alarmly', fVisits.where((v) => v.appId == 'alarmly').length, Colors.redAccent),
                          _appRow('Drinkly', fVisits.where((v) => v.appId == 'drinkly').length, Colors.blueAccent),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isWithinDate(DateTime? target, DateFilter dateFilter) {
    if (target == null) return false;
    if (dateFilter.type == DateFilterType.allTime) return true;
    if (dateFilter.type == DateFilterType.daily) {
      return target.year == dateFilter.date.year && target.month == dateFilter.date.month && target.day == dateFilter.date.day;
    } else {
      return target.year == dateFilter.date.year && target.month == dateFilter.date.month;
    }
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    );
  }

  Widget _kpi(double w, String t, String v, IconData i, Color c) {
    return SizedBox(width: w, child: KpiCard(title: t, value: v, icon: i, iconColor: c));
  }

  Widget _buildPlatformBox(String label, int count, int total, IconData icon, Color color) {
    final double percent = total == 0 ? 0 : (count / total) * 100;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text('%${percent.toStringAsFixed(1)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: percent / 100, backgroundColor: Colors.white10, color: color, minHeight: 6),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54)),
                Text('$count Ziyaret', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _appRow(String name, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 16),
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('$count Ziyaret', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
        ],
      ),
    );
  }
}
