import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/visit.dart';
import '../../models/date_filter.dart';
import '../../models/user_engagement.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';
import 'user_profile_screen.dart';
import 'package:intl/intl.dart';

class AllUsersScreen extends StatefulWidget {
  final DateFilter dateFilter;
  final String appIdFilter;

  const AllUsersScreen({
    super.key,
    required this.dateFilter,
    required this.appIdFilter,
  });

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  String _sortBy = 'score'; // 'score', 'visitCount', 'lastVisit', 'createdAt'

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: DashboardService().getProfilesStream(),
      builder: (context, profileSnapshot) {
        return StreamBuilder<List<Visit>>(
          stream: DashboardService().getVisitsStream(),
          builder: (context, visitSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting || 
                visitSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allProfiles = profileSnapshot.data ?? [];
            final allVisits = visitSnapshot.data ?? [];

            // 1. Filtreleme ve Data Birleştirme
            var filteredProfiles = _applyFilters(allProfiles);
            
            final List<UserEngagement> engagementData = filteredProfiles.map((p) {
              final userVisits = allVisits.where((v) => v.userId == p.id).toList();
              return UserEngagement.fromData(p, userVisits);
            }).toList();

            // 2. Sıralama
            _sortData(engagementData);

            // 3. Özet Metrikleri (Son 7 gün aktiflik)
            final now = DateTime.now();
            final sevenDaysAgo = now.subtract(const Duration(days: 7));
            final activeCount = engagementData.where((e) => e.lastVisit != null && e.lastVisit!.isAfter(sevenDaysAgo)).length;
            final passiveCount = engagementData.length - activeCount;

            return SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryBar(engagementData.length, activeCount, passiveCount),
                  _buildSortHeader(),
                  
                  Expanded(
                    child: engagementData.isEmpty 
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: engagementData.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(engagementData[index]);
                          },
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<UserProfile> _applyFilters(List<UserProfile> profiles) {
    var filtered = profiles;
    if (widget.appIdFilter != 'Hepsi') {
      final filterLower = widget.appIdFilter.toLowerCase();
      filtered = filtered.where((p) => p.appId?.toLowerCase() == filterLower).toList();
    }

    return filtered.where((p) {
      if (widget.dateFilter.type == DateFilterType.allTime) return true;
      // Modelde yaptığımız güncelleme sayesinde p.createdAt artık migratedAt'i de kapsıyor
      final date = p.createdAt;
      if (date == null) return false;

      if (widget.dateFilter.type == DateFilterType.daily) {
        return date.year == widget.dateFilter.date.year && 
               date.month == widget.dateFilter.date.month && 
               date.day == widget.dateFilter.date.day;
      } else {
        return date.year == widget.dateFilter.date.year && date.month == widget.dateFilter.date.month;
      }
    }).toList();
  }

  void _sortData(List<UserEngagement> data) {
    switch (_sortBy) {
      case 'score':
        data.sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
        break;
      case 'visitCount':
        data.sort((a, b) => b.visitCount.compareTo(a.visitCount));
        break;
      case 'lastVisit':
        data.sort((a, b) => (b.lastVisit ?? DateTime(2000)).compareTo(a.lastVisit ?? DateTime(2000)));
        break;
      case 'createdAt':
        data.sort((a, b) => (b.profile.createdAt ?? DateTime(2000)).compareTo(a.profile.createdAt ?? DateTime(2000)));
        break;
    }
  }

  Widget _buildSummaryBar(int total, int active, int passive) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Toplam', total.toString(), Colors.blueAccent),
          _summaryItem('Aktif (7G)', active.toString(), Colors.greenAccent),
          _summaryItem('Pasif', passive.toString(), Colors.redAccent),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _buildSortHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Kullanıcı Listesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          DropdownButton<String>(
            value: _sortBy,
            underline: Container(),
            dropdownColor: AppTheme.sidebarColor,
            elevation: 16,
            style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
            items: const [
              DropdownMenuItem(value: 'score', child: Text('Etkileşim Skoru')),
              DropdownMenuItem(value: 'visitCount', child: Text('Ziyaret Sayısı')),
              DropdownMenuItem(value: 'lastVisit', child: Text('Son Ziyaret')),
              DropdownMenuItem(value: 'createdAt', child: Text('Kayıt Tarihi')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _sortBy = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserEngagement engage) {
    final p = engage.profile;
    final score = engage.engagementScore;
    final scoreColor = score > 50 ? Colors.greenAccent : (score > 20 ? Colors.orangeAccent : Colors.redAccent);
    final lastVisitStr = engage.lastVisit != null 
        ? '${DateTime.now().difference(engage.lastVisit!).inDays} gün önce'
        : 'Ziyaret yok';

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(profile: p)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    (p.originalName == null || p.originalName!.trim().isEmpty) ? 'Anonim' : p.originalName!,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: scoreColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: scoreColor.withOpacity(0.3))),
                  child: Text('Skor: ${score.toInt()}', style: TextStyle(color: scoreColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniInfo(Icons.analytics_outlined, '${engage.visitCount} Ziyaret'),
                _miniInfo(Icons.timer_outlined, '${engage.avgSessionMinutes.toStringAsFixed(1)} Dk Ort.'),
                _miniInfo(Icons.event_available, lastVisitStr),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(p.platform?.toLowerCase() == 'ios' ? Icons.apple : Icons.smartphone, size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Text(p.appId?.toUpperCase() ?? '-', style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('Kriterlere uygun kullanıcı bulunamadı.', style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }
}
