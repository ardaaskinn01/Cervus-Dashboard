import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/date_filter.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/kpi_card.dart';

class NewUsersScreen extends StatefulWidget {
  final DateFilter dateFilter; 
  final String appIdFilter;

  const NewUsersScreen({
    super.key,
    required this.dateFilter,
    required this.appIdFilter,
  });

  @override
  State<NewUsersScreen> createState() => _NewUsersScreenState();
}

class _NewUsersScreenState extends State<NewUsersScreen> {
  // 1 = Son 24 Saat, 7 = Son 7 Gün, 30 = Son 30 Gün
  int _selectedFilterDays = 7; 

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: DashboardService().getProfilesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final allProfiles = snapshot.data ?? [];

        // 1. AppId Filtreleme (Globalden gelen)
        var appFiltered = allProfiles;
        if (widget.appIdFilter != 'Hepsi') {
          appFiltered = appFiltered.where((p) => p.appId == widget.appIdFilter).toList();
        }

        // 2. Zaman Periyodunu Ayarlama (Yerel Filtre)
        final now = DateTime.now();
        final periodStart = _selectedFilterDays == 1 
            ? now.subtract(const Duration(hours: 24))
            : DateTime(now.year, now.month, now.day).subtract(Duration(days: _selectedFilterDays - 1));
            
        final prevPeriodStart = _selectedFilterDays == 1
            ? periodStart.subtract(const Duration(hours: 24))
            : periodStart.subtract(Duration(days: _selectedFilterDays));

        // Güncel Dönem Verileri
        final currentPeriodUsers = appFiltered.where((p) {
          final date = p.createdAt ?? p.registrationDate;
          if (date == null) return false;
          return date.isAfter(periodStart) && date.isBefore(now);
        }).toList();

        // Önceki Dönem Verileri (Kıyaslama için)
        final prevPeriodUsers = appFiltered.where((p) {
          final date = p.createdAt ?? p.registrationDate;
          if (date == null) return false;
          return date.isAfter(prevPeriodStart) && date.isBefore(periodStart);
        }).toList();

        // İstatistik Hesaplamaları
        final totalCurrent = currentPeriodUsers.length;
        final totalPrev = prevPeriodUsers.length;
        final growthRate = totalPrev == 0 ? 100.0 : ((totalCurrent - totalPrev) / totalPrev) * 100;

        final iosUsers = currentPeriodUsers.where((p) => p.platform?.toLowerCase() == 'ios').length;
        final androidUsers = currentPeriodUsers.where((p) => p.platform?.toLowerCase() != 'ios').length;

        // Uygulamalara Göre Dağılım Map
        final Map<String, int> appDistribution = {};
        for (var p in currentPeriodUsers) {
          final app = p.appId?.toLowerCase() ?? 'Bilinmeyen';
          appDistribution[app] = (appDistribution[app] ?? 0) + 1;
        }

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve Yerel Filtre
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Büyüme & Yeni Kullanıcılar',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    _buildTimeFilter(),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Ana Rakamlar (Ana KPI Kartları)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 250,
                      child: _buildTrendCard(
                        title: 'Kazanılan Kullanıcı',
                        value: totalCurrent.toString(),
                        trendValue: growthRate,
                        icon: Icons.person_add_alt_1,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: KpiCard(
                        title: 'iOS Platformu',
                        value: iosUsers.toString(),
                        icon: Icons.apple,
                        iconColor: Colors.white70,
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: KpiCard(
                        title: 'Mobil/Diğer Platform',
                        value: androidUsers.toString(),
                        icon: Icons.smartphone,
                        iconColor: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                
                // Uygulama Dağılımı (Sadece 'Hepsi' seçiliyse göster)
                if (widget.appIdFilter == 'Hepsi' && appDistribution.isNotEmpty) ...[
                  const Text(
                    'Uygulama Performansı',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: appDistribution.entries.map((e) {
                      return SizedBox(
                        width: 200,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.glassDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.key.toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(e.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  const Text('yeni kullanıcı', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],

                // Özet Detayı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.analytics_outlined, color: AppTheme.primaryColor),
                          SizedBox(width: 12),
                          Text('Analiz Özeti', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFilterDays == 1 
                          ? 'Son 24 saat içinde sisteme katılan kullanıcı sayısı, önceki 24 saate göre %${growthRate.abs().toStringAsFixed(1)} ${growthRate >= 0 ? "artış" : "düşüş"} gösterdi.'
                          : 'Son $_selectedFilterDays gün içinde toplam $totalCurrent yeni kullanıcı uygulamalarımızı kullanmaya başladı. Bu rakam bir önceki $_selectedFilterDays günlük periyoda ($totalPrev) kıyasla %${growthRate.abs().toStringAsFixed(1)} oranında ${growthRate >= 0 ? "büyümeyi" : "küçülmeyi"} ifade ediyor.',
                        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      decoration: AppTheme.glassDecoration.copyWith(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterButton('Son 24s', 1),
          _buildFilterButton('Son 7 Gün', 7),
          _buildFilterButton('Son 30 Gün', 30),
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
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPositive ? Colors.green : Colors.red,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '%${trendValue.abs().toStringAsFixed(1)}',
                            style: TextStyle(
                              color: isPositive ? Colors.green : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
