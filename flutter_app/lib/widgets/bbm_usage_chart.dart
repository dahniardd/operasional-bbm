import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/pln_colors.dart';
import '../models/pemakaian_bbm.dart';

/// BBM Usage Chart Widget
class BbmUsageChart extends StatefulWidget {
  final List<PemakaianBbm> pemakaianList;

  const BbmUsageChart({
    super.key,
    required this.pemakaianList,
  });

  @override
  State<BbmUsageChart> createState() => _BbmUsageChartState();
}

class _BbmUsageChartState extends State<BbmUsageChart>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = '7days';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
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
    final avgDaily = filteredData.isEmpty ? 0.0 : totalLiter / filteredData.length;

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
    final chartData = _calculateChartData();
    final data = chartData['data'] as List<PemakaianBbm>;
    final totalLiter = chartData['totalLiter'] as double;
    final totalCost = chartData['totalCost'] as double;
    final periodLabel = chartData['periodLabel'] as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: PlnColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PlnColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grafik Pemakaian BBM',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PlnColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      periodLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: PlnColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: PlnColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: PlnColors.primaryBlue,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Period selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: PlnColors.background,
                borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 16),
            // Content
            if (data.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 40,
                      color: PlnColors.border,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada data',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: PlnColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Stats
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
                ],
              ),
          ],
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
            setState(() => _selectedPeriod = value);
            _animationController.reset();
            _animationController.forward();
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? PlnColors.primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : PlnColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: PlnColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
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
