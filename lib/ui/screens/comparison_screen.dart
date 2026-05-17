import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/visit.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/scrollable_multi_line_chart_card.dart';
import 'package:fl_chart/fl_chart.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  String _appA = 'alarmly';
  String _appB = 'quitly';

  final List<String> _apps = ['alarmly', 'drinkly', 'quitly'];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Visit>>(
      stream: DashboardService().getVisitsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allVisits = snapshot.data ?? [];
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));

        final visitsA = allVisits.where((v) => v.appId?.toLowerCase() == _appA).toList();
        final visitsB = allVisits.where((v) => v.appId?.toLowerCase() == _appB).toList();

        // Son 30 G ün Verisi (Trend için)
        final List<String> labels = [];
        final List<FlSpot> spotsA = [];
        final List<FlSpot> spotsB = [];

        for (int i = 0; i < 30; i++) {
          final date = thirtyDaysAgo.add(Duration(days: i));
          final label = DateFormat('dd/MM').format(date);
          labels.add(label);

          final countA = visitsA.where((v) {
            final vd = v.lastUpdate ?? v.timestamp;
            return vd != null && vd.year == date.year && vd.month == date.month && vd.day == date.day;
          }).length;
          
          final countB = visitsB.where((v) {
            final vd = v.lastUpdate ?? v.timestamp;
            return vd != null && vd.year == date.year && vd.month == date.month && vd.day == date.day;
          }).length;

          spotsA.add(FlSpot(i.toDouble(), countA.toDouble()));
          spotsB.add(FlSpot(i.toDouble(), countB.toDouble()));
        }

        // Metrik Hesaplamaları (Tüm zamanlar)
        final totalA = visitsA.length;
        final totalB = visitsB.length;
        
        final double avgDurA = _calcAvgDur(visitsA);
        final double avgDurB = _calcAvgDur(visitsB);

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Uygulama Karşılaştırma', 'İki uygulamayı yan yana analiz edin.'),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(child: _buildAppPicker('Uygulama A', _appA, (val) => setState(() => _appA = val!))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.compare_arrows_rounded, color: Colors.white24),
                    ),
                    Expanded(child: _buildAppPicker('Uygulama B', _appB, (val) => setState(() => _appB = val!))),
                  ],
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('Trend Karşılaştırması', 'Son 30 günlük ziyaret etkileşimi (Kaydırılabilir).'),
                const SizedBox(height: 16),
                ScrollableMultiLineChartCard(
                  title: 'Ziyaret Trendi Karşılaştırması',
                  labelA: _appLabel(_appA),
                  labelB: _appLabel(_appB),
                  colorA: Colors.blueAccent,
                  colorB: Colors.orangeAccent,
                  spotsA: spotsA,
                  spotsB: spotsB,
                  labels: labels,
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('Temel Metrikler', 'Karşılaştırmalı performans verileri.'),
                const SizedBox(height: 16),
                _buildMetricRow('Toplam Ziyaret', totalA, totalB, totalA > totalB),
                _buildMetricRow('Ortalama Oturum', '${(avgDurA / 60).toStringAsFixed(1)} dk', '${(avgDurB / 60).toStringAsFixed(1)} dk', avgDurA > avgDurB),
                _buildMetricRow('iOS Kullanıcı Oranı', '${_calcIosPercent(visitsA)}%', '${_calcIosPercent(visitsB)}%', _calcIosPercent(visitsA) > _calcIosPercent(visitsB)),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calcAvgDur(List<Visit> visits) {
    if (visits.isEmpty) return 0;
    final durs = visits.where((v) => v.durationSeconds != null).map((v) => v.durationSeconds!);
    return durs.isEmpty ? 0 : durs.reduce((a, b) => a + b) / durs.length;
  }

  int _calcIosPercent(List<Visit> visits) {
    if (visits.isEmpty) return 0;
    final iosCount = visits.where((v) => v.platform?.toLowerCase() == 'ios').length;
    return (iosCount / visits.length * 100).toInt();
  }

  String _appLabel(String id) {
    switch (id.toLowerCase()) {
      case 'drinkly': return 'Drinkly';
      case 'alarmly': return 'Alarmly';
      case 'quitly':  return 'Quitly';
      default:        return id;
    }
  }

  Widget _buildAppPicker(String label, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: AppTheme.glassDecoration.copyWith(borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: AppTheme.sidebarColor,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
              isExpanded: true,
              items: _apps.map((a) => DropdownMenuItem(value: a, child: Text(_appLabel(a), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String title, dynamic valA, dynamic valB, bool aIsWinner) {
    // flex 0 olursa hata verir, minimum 1 koy
    final int flexA = valA is int ? (valA < 1 ? 1 : valA) : 50;
    final int flexB = valB is int ? (valB < 1 ? 1 : valB) : 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricValue(valA.toString(), aIsWinner, Colors.blueAccent),
              Text('VS', style: TextStyle(color: Colors.white10, fontWeight: FontWeight.bold, fontSize: 18)),
              _metricValue(valB.toString(), !aIsWinner, Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(flex: flexA, child: Container(height: 4, color: Colors.blueAccent.withOpacity(aIsWinner ? 1 : 0.2))),
                Expanded(flex: flexB, child: Container(height: 4, color: Colors.orangeAccent.withOpacity(!aIsWinner ? 1 : 0.2))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricValue(String val, bool highlight, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: highlight ? color : Colors.white70)),
        if (highlight) Container(margin: const EdgeInsets.only(top: 4), width: 20, height: 2, color: color),
      ],
    );
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
}
