import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/visit.dart';
import '../../models/date_filter.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import '../widgets/scrollable_line_chart_card.dart';
import 'package:fl_chart/fl_chart.dart';

class AppDetailsScreen extends StatelessWidget {
  final String appId;
  final DateFilter dateFilter;

  const AppDetailsScreen({
    super.key,
    required this.appId,
    required this.dateFilter,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Visit>>(
      stream: DashboardService().getVisitsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRawVisits = snapshot.data ?? [];
        
        // 1. App Filtreleme (Client-side lowercase check)
        final appVisits = appId == 'Hepsi' 
            ? allRawVisits 
            : allRawVisits.where((v) => v.appId?.toLowerCase() == appId.toLowerCase()).toList();

        final now = DateTime.now();
        
        // 2. Tarih Filtreleme (KPI kartları için)
        final filteredVisits = appVisits
            .where((v) => _isWithinDate(v.lastUpdate ?? v.timestamp, dateFilter))
            .toList()
          ..sort((a, b) => (b.lastUpdate ?? b.timestamp ?? DateTime(2000))
              .compareTo(a.lastUpdate ?? a.timestamp ?? DateTime(2000)));

        // 3. Grafik için Veri Hazırlığı (appVisits üzerinden, tüm zamanlar trend)
        DateTime earliestDate = appVisits.isEmpty 
            ? now.subtract(const Duration(days: 30))
            : appVisits.map((v) => v.lastUpdate ?? v.timestamp ?? now).reduce((a, b) => a.isBefore(b) ? a : b);
        
        if (now.difference(earliestDate).inDays < 30) {
          earliestDate = now.subtract(const Duration(days: 30));
        }

        final List<String> dailyLabels = [];
        final List<FlSpot> dailyVisitSpots = [];
        int dayCount = now.difference(earliestDate).inDays + 1;

        for (int i = 0; i < dayCount; i++) {
          final date = earliestDate.add(Duration(days: i));
          final label = DateFormat('dd/MM').format(date);
          dailyLabels.add(label);
          
          final count = appVisits.where((v) {
            final vDate = v.lastUpdate ?? v.timestamp;
            if (vDate == null) return false;
            return vDate.year == date.year && vDate.month == date.month && vDate.day == date.day;
          }).length;
          
          dailyVisitSpots.add(FlSpot(i.toDouble(), count.toDouble()));
        }

        // KPI Hesaplamaları
        final totalVisits = filteredVisits.length;
        final iosVisits = filteredVisits.where((v) => v.platform?.toLowerCase() == 'ios').length;
        final otherVisits = totalVisits - iosVisits;
        
        final durations = filteredVisits
            .where((v) => v.durationSeconds != null)
            .map((v) => v.durationSeconds!)
            .toList();
        final double avgDuration = durations.isEmpty
            ? 0
            : durations.reduce((a, b) => a + b) / durations.length;
        final int maxDuration = durations.isEmpty ? 0 : durations.reduce((a, b) => a > b ? a : b);

        final dist01 = durations.where((d) => d <= 60).length;
        final dist15 = durations.where((d) => d > 60 && d <= 300).length;
        final dist5p = durations.where((d) => d > 300).length;

        final Map<String, int> versionDist = {};
        for (var v in filteredVisits) {
          final appLabel = appId == 'Hepsi' ? (v.appId ?? 'Bilinmiyor') : appId;
          final verLabel = '${_appLabel(appLabel)} v${v.appVersion ?? '?'}';
          versionDist[verLabel] = (versionDist[verLabel] ?? 0) + 1;
        }
        final sortedVersions = versionDist.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  'Uygulama Özeti',
                  '${_appLabel(appId)} için performans metrikleri.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _kpi(180, 'Toplam Ziyaret', totalVisits.toString(), Icons.analytics_outlined, Colors.blueAccent),
                    _kpi(180, 'Ort. Süre', '${(avgDuration / 60).toStringAsFixed(1)} Dk', Icons.timer_outlined, Colors.greenAccent),
                    _kpi(180, 'En Uzun', '${(maxDuration / 60).toStringAsFixed(1)} Dk', Icons.history_toggle_off, Colors.orangeAccent),
                    _kpi(180, 'iOS / Diğer', '$iosVisits / $otherVisits', Icons.devices, Colors.purpleAccent),
                  ],
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('Ziyaret Geçmişi', 'Günlük toplam ziyaret trendi (Kaydırılabilir).'),
                const SizedBox(height: 16),
                ScrollableLineChartCard(
                  spots: dailyVisitSpots,
                  labels: dailyLabels,
                  title: 'Günlük Toplam Ziyaret',
                  color: Colors.blueAccent,
                  tooltipLabel: 'Ziyaret',
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('Oturum Analizi', 'Kullanıcıların harcadığı süre dağılımı.'),
                const SizedBox(height: 16),
                _buildDurationDistribution(dist01, dist15, dist5p, totalVisits),

                const SizedBox(height: 32),
                _buildSectionHeader('Versiyon Dağılımı', 'Uygulama bazlı sürüm kullanımı.'),
                const SizedBox(height: 16),
                _buildVersionList(sortedVersions, totalVisits),

                const SizedBox(height: 32),
                _buildSectionHeader('Son Aktiviteler', 'Gelen son ziyaret kayıtları.'),
                const SizedBox(height: 16),
                _buildCompactVisitList(filteredVisits.take(15).toList()),
              ],
            ),
          ),
        );
      },
    );
  }

  String _appLabel(String id) {
    switch (id.toLowerCase()) {
      case 'drinkly':   return 'Drinkly';
      case 'alarmly':   return 'Alarmly';
      case 'quitly':    return 'Quitly';
      default:          return id;
    }
  }

  Widget _buildDurationDistribution(int d01, int d15, int d5p, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Column(
        children: [
          _distRow('Kısa (0–1 dk)', d01, total, Colors.redAccent),
          const SizedBox(height: 14),
          _distRow('Normal (1–5 dk)', d15, total, Colors.yellowAccent),
          const SizedBox(height: 14),
          _distRow('Uzun (5+ dk)', d5p, total, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _distRow(String label, int count, int total, Color color) {
    final double percent = total == 0 ? 0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '$count ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                ),
                TextSpan(
                  text: '(%${(percent * 100).toInt()})',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            color: color,
            backgroundColor: Colors.white10,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildVersionList(List<MapEntry<String, int>> versions, int total) {
    if (versions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration,
        child: const Center(child: Text('Veri yok', style: TextStyle(color: Colors.white38))),
      );
    }
    final colors = [Colors.blueAccent, Colors.purpleAccent, Colors.greenAccent, Colors.orangeAccent];
    return Container(
      decoration: AppTheme.glassDecoration,
      child: Column(
        children: List.generate(versions.length, (i) {
          final e = versions[i];
          final double percent = total == 0 ? 0 : e.value / total;
          final color = colors[i % colors.length];
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${e.value} (%${(percent * 100).toInt()})', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: percent, color: color, backgroundColor: Colors.white.withOpacity(0.06), minHeight: 5),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCompactVisitList(List<Visit> visits) {
    if (visits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration,
        child: const Center(child: Text('Veri yok', style: TextStyle(color: Colors.white38))),
      );
    }
    return Container(
      decoration: AppTheme.glassDecoration,
      child: Column(
        children: List.generate(visits.length, (i) {
          final v = visits[i];
          final isIOS = v.platform?.toLowerCase() == 'ios';
          final duration = (v.durationSeconds ?? 0) / 60;
          return Column(
            children: [
              ListTile(
                leading: Icon(isIOS ? Icons.apple : Icons.android, color: Colors.white24, size: 20),
                title: Text(DateFormat('dd MMM, HH:mm').format(v.lastUpdate ?? v.timestamp ?? DateTime.now()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('${_appLabel(v.appId ?? appId)} v${v.appVersion ?? '?'}', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                trailing: Text('${duration.toStringAsFixed(1)} dk', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12)),
              ),
              if (i < visits.length - 1) const Divider(color: Colors.white10, height: 1, indent: 50),
            ],
          );
        }),
      ),
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
    return Row(
      children: [
        Container(width: 4, height: 36, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.5), blurRadius: 8)])),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12))]),
      ],
    );
  }

  Widget _kpi(double w, String t, String v, IconData i, Color c) {
    return SizedBox(width: w, child: KpiCard(title: t, value: v, icon: i, iconColor: c));
  }
}
