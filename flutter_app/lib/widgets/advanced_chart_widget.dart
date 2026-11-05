import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/pln_colors.dart';
import '../models/pemakaian_bbm.dart';

/// Advanced Chart Widget dengan period selector dan animasi
class AdvancedChartWidget extends StatefulWidget {
  final List<PemakaianBbm> pemakaianList;

  const AdvancedChartWidget({
    super.key,
    required this.pemakaianList,
  });

  @override
  State<AdvancedChartWidget> createState() => _AdvancedChartWidgetState();
}

class _AdvancedChartWidgetState extends State<AdvancedChartWidget>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = '7days'; // 7days, 30days, month
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.3, end: 0.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _calculateChartData() {
    final now = DateTime.now();
    List<PemakaianBbm> filteredData = [];
    String periodLabel = '';

    switch (_selectedPeriod) {
      case '7days':
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        filteredData = widget.pemakaianList
            .where((item) => item.tanggal.isAfter(sevenDaysAgo))
            .toList();
        periodLabel = 'Terakhir 7 Hari';
        break;
      case '30days':
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        filteredData = widget.pemakaianList
            .where((item) => item.tanggal.isAfter(thirtyDaysAgo))
            .toList();
        periodLabel = 'Terakhir 30 Hari';
        break;
      case 'month':
        filteredData = widget.pemakaianList
            .where((item) => item.tanggal.year == now.year && item.tanggal.month == now.month)
            .toList();
        periodLabel = 'Bulan ${DateFormat('MMMM', 'id_ID').format(now)}';
        break;
    }

    final totalLiter = filteredData.fold<double>(0, (sum, item) => sum + item.liter);
    final totalCost = filteredData.fold<double>(0, (sum, item) => sum + item.jumlah);
    final avgDaily = filteredData.isEmpty ? 0.0 : totalLiter / (filteredData.length);

    return {
      'data': filteredData,
      'totalLiter': totalLiter,
      'totalCost': totalCost,
      'avgDaily': avgDaily,
      'count': filteredData.length,
      'periodLabel': periodLabel,
    };
  }

  @override
  Widget build(BuildContext context) {
    _animationController.reset();
    _animationController.forward();

    final chartData = _calculateChartData();
    final data = chartData['data'] as List<PemakaianBbm>;
    final totalLiter = chartData['totalLiter'] as double;
    final totalCost = chartData['totalCost'] as double;
    final avgDaily = chartData['avgDaily'] as double;
    final periodLabel = chartData['periodLabel'] as String;

    return ScaleTransition(
      scale: _slideAnimation.drive(Tween<double>(begin: 0.9, end: 1.0)),
      child: Container(
        decoration: BoxDecoration(
          color: PlnColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: PlnColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grafik Pemakaian',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PlnColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        periodLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: PlnColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: PlnColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: PlnColors.primaryBlue,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Period selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: PlnColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildPeriodButton('7 Hari', '7days'),
                    const SizedBox(width: 4),
                    _buildPeriodButton('30 Hari', '30days'),
                    const SizedBox(width: 4),
                    _buildPeriodButton('Bulan Ini', 'month'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Chart representation
              if (data.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart_outlined,
                        size: 48,
                        color: PlnColors.border,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada data untuk periode ini',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: PlnColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    // Simple bar chart visualization
                    Container(
                      height: 180,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _buildSimpleChart(data, totalLiter),
                    ),
                    const SizedBox(height: 20),
                    // Stats grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Total Liter',
                            '${totalLiter.toStringAsFixed(1)} L',
                            Icons.local_gas_station,
                            PlnColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            'Total Biaya',
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(totalCost),
                            Icons.attach_money,
                            PlnColors.accentYellow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Rata-rata/Hari',
                            '${avgDaily.toStringAsFixed(1)} L',
                            Icons.trending_up,
                            PlnColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            'Jumlah Isi',
                            '${data.length}x',
                            Icons.receipt_long,
                            PlnColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedPeriod = value;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? PlnColors.primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : PlnColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleChart(List<PemakaianBbm> data, double maxValue) {
    final maxLiter = maxValue > 0 ? maxValue : 10;

    // Group data by day for 7/30 days, or by week for month
    Map<String, double> groupedData = {};

    for (var item in data) {
      String key;
      if (_selectedPeriod == 'month') {
        final week = ((item.tanggal.day - 1) ~/ 7) + 1;
        key = 'Minggu $week';
      } else {
        key = DateFormat('d MMM', 'id_ID').format(item.tanggal);
      }

      groupedData[key] = (groupedData[key] ?? 0) + item.liter;
    }

    final entries = groupedData.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: entries.asMap().entries.map((entry) {
        final label = entry.value.key;
        final value = entry.value.value;
        final percentage = (value / maxLiter).clamp(0.0, 1.0);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Bar
            Container(
              width: 24,
              height: 120 * percentage,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    PlnColors.primaryBlue,
                    PlnColors.primaryBlue.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Label
            SizedBox(
              width: 40,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: PlnColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: PlnColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
