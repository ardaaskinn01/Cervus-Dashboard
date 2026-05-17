import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/visit.dart';
import '../../models/user_profile.dart';
import '../../models/date_filter.dart';
import '../../services/dashboard_service.dart';
import '../widgets/kpi_card.dart';
import '../widgets/scrollable_line_chart_card.dart';
import '../widgets/donut_chart_card.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

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

            // 1. Filtreleme (AppId)
            var fVisits = appIdFilter == 'Hepsi' ? visits : visits.where((v) => v.appId?.toLowerCase() == appIdFilter.toLowerCase()).toList();
            var fProfiles = appIdFilter == 'Hepsi' ? profiles : profiles.where((p) => p.appId?.toLowerCase() == appIdFilter.toLowerCase()).toList();

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
            final otherVisits = totalVisits - iosVisits;

            // Trend Verisi (En eskiden bugüne)
            final trendData = _prepareTrendData(visits, appIdFilter);

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Sistem Özeti', 'Kritik performans göstergeleri.'),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _kpi(250, 'Toplam Ziyaret', totalVisits.toString(), Icons.analytics, Colors.blueAccent),
                        _kpi(250, 'Yeni Kayıt', totalNewUsers.toString(), Icons.person_add_alt_1, Colors.greenAccent),
                        _kpi(250, 'Aktif Kullanıcı', activeUsers.toString(), Icons.visibility, Colors.orangeAccent),
                        _kpi(250, 'Ort. Oturum', '${(avgDuration / 60).toStringAsFixed(1)} Dk', Icons.av_timer, Colors.purpleAccent),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Ziyaret Trendi', 'Son 30 günlük günlük aktiflik grafiği.'),
                    const SizedBox(height: 16),
                    ScrollableLineChartCard(
                      spots: trendData['spots'] as List<FlSpot>,
                      labels: trendData['labels'] as List<String>,
                      title: 'Günlük Ziyaret Trendi',
                      color: AppTheme.primaryColor,
                      tooltipLabel: 'Ziyaret',
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Platform Analizi', 'Cihaz tabanlı kullanım dağılımı.'),
                    const SizedBox(height: 16),
                    DonutChartCard(
                      title: 'Cihaz Dağılımı',
                      data: {
                        'iOS': iosVisits,
                        'Diğer': otherVisits,
                      },
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Uygulama Performansı', 'Uygulama bazlı ziyaret sayıları.'),
                    const SizedBox(height: 16),
                    Container(
                      decoration: AppTheme.glassDecoration,
                      child: Column(
                        children: [
                          _appRow('Alarmly', visits.where((v) => v.appId?.toLowerCase() == 'alarmly').length, Colors.blueAccent),
                          const Divider(color: AppTheme.borderColor, height: 1),
                          _appRow('Quitly', visits.where((v) => v.appId?.toLowerCase() == 'quitly').length, Colors.greenAccent),
                          const Divider(color: AppTheme.borderColor, height: 1),
                          _appRow('Drinkly', visits.where((v) => v.appId?.toLowerCase() == 'drinkly').length, Colors.orangeAccent),
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

  Map<String, dynamic> _prepareTrendData(List<Visit> visits, String appId) {
    final now = DateTime.now();
    final filteredVisits = appId == 'Hepsi' ? visits : visits.where((v) => v.appId?.toLowerCase() == appId.toLowerCase()).toList();

    DateTime earliestDate = filteredVisits.isEmpty 
        ? now.subtract(const Duration(days: 30))
        : filteredVisits.map((v) => v.lastUpdate ?? v.timestamp ?? now).reduce((a, b) => a.isBefore(b) ? a : b);
    
    if (now.difference(earliestDate).inDays < 30) {
      earliestDate = now.subtract(const Duration(days: 30));
    }

    final List<String> labels = [];
    final List<FlSpot> spots = [];
    int dayCount = now.difference(earliestDate).inDays + 1;

    for (int i = 0; i < dayCount; i++) {
      final date = earliestDate.add(Duration(days: i));
      labels.add(DateFormat('dd/MM').format(date));
      
      final count = filteredVisits.where((v) {
        final vDate = v.lastUpdate ?? v.timestamp;
        if (vDate == null) return false;
        return vDate.year == date.year && vDate.month == date.month && vDate.day == date.day;
      }).length;

      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }

    return {'spots': spots, 'labels': labels};
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
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.5), blurRadius: 8)
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _kpi(double w, String t, String v, IconData i, Color c) {
    return SizedBox(width: w, child: KpiCard(title: t, value: v, icon: i, iconColor: c));
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
