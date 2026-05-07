import 'package:flutter/material.dart';
import '../../models/visit.dart';
import '../../models/date_filter.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';

class AppDetailsScreen extends StatefulWidget {
  final DateFilter dateFilter;
  final String appIdFilter;

  const AppDetailsScreen({
    super.key,
    required this.dateFilter,
    required this.appIdFilter,
  });

  @override
  State<AppDetailsScreen> createState() => _AppDetailsScreenState();
}

class _AppDetailsScreenState extends State<AppDetailsScreen> {
  String _internalPlatformFilter = 'Hepsi';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Visit>>(
      stream: DashboardService().getVisitsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final allVisits = snapshot.data ?? [];

        // 1. Global AppId Filtresi
        var filtered = allVisits;
        if (widget.appIdFilter != 'Hepsi') {
          filtered = filtered.where((v) => v.appId == widget.appIdFilter).toList();
        }

        // 2. Global Tarih Filtresi
        filtered = filtered.where((v) {
          if (widget.dateFilter.type == DateFilterType.allTime) return true;
          final date = v.lastUpdate ?? v.timestamp;
          if (date == null) return false;

          final filterDate = widget.dateFilter.date;
          if (widget.dateFilter.type == DateFilterType.daily) {
            return date.year == filterDate.year && 
                   date.month == filterDate.month && 
                   date.day == filterDate.day;
          } else {
            return date.year == filterDate.year && date.month == filterDate.month;
          }
        }).toList();

        // 3. Sayfa içi Platform Filtresi
        if (_internalPlatformFilter != 'Hepsi') {
          filtered = filtered.where((v) => 
            v.platform?.toLowerCase() == _internalPlatformFilter.toLowerCase()
          ).toList();
        }

        // Sıralama: En yeniden en eskiye
        filtered.sort((a, b) {
          final da = a.lastUpdate ?? a.timestamp ?? DateTime.now();
          final db = b.lastUpdate ?? b.timestamp ?? DateTime.now();
          return db.compareTo(da);
        });

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    const Text(
                      'Ziyaret ve Oturum Kayıtları',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    _buildPlatformDropdown(),
                  ],
                ),
                const SizedBox(height: 24),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length > 100 ? 100 : filtered.length,
                    itemBuilder: (context, index) {
                      final v = filtered[index];
                      final date = v.lastUpdate ?? v.timestamp;
                      final dateStr = date != null ? "${date.day}/${date.month} ${date.hour}:${date.minute}" : "-";
                      final shortUserId = v.userId.length > 8 ? v.userId.substring(0, 8) + "..." : v.userId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.glassDecoration,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shortUserId,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(v.platform?.toLowerCase() == 'ios' ? Icons.apple : Icons.android, size: 14, color: Colors.white54),
                                      const SizedBox(width: 4),
                                      _buildPillBadge(v.appId ?? '-', AppTheme.secondaryColor),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.timer_outlined, size: 12, color: Colors.white38),
                                      const SizedBox(width: 4),
                                      Text(
                                        v.durationSeconds != null ? "${v.durationSeconds} sn" : "-",
                                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Icon(Icons.history_rounded, size: 16, color: Colors.white38),
                                const SizedBox(height: 4),
                                Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlatformDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _internalPlatformFilter,
          dropdownColor: AppTheme.bgColorStart,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: (v) => setState(() => _internalPlatformFilter = v!),
          items: ['Hepsi', 'iOS', 'Android'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  Widget _buildPillBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}
