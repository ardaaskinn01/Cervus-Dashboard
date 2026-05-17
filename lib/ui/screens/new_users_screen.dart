import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_profile.dart';
import '../../models/date_filter.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import '../widgets/scrollable_line_chart_card.dart';
import 'package:fl_chart/fl_chart.dart';

class NewUsersScreen extends StatefulWidget {
  final DateFilter dateFilter;
  final String appIdFilter;

  const NewUsersScreen({super.key, required this.dateFilter, required this.appIdFilter});

  @override
  State<NewUsersScreen> createState() => _NewUsersScreenState();
}

class _NewUsersScreenState extends State<NewUsersScreen> {
  int _selectedFilterDays = 30; 
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: DashboardService().getProfilesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final profiles = snapshot.data ?? [];
        final now = DateTime.now();
        
        // Veri Setini Hazırla (En eski kayıttan bugüne)
        // Eğer profiles boş ise DateTime.now() kullan
        DateTime earliestDate = profiles.isEmpty 
            ? now.subtract(const Duration(days: 30))
            : profiles.map((p) => p.createdAt ?? now).reduce((a, b) => a.isBefore(b) ? a : b);
        
        // En az 30 günlük veri gösterelim
        if (now.difference(earliestDate).inDays < 30) {
          earliestDate = now.subtract(const Duration(days: 30));
        }

        // Grafik için günleri oluştur
        final List<String> labels = [];
        final List<FlSpot> spots = [];
        int dayCount = now.difference(earliestDate).inDays + 1;

        for (int i = 0; i < dayCount; i++) {
          final date = earliestDate.add(Duration(days: i));
          final label = DateFormat('dd/MM').format(date);
          labels.add(label);
          
          // O günkü kullanıcı sayısını bul
          final userCount = profiles.where((p) {
            final pDate = p.createdAt;
            if (pDate == null) return false;
            
            bool isSameDay = pDate.year == date.year && pDate.month == date.month && pDate.day == date.day;
            if (widget.appIdFilter != 'Hepsi') {
              return isSameDay && p.appId?.toLowerCase() == widget.appIdFilter.toLowerCase();
            }
            return isSameDay;
          }).length;
          
          spots.add(FlSpot(i.toDouble(), userCount.toDouble()));
        }

        // Mevcut periyot filtrelemesi (KPI için)
        final periodStart = now.subtract(Duration(days: _selectedFilterDays));
        var currentPeriodUsers = profiles.where((p) {
          final date = p.createdAt;
          if (date == null) return false;
          bool isInTime = date.isAfter(periodStart);
          if (widget.appIdFilter != 'Hepsi') {
            return isInTime && p.appId?.toLowerCase() == widget.appIdFilter.toLowerCase();
          }
          return isInTime;
        }).toList();

        final prevPeriodStart = periodStart.subtract(Duration(days: _selectedFilterDays));
        var prevPeriodUsers = profiles.where((p) {
          final date = p.createdAt;
          if (date == null) return false;
          return date.isAfter(prevPeriodStart) && date.isBefore(periodStart);
        }).toList();

        final totalCount = currentPeriodUsers.length;
        final prevCount = prevPeriodUsers.length;
        final double growth = prevCount == 0 ? 100 : ((totalCount - prevCount) / prevCount * 100);

        final appDist = _calculateAppDistribution(currentPeriodUsers);

        // Grafiği en sona (sağa) kaydır (Eğer veri varsa)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            // NewUsersScreen içinde scrollController yok artık çünkü listewiev vs yok ama
            // ScrollableLineChartCard kendi içinde controller kullanmıyor.
            // Bu yüzden Widget içinde sağa kaydırma manuel yapılmalıydı ama bu modelde 
            // kullanıcı zaten en güncel veriyi (sağda) görecek şekilde scroll yapabilir.
          }
        });

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Büyüme Analizi', 'Tarihsel kullanıcı kazanım trendi.'),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    _buildTimeFilter(),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Periyot Toplamı', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        Text('$totalCount Kayıt', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _buildTrendCard(
                  title: 'Dönemsel Yeni Kayıt',
                  value: totalCount.toString(),
                  trendValue: growth,
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.primaryColor,
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('Kayıt Geçmişi', 'En eskiden bugüne günlük kayıt trendi (Kaydırılabilir).'),
                const SizedBox(height: 16),
                ScrollableLineChartCard(
                  title: 'Günlük Kayıt Trendi',
                  spots: spots,
                  labels: labels,
                  color: AppTheme.secondaryColor,
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('Uygulama Dağılımı', 'Hangi uygulama daha çok kullanıcı çekiyor?'),
                const SizedBox(height: 16),
                _buildAppDistributionList(appDist, totalCount),

                const SizedBox(height: 32),
                _buildSectionHeader('Son Kayıtlar', 'En son katılan 10 kullanıcı.'),
                const SizedBox(height: 16),
                _buildCompactUserList(profiles..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)))),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, int> _calculateAppDistribution(List<UserProfile> users) {
    final Map<String, int> dist = {'alarmly': 0, 'quitly': 0, 'drinkly': 0};
    for (var u in users) {
      final id = u.appId?.toLowerCase().trim();
      if (id != null && dist.containsKey(id)) {
        dist[id] = dist[id]! + 1;
      }
    }
    return dist;
  }

  Widget _buildAppDistributionList(Map<String, int> dist, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Column(
        children: dist.entries.map((e) {
          final double percent = total == 0 ? 0 : (e.value / total);
          final color = e.key == 'alarmly' ? Colors.blueAccent : (e.key == 'quitly' ? Colors.greenAccent : Colors.orangeAccent);
          final name = e.key == 'alarmly' ? 'Alarmly' : (e.key == 'quitly' ? 'Quitly' : 'Drinkly');
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                    Text('%${(percent * 100).toInt()} (${e.value})', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    color: color,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactUserList(List<UserProfile> sortedUsers) {
    final displayUsers = sortedUsers.take(15).toList();
    if (displayUsers.isEmpty) {
      return Container(
        height: 100,
        decoration: AppTheme.glassDecoration,
        alignment: Alignment.center,
        child: const Text('Kullanıcı bulunamadı', style: TextStyle(color: Colors.white38)),
      );
    }

    return Container(
      decoration: AppTheme.glassDecoration,
      child: Column(
        children: List.generate(displayUsers.length, (index) {
          final u = displayUsers[index];
          final isIOS = u.platform?.toLowerCase() == 'ios';
          final appName = u.appId == 'alarmly' ? 'Alarmly' : (u.appId == 'quitly' ? 'Quitly' : 'Drinkly');

          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor, size: 20),
                ),
                title: Text(
                   (u.originalName == null || u.originalName!.trim().isEmpty) ? 'Anonim' : u.originalName!,
                   style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                ),
                subtitle: Text(
                  '${appName}  ·  ${DateFormat('dd MMM, HH:mm').format(u.createdAt ?? DateTime.now())}', 
                  style: const TextStyle(fontSize: 11, color: Colors.white38)
                ),
                trailing: Icon(isIOS ? Icons.apple : Icons.android_rounded, size: 18, color: Colors.white38),
              ),
              if (index < displayUsers.length - 1)
                const Divider(color: Colors.white10, height: 1, indent: 70),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.5), blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      decoration: AppTheme.glassDecoration.copyWith(borderRadius: BorderRadius.circular(20), color: Colors.white.withValues(alpha: 0.05)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterButton('Son 24s', 1),
          _buildFilterButton('7 G', 7),
          _buildFilterButton('30 G', 30),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, int days) {
    final isSelected = _selectedFilterDays == days;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterDays = days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendCard({
    required String title,
    required String value,
    required double trendValue,
    required IconData icon,
    required Color color,
  }) {
    final isPositive = trendValue >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: isPositive ? Colors.green : Colors.red, size: 10),
                          const SizedBox(width: 2),
                          Text('%${trendValue.abs().toStringAsFixed(1)}', style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
