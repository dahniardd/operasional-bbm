import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/pemakaian_bbm.dart';

class DashboardChartCard extends StatefulWidget {
  final List<PemakaianBbm> pemakaianList;

  const DashboardChartCard({
    super.key,
    required this.pemakaianList,
  });

  @override
  State<DashboardChartCard> createState() => _DashboardChartCardState();
}

class _DashboardChartCardState extends State<DashboardChartCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _selectedPeriod = '7d';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<ChartData> _getChartData() {
    final now = DateTime.now();
    final data = <ChartData>[];

    if (_selectedPeriod == '7d') {
      // Last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        
        final total = widget.pemakaianList
            .where((item) => 
                item.tanggal.year == date.year &&
                item.tanggal.month == date.month &&
                item.tanggal.day == date.day)
            .fold<double>(0, (sum, item) => sum + item.jumlah);

        data.add(ChartData(
          label: DateFormat('E', 'id_ID').format(date).substring(0, 3),
          value: total,
          date: date,
        ));
      }
    } else if (_selectedPeriod == '30d') {
      // Last 30 days grouped by week
      for (int i = 4; i >= 0; i--) {
        final endDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: i * 7));
        final startDate = endDate.subtract(const Duration(days: 6));
        
        final total = widget.pemakaianList.where((item) {
          return item.tanggal.isAfter(startDate.subtract(const Duration(days: 1))) &&
              item.tanggal.isBefore(endDate.add(const Duration(days: 1)));
        }).fold<double>(0, (sum, item) => sum + item.jumlah);

        data.add(ChartData(
          label: 'W${5 - i}',
          value: total,
          date: endDate,
        ));
      }
    } else {
      // Last 12 months
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i);
        
        final total = widget.pemakaianList.where((item) {
          return item.tanggal.year == date.year && item.tanggal.month == date.month;
        }).fold<double>(0, (sum, item) => sum + item.jumlah);

        data.add(ChartData(
          label: DateFormat('MMM', 'id_ID').format(date),
          value: total,
          date: date,
        ));
      }
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _getChartData();
    final maxValue = chartData.isEmpty
        ? 1.0
        : chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analitik Pengeluaran',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grafik pemakaian BBM',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPeriodButton('7d', '7H'),
                    _buildPeriodButton('30d', '30H'),
                    _buildPeriodButton('12m', '12B'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (chartData.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada data untuk ditampilkan',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(chartData.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildBar(
                        chartData[index],
                        maxValue,
                        index,
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
        _controller.reset();
        _controller.forward();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(ChartData data, double maxValue, int index) {
    final height = maxValue > 0 ? (data.value / maxValue) * 180 : 0.0;
    final delay = index * 100;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: height),
      builder: (context, animatedHeight, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (data.value > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: Text(
                  NumberFormat.compact(locale: 'id_ID').format(data.value),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF667eea),
                  ),
                ),
              ),
            Tooltip(
              message:
                  '${DateFormat('d MMM yyyy', 'id_ID').format(data.date)}\n${NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(data.value)}',
              child: Container(
                width: double.infinity,
                height: animatedHeight.clamp(4.0, 180.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF667eea),
                      const Color(0xFF764ba2),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ChartData {
  final String label;
  final double value;
  final DateTime date;

  ChartData({
    required this.label,
    required this.value,
    required this.date,
  });
}
