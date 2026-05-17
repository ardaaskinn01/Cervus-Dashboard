import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';

class ScrollableMultiLineChartCard extends StatefulWidget {
  final List<FlSpot> spotsA;
  final List<FlSpot> spotsB;
  final List<String> labels;
  final String title;
  final String labelA;
  final String labelB;
  final Color colorA;
  final Color colorB;

  const ScrollableMultiLineChartCard({
    super.key,
    required this.spotsA,
    required this.spotsB,
    required this.labels,
    required this.title,
    required this.labelA,
    required this.labelB,
    required this.colorA,
    required this.colorB,
  });

  @override
  State<ScrollableMultiLineChartCard> createState() => _ScrollableMultiLineChartCardState();
}

class _ScrollableMultiLineChartCardState extends State<ScrollableMultiLineChartCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
              Row(
                children: [
                  _legend(widget.labelA, widget.colorA),
                  const SizedBox(width: 12),
                  _legend(widget.labelB, widget.colorB),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
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
                      maxY: () {
                        double maxA = widget.spotsA.isEmpty ? 0 : widget.spotsA.map((s) => s.y).reduce((a, b) => a > b ? a : b);
                        double maxB = widget.spotsB.isEmpty ? 0 : widget.spotsB.map((s) => s.y).reduce((a, b) => a > b ? a : b);
                        double m = maxA > maxB ? maxA : maxB;
                        return m < 10 ? 10.0 : (m * 1.2).ceilToDouble();
                      }(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
                        getDrawingVerticalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
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
                        _bar(widget.spotsA, widget.colorA),
                        _bar(widget.spotsB, widget.colorB),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppTheme.sidebarColor.withValues(alpha: 0.9),
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((s) {
                              final label = s.barIndex == 0 ? widget.labelA : widget.labelB;
                              final color = s.barIndex == 0 ? widget.colorA : widget.colorB;
                              return LineTooltipItem(
                                '${widget.labels[s.x.toInt()]}\n',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                children: [
                                  TextSpan(
                                    text: '$label: ${s.y.toInt()} Ziyaret',
                                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13),
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

  LineChartBarData _bar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.1), color.withOpacity(0)],
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
