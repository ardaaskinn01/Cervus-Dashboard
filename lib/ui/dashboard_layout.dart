import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/overview_screen.dart';
import 'screens/app_details_screen.dart';
import 'screens/new_users_screen.dart';
import 'screens/all_users_screen.dart';
import '../theme/app_theme.dart';
import '../models/date_filter.dart';

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  
  DateFilter _globalFilter = DateFilter(type: DateFilterType.allTime, date: DateTime.now());
  String _selectedAppId = 'Hepsi';

  final List<String> _appOptions = ['Hepsi', 'quitly', 'alarmly', 'drinkly'];

  Widget _getScreen(int index) {
    switch(index) {
      case 0:
        return OverviewScreen(dateFilter: _globalFilter, appIdFilter: _selectedAppId);
      case 1:
        return AllUsersScreen(dateFilter: _globalFilter, appIdFilter: _selectedAppId);
      case 2:
        return NewUsersScreen(dateFilter: _globalFilter, appIdFilter: _selectedAppId);
      case 3:
        return AppDetailsScreen(dateFilter: _globalFilter, appIdFilter: _selectedAppId); 
      default:
        return OverviewScreen(dateFilter: _globalFilter, appIdFilter: _selectedAppId);
    }
  }

  String _getScreenTitle(int index) {
    switch(index) {
      case 0: return 'Genel Bakış';
      case 1: return 'Tüm Kullanıcılar';
      case 2: return 'Yeni Kullanıcılar';
      case 3: return 'Ziyaret ve Oturumlar';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1000;

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
        appBar: isDesktop
            ? null
            : AppBar(
                title: Text(_getScreenTitle(_selectedIndex), style: const TextStyle(fontSize: 18)),
                backgroundColor: AppTheme.sidebarColor.withOpacity(0.8),
                elevation: 0,
              ),
        drawer: isDesktop ? null : Drawer(
          backgroundColor: AppTheme.bgColorStart,
          child: _buildSidebar(isDesktop: false),
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Sidebar ve İçeriği tepeye yasla
          children: [
            if (isDesktop) _buildSidebar(isDesktop: true),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, // Dikeyde en baştan başla
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isDesktop),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _getScreen(_selectedIndex),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isDesktop)
            Text(
              _getScreenTitle(_selectedIndex),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            )
          else
            const SizedBox(),
          if (_selectedIndex != 2)
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(child: _buildAppFilter()),
                  const SizedBox(width: 8),
                  Flexible(child: _buildGlobalDateFilter()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: AppTheme.glassDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.apps_rounded, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAppId,
              dropdownColor: AppTheme.bgColorStart,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              isDense: true,
              onChanged: (val) {
                if (val != null) setState(() => _selectedAppId = val);
              },
              items: _appOptions.map((e) {
                return DropdownMenuItem(
                  value: e, 
                  child: Text(e == 'Hepsi' ? e : e[0].toUpperCase() + e.substring(1))
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalDateFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppTheme.glassDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_month_outlined, color: AppTheme.secondaryColor, size: 18),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<DateFilterType>(
              value: _globalFilter.type,
              dropdownColor: AppTheme.bgColorStart,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              isDense: true,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _globalFilter = DateFilter(type: val, date: _globalFilter.date);
                  });
                  if (val != DateFilterType.allTime) {
                    _pickDate(val); // Burası dropdown değişince tetikler
                  }
                }
              },
              items: const [
                DropdownMenuItem(value: DateFilterType.daily, child: Text("Gün")),
                DropdownMenuItem(value: DateFilterType.monthly, child: Text("Ay")),
                DropdownMenuItem(value: DateFilterType.allTime, child: Text("Hepsi")),
              ],
            ),
          ),
          if (_globalFilter.type != DateFilterType.allTime) ...[
            const SizedBox(width: 4),
            const Text('|', style: TextStyle(color: Colors.white12)),
            const SizedBox(width: 4),
            Flexible(
              child: InkWell(
                onTap: () => _pickDate(_globalFilter.type), // Burası metne tıklayınca tetikler
                child: Text(
                  _globalFilter.type == DateFilterType.daily 
                    ? "${_globalFilter.date.day}/${_globalFilter.date.month}"
                    : "${_globalFilter.date.month}/${_globalFilter.date.year}",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor, fontSize: 12),
                ),
              ),
            )
          ]
        ],
      ),
    );
  }

  Future<void> _pickDate(DateFilterType type) async {
    if (type == DateFilterType.monthly) {
      // Custom Month Picker Dialog
      final selectedDate = await showDialog<DateTime>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Ay Seçin'),
            backgroundColor: AppTheme.bgColorStart,
            content: SizedBox(
              width: 300,
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final isSelected = _globalFilter.date.month == month;
                  return InkWell(
                    onTap: () => Navigator.pop(context, DateTime(_globalFilter.date.year, month)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? AppTheme.secondaryColor : Colors.white10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getMonthName(month),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
      if (selectedDate != null) {
        setState(() => _globalFilter = DateFilter(type: type, date: selectedDate));
      }
    } else {
      // Standard Daily Picker
      final picked = await showDatePicker(
        context: context,
        initialDate: _globalFilter.date,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: AppTheme.darkTheme.copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.primaryColor,
                onPrimary: Colors.white,
                surface: AppTheme.bgColorStart,
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() => _globalFilter = DateFilter(type: type, date: picked));
      }
    }
  }

  String _getMonthName(int month) {
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return months[month - 1];
  }

  Widget _buildSidebar({required bool isDesktop}) {
    final width = (_isSidebarExpanded || !isDesktop) ? 280.0 : 88.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.sidebarColor,
        border: const Border(right: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        children: [
          // Logo Section
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: isDesktop && !_isSidebarExpanded ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                if (_isSidebarExpanded || !isDesktop) ...[
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'CERVUS\nSTUDIO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: IconButton(
                icon: Icon(_isSidebarExpanded ? Icons.keyboard_arrow_left : Icons.keyboard_arrow_right, color: Colors.white54),
                onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
              ),
            ),

          const Divider(color: AppTheme.borderColor, indent: 20, endIndent: 20),
          const SizedBox(height: 10),

          _buildMenuItem(
            index: 0,
            icon: Icons.grid_view_rounded,
            title: 'Genel Bakış',
          ),
          _buildMenuItem(
            index: 1,
            icon: Icons.people_outline_rounded,
            title: 'Tüm Kullanıcılar',
          ),
          _buildMenuItem(
            index: 2,
            icon: Icons.person_add_rounded,
            title: 'Yeni Kullanıcılar',
          ),
          _buildMenuItem(
            index: 3,
            icon: Icons.history_toggle_off_rounded,
            title: 'Ziyaret ve Oturumlar',
          ),
          
          const Spacer(),
          
          // Version info
          if (_isSidebarExpanded || !isDesktop)
            Container(
              padding: const EdgeInsets.all(20),
              child: const Text('v1.1.0 Stable', style: TextStyle(color: Colors.white24, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required int index, required IconData icon, required String title}) {
    final isSelected = _selectedIndex == index;
    final isExpanded = _isSidebarExpanded || MediaQuery.of(context).size.width <= 1000;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => _selectedIndex = index);
          if (MediaQuery.of(context).size.width <= 1000) Navigator.pop(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.3),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                )
              : null,
            border: isSelected ? Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 1) : null,
            boxShadow: isSelected 
              ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 10, spreadRadius: -2)] 
              : null,
          ),
          child: Row(
            mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.secondaryColor : Colors.white54,
                size: 22,
              ),
              if (isExpanded) ...[
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
