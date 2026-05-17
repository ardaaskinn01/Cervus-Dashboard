import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';

class ScrollableLineChartCard extends StatefulWidget {
  final List<FlSpot> spots;
  final List<String> labels;
  final String title;
  final Color color;
  final String tooltipLabel;

  const ScrollableLineChartCard({
    super.key,
    required this.spots,
    required this.labels,
    required this.title,
    required this.color,
    this.tooltipLabel = 'Veri',
  });

  @override
  State<ScrollableLineChartCard> createState() => _ScrollableLineChartCardState();
}

class _ScrollableLineChartCardState extends State<ScrollableLineChartCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Grafik oluştuktan sonra en sağa (en güncel veriye) kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double chartWidth = widget.labels.length * 60.0 > MediaQuery.of(context).size.width 
        ? widget.labels.length * 60.0 
        : MediaQuery.of(context).size.width - 40;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const Icon(Icons.swipe_left_rounded, color: Colors.white24, size: 16),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, left: 10),
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: widget.spots.isEmpty ? 10 : (widget.spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
                        getDrawingVerticalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < widget.labels.length) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    widget.labels[value.toInt()],
                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: widget.spots,
                          isCurved: true,
                          color: widget.color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 4,
                              color: widget.color,
                              strokeWidth: 2,
                              strokeColor: AppTheme.bgColorStart,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [widget.color.withValues(alpha: 0.2), widget.color.withValues(alpha: 0)],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppTheme.sidebarColor.withValues(alpha: 0.9),
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((s) {
                              return LineTooltipItem(
                                '${widget.labels[s.x.toInt()]}\n',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                children: [
                                  TextSpan(
                                    text: '${s.y.toInt()} ${widget.tooltipLabel}',
                                    style: TextStyle(color: widget.color, fontWeight: FontWeight.w900, fontSize: 14),
                                  ),
                                ]
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
