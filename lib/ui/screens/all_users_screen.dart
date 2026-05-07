import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/date_filter.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';
import 'user_profile_screen.dart';

class AllUsersScreen extends StatelessWidget {
  final DateFilter dateFilter;
  final String appIdFilter;

  const AllUsersScreen({
    super.key,
    required this.dateFilter,
    required this.appIdFilter,
  });

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

        // 1. AppId Filtreleme
        var filtered = allProfiles;
        if (appIdFilter != 'Hepsi') {
          filtered = filtered.where((p) => p.appId == appIdFilter).toList();
        }

        // 2. Tarih Filtreleme
        filtered = filtered.where((p) {
          if (dateFilter.type == DateFilterType.allTime) return true;
          final date = p.createdAt ?? p.registrationDate;
          if (date == null) return false;

          if (dateFilter.type == DateFilterType.daily) {
            return date.year == dateFilter.date.year && 
                   date.month == dateFilter.date.month && 
                   date.day == dateFilter.date.day;
          } else {
            return date.year == dateFilter.date.year && date.month == dateFilter.date.month;
          }
        }).toList();

        // Sıralama (Yeniye göre)
        filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

        return SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tüm Kullanıcı Portfolyosu',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Toplam ${filtered.length} kayıt listeleniyor',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: filtered.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        final date = p.createdAt ?? p.registrationDate;
                        final dateStr = date != null ? "${date.day}/${date.month}/${date.year}" : "-";
                        final shortId = p.id.length > 8 ? p.id.substring(0, 8) + "..." : p.id;
                        
                        return InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(profile: p)));
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.glassDecoration,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shortId,
                                        style: const TextStyle(color: Colors.blueAccent, fontSize: 15, decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(p.platform?.toLowerCase() == 'ios' ? Icons.apple : Icons.android, size: 14, color: Colors.white54),
                                          const SizedBox(width: 4),
                                          Text(p.appId?.toUpperCase() ?? '-', style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.calendar_today, size: 12, color: Colors.white38),
                                          const SizedBox(width: 4),
                                          Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusBadge(p.isMigrated ?? false),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('Seçili kriterlere uygun kullanıcı bulunamadı.', style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool migrated) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: migrated ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: migrated ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
      ),
      child: Text(
        migrated ? 'AKTİF' : 'BEKLEMEDE',
        style: TextStyle(color: migrated ? Colors.green : Colors.orange, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
