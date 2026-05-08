import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/visit.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/kpi_card.dart';

class UserProfileScreen extends StatelessWidget {
  final UserProfile profile;

  const UserProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.bgColorStart, AppTheme.bgColorEnd],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppTheme.sidebarColor.withOpacity(0.8),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Kullanıcı Profili', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 32),
                _buildVisitsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final date = profile.createdAt ?? profile.registrationDate;
    final dateStr = date != null ? "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}" : "-";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 60, color: AppTheme.secondaryColor),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kullanıcı ID: ${profile.id}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 32,
                  runSpacing: 20,
                  children: [
                    _buildInfoColumn('Uygulama', profile.appId?.toUpperCase() ?? '-', Icons.apps),
                    _buildInfoColumn('Platform', profile.platform?.toUpperCase() ?? '-', profile.platform?.toLowerCase() == 'ios' ? Icons.apple : Icons.smartphone),
                    _buildInfoColumn('Versiyon', profile.appVersion ?? '-', Icons.info_outline),
                    _buildInfoColumn('Kayıt Tarihi', dateStr, Icons.calendar_today),
                    _buildInfoColumn('Durum', (profile.isMigrated ?? false) ? 'Aktif' : 'Beklemede', Icons.verified_user),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: Colors.white54),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildVisitsSection() {
    return StreamBuilder<List<Visit>>(
      stream: DashboardService().getUserVisitsStream(profile.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        var visits = snapshot.data ?? [];
        
        // Yeniden eskiye sıralayalım
        visits.sort((a, b) {
          final da = a.lastUpdate ?? a.timestamp ?? DateTime.now();
          final db = b.lastUpdate ?? b.timestamp ?? DateTime.now();
          return db.compareTo(da);
        });

        // KPI Hesaplamaları
        final totalVisits = visits.length;
        final validDurations = visits.where((v) => v.durationSeconds != null).map((v) => v.durationSeconds!);
        final avgDuration = validDurations.isEmpty ? 0 : validDurations.reduce((a, b) => a + b) / validDurations.length;
        
        DateTime? lastVisitDate;
        if (visits.isNotEmpty) {
          lastVisitDate = visits.first.lastUpdate ?? visits.first.timestamp;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kullanıcı Performansı',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 250,
                  child: KpiCard(
                    title: 'Toplam Oturum', 
                    value: totalVisits.toString(), 
                    icon: Icons.repeat, 
                    iconColor: Colors.blueAccent
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: KpiCard(
                    title: 'Ort. Oturum Süresi', 
                    value: '${(avgDuration / 60).toStringAsFixed(1)} Dk', 
                    icon: Icons.timer, 
                    iconColor: Colors.orangeAccent
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: KpiCard(
                    title: 'Son Etkinlik', 
                    value: lastVisitDate != null ? "${lastVisitDate.day}/${lastVisitDate.month} ${lastVisitDate.hour}:${lastVisitDate.minute}" : "-", 
                    icon: Icons.history, 
                    iconColor: Colors.greenAccent
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Ziyaret ve Oturum Geçmişi',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            visits.isEmpty 
              ? _buildEmptyState()
              : _buildTimelineTable(visits),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.glassDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('Bu kullanıcıya ait bir oturum kaydı bulunamadı.', style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildTimelineTable(List<Visit> visits) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.glassDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.05)),
            columns: const [
              DataColumn(label: Text('Ziyaret ID')),
              DataColumn(label: Text('Platform')),
              DataColumn(label: Text('Süre (Sn)')),
              DataColumn(label: Text('Başlangıç Saati')),
              DataColumn(label: Text('Son Güncelleme')),
            ],
            rows: visits.map((v) {
              final sDate = v.timestamp;
              final eDate = v.lastUpdate ?? v.timestamp;

              final sStr = sDate != null ? "${sDate.day}/${sDate.month} ${sDate.hour}:${sDate.minute}" : "-";
              final eStr = eDate != null ? "${eDate.hour}:${eDate.minute}:${eDate.second}" : "-";

              return DataRow(cells: [
                DataCell(Text(v.id.length > 8 ? v.id.substring(0, 8) + '...' : v.id, style: const TextStyle(color: Colors.white54, fontSize: 13))),
                DataCell(Text(v.platform?.toUpperCase() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      v.durationSeconds != null ? "${v.durationSeconds} sn" : "-",
                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ),
                DataCell(Text(sStr)),
                DataCell(Text(eStr, style: const TextStyle(color: Colors.white70))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
